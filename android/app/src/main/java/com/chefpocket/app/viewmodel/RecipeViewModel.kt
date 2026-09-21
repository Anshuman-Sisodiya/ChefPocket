package com.chefpocket.app.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.chefpocket.app.data.models.*
import com.chefpocket.app.data.repository.RecipeRepository
import com.chefpocket.app.network.AIService
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class RecipeFilterState(
    val scope: RecipeScope = RecipeScope.CURATED,
    val diet: DietType = DietType.ALL,
    val cuisine: Cuisine = Cuisine.ALL,
    val category: RecipeCategory = RecipeCategory.ALL,
    val query: String = ""
)

class RecipeViewModel(application: Application) : AndroidViewModel(application) {
    val repository = RecipeRepository(application)
    val recipes = repository.recipes
    val groceries = repository.groceries
    val thali = repository.thali
    val profile = repository.profile

    // Active Home Filters
    private val _selectedScope = MutableStateFlow(RecipeScope.CURATED)
    val selectedScope: StateFlow<RecipeScope> = _selectedScope.asStateFlow()

    private val _selectedDiet = MutableStateFlow(DietType.ALL)
    val selectedDiet: StateFlow<DietType> = _selectedDiet.asStateFlow()

    private val _selectedCuisine = MutableStateFlow(Cuisine.ALL)
    val selectedCuisine: StateFlow<Cuisine> = _selectedCuisine.asStateFlow()

    private val _selectedCategory = MutableStateFlow(RecipeCategory.ALL)
    val selectedCategory: StateFlow<RecipeCategory> = _selectedCategory.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // Clipboard & Extraction state
    val clipboardDetectedURL = MutableStateFlow<String?>(null)
    val isExtracting = MutableStateFlow(false)
    val extractionStatus = MutableStateFlow("")
    val extractionError = MutableStateFlow<String?>(null)
    val duplicateRecipeTitle = MutableStateFlow<String?>(null)

    // Active recipe detail selection
    val activeRecipe = MutableStateFlow<Recipe?>(null)

    // Dialogs state
    val showAIImportDialog = MutableStateFlow(false)
    val showCreateRecipeDialog = MutableStateFlow(false)
    val showRandomizerDialog = MutableStateFlow(false)
    val showProfileDialog = MutableStateFlow(false)

    // Combine filters into intermediate state flow
    private val filterState: Flow<RecipeFilterState> = combine(
        _selectedScope,
        _selectedDiet,
        _selectedCuisine,
        _selectedCategory,
        _searchQuery
    ) { scope, diet, cuisine, category, query ->
        RecipeFilterState(scope, diet, cuisine, category, query)
    }

    // Filtered Recipes Pipeline
    val filteredRecipes: StateFlow<List<Recipe>> = combine(
        recipes,
        filterState
    ) { all, filter ->
        // 1. Scope filter
        val inScope = when (filter.scope) {
            RecipeScope.MY_KITCHEN -> all.filter { it.isUserCreated }
            RecipeScope.FAVORITES -> all.filter { it.isFavorite }
            else -> all.filter { !it.isUserCreated }
        }

        // 2. Query search
        val qClean = filter.query.trim().lowercase()
        val inQuery = if (qClean.isEmpty()) inScope else inScope.filter {
            it.title.lowercase().contains(qClean) ||
                    it.cuisine.lowercase().contains(qClean) ||
                    it.category.lowercase().contains(qClean) ||
                    it.ingredients.any { ing -> ing.name.lowercase().contains(qClean) }
        }

        // 3. Diet
        val inDiet = if (filter.diet == DietType.ALL) inQuery else inQuery.filter { it.dietType == filter.diet }

        // 4. Cuisine
        val inCuisine = if (filter.cuisine == Cuisine.ALL) inDiet else inDiet.filter {
            it.cuisine.equals(filter.cuisine.label, ignoreCase = true)
        }

        // 5. Category
        if (filter.category == RecipeCategory.ALL) inCuisine else inCuisine.filter {
            it.category.equals(filter.category.label, ignoreCase = true)
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Counts
    val curatedCount: StateFlow<Int> = recipes.map { list -> list.count { !it.isUserCreated } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val myKitchenCount: StateFlow<Int> = recipes.map { list -> list.count { it.isUserCreated } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val favoritesCount: StateFlow<Int> = recipes.map { list -> list.count { it.isFavorite } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    fun setScope(scope: RecipeScope) { _selectedScope.value = scope }
    fun setDiet(diet: DietType) { _selectedDiet.value = diet }
    fun setCuisine(cuisine: Cuisine) { _selectedCuisine.value = cuisine }
    fun setCategory(category: RecipeCategory) { _selectedCategory.value = category }
    fun setSearchQuery(query: String) { _searchQuery.value = query }

    fun toggleFavorite(id: String) {
        repository.toggleFavorite(id)
        if (activeRecipe.value?.id == id) {
            activeRecipe.value = activeRecipe.value?.copy(isFavorite = !(activeRecipe.value?.isFavorite ?: false))
        }
    }

    fun deleteRecipe(id: String) {
        repository.deleteRecipe(id)
        if (activeRecipe.value?.id == id) {
            activeRecipe.value = null
        }
    }

    fun addCustomRecipe(recipe: Recipe) {
        repository.addRecipe(recipe)
        _selectedScope.value = RecipeScope.MY_KITCHEN
    }

    fun extractRecipeFromVideo(url: String, onComplete: () -> Unit = {}) {
        val clean = url.trim()
        if (clean.isEmpty()) return

        // Duplicate check
        val existing = repository.findRecipeMatchingURL(clean)
        if (existing != null) {
            duplicateRecipeTitle.value = existing.title
            return
        }

        viewModelScope.launch {
            isExtracting.value = true
            extractionError.value = null
            extractionStatus.value = "Analyzing video link..."
            try {
                val apiKey = repository.getApiKey()
                val model = repository.getPreferredModel()
                val recipe = AIService.shared.extractRecipe(
                    urlString = clean,
                    userApiKey = apiKey,
                    preferredModel = model
                ) { status ->
                    extractionStatus.value = status
                }
                repository.addRecipe(recipe)
                _selectedScope.value = RecipeScope.MY_KITCHEN
                showAIImportDialog.value = false
                clipboardDetectedURL.value = null
                onComplete()
            } catch (e: Exception) {
                extractionError.value = e.localizedMessage ?: "Extraction failed. Please check your link or API key."
            } finally {
                isExtracting.value = false
                extractionStatus.value = ""
            }
        }
    }
}
