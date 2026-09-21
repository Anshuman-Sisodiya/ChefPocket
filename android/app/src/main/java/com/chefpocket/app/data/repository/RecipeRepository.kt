package com.chefpocket.app.data.repository

import android.content.Context
import android.content.SharedPreferences
import com.chefpocket.app.data.models.*
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.io.InputStreamReader
import java.util.UUID

class RecipeRepository(private val context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("chefpocket_prefs", Context.MODE_PRIVATE)
    private val gson = Gson()

    // Storage Keys (Matching iOS architecture)
    private val keyUserRecipes = "chefpocket_user_custom_recipes_permanent"
    private val keyFavorites = "chefpocket_user_favorites_permanent"
    private val keyTombstones = "chefpocket_deleted_recipe_tombstones_permanent"
    private val keyGroceries = "chefpocket_groceries"
    private val keyThali = "chefpocket_thali"
    private val keyProfile = "chefpocket_profile"
    private val keyApiKey = "chefpocket_gemini_api_key"
    private val keyModel = "chefpocket_gemini_model"

    private val _recipes = MutableStateFlow<List<Recipe>>(emptyList())
    val recipes: StateFlow<List<Recipe>> = _recipes.asStateFlow()

    private val _groceries = MutableStateFlow<List<GroceryItem>>(emptyList())
    val groceries: StateFlow<List<GroceryItem>> = _groceries.asStateFlow()

    private val _thali = MutableStateFlow(ThaliPlan())
    val thali: StateFlow<ThaliPlan> = _thali.asStateFlow()

    private val _profile = MutableStateFlow(UserProfile())
    val profile: StateFlow<UserProfile> = _profile.asStateFlow()

    val curatedRecipes: List<Recipe>
        get() = _recipes.value.filter { !it.isUserCreated }

    val myRecipes: List<Recipe>
        get() = _recipes.value.filter { it.isUserCreated }

    val favoriteRecipes: List<Recipe>
        get() = _recipes.value.filter { it.isFavorite }

    init {
        loadProfile()
        loadData()
    }

    // MARK: - Tombstones
    private fun getTombstones(): Set<String> {
        val json = prefs.getString(keyTombstones, null) ?: return emptySet()
        val type = object : TypeToken<List<String>>() {}.type
        val list: List<String> = gson.fromJson(json, type) ?: emptyList()
        return list.toSet()
    }

    private fun addTombstone(id: String, title: String) {
        val stones = getTombstones().toMutableSet()
        stones.add(id)
        stones.add(title.trim().lowercase())
        prefs.edit().putString(keyTombstones, gson.toJson(stones.toList())).apply()
    }

    private fun removeTombstone(id: String, title: String) {
        val stones = getTombstones().toMutableSet()
        stones.remove(id)
        stones.remove(title.trim().lowercase())
        prefs.edit().putString(keyTombstones, gson.toJson(stones.toList())).apply()
    }

    // MARK: - Data Loading
    fun loadData() {
        val tombstones = getTombstones()

        // 1. Load permanent user custom recipes
        val customJson = prefs.getString(keyUserRecipes, null)
        val customRecipes: MutableList<Recipe> = if (customJson != null) {
            val type = object : TypeToken<List<Recipe>>() {}.type
            val list: List<Recipe> = gson.fromJson(customJson, type) ?: emptyList()
            list.filter { !tombstones.contains(it.id) && !tombstones.contains(it.title.trim().lowercase()) }.toMutableList()
        } else {
            mutableListOf()
        }

        // 2. Load permanent favorite identifiers (both UUID and lowercased title)
        val favJson = prefs.getString(keyFavorites, null)
        val favSet: Set<String> = if (favJson != null) {
            val type = object : TypeToken<List<String>>() {}.type
            gson.fromJson<List<String>>(favJson, type)?.toSet() ?: emptySet()
        } else {
            emptySet()
        }

        // 3. Load 434 bundled recipes from assets
        val bundled = loadBundledRecipes().map { recipe ->
            val isFav = favSet.contains(recipe.id) || favSet.contains(recipe.title.trim().lowercase())
            recipe.copy(isFavorite = isFav)
        }

        // 4. Merge: Custom recipes first, then Curated
        _recipes.value = customRecipes + bundled

        // 5. Load Groceries
        val grocJson = prefs.getString(keyGroceries, null)
        if (grocJson != null) {
            val type = object : TypeToken<List<GroceryItem>>() {}.type
            _groceries.value = gson.fromJson(grocJson, type) ?: emptyList()
        }

        // 6. Load Thali
        val thaliJson = prefs.getString(keyThali, null)
        if (thaliJson != null) {
            _thali.value = gson.fromJson(thaliJson, ThaliPlan::class.java) ?: ThaliPlan()
        }
    }

    private fun loadBundledRecipes(): List<Recipe> {
        return try {
            context.assets.open("recipes_data.json").use { stream ->
                InputStreamReader(stream, "UTF-8").use { reader ->
                    val type = object : TypeToken<List<Recipe>>() {}.type
                    gson.fromJson(reader, type) ?: emptyList()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }

    private fun saveData() {
        // 1. Save user custom recipes
        val custom = myRecipes
        prefs.edit().putString(keyUserRecipes, gson.toJson(custom)).apply()

        // 2. Save favorites (both ID and title for durability)
        val favIdentifiers = mutableListOf<String>()
        _recipes.value.filter { it.isFavorite }.forEach {
            favIdentifiers.add(it.id)
            favIdentifiers.add(it.title.trim().lowercase())
        }
        prefs.edit().putString(keyFavorites, gson.toJson(favIdentifiers)).apply()

        // 3. Save groceries
        prefs.edit().putString(keyGroceries, gson.toJson(_groceries.value)).apply()

        // 4. Save thali
        prefs.edit().putString(keyThali, gson.toJson(_thali.value)).apply()
    }

    // MARK: - Recipe Operations
    fun addRecipe(recipe: Recipe): Pair<Recipe, Boolean> {
        // Deduplication check by source URL
        if (!recipe.sourceURL.isNullOrBlank()) {
            val existing = findRecipeMatchingURL(recipe.sourceURL)
            if (existing != null) {
                return Pair(existing, false)
            }
        }

        removeTombstone(recipe.id, recipe.title)
        val newR = recipe.copy(isUserCreated = true)
        _recipes.value = listOf(newR) + _recipes.value
        saveData()
        return Pair(newR, true)
    }

    fun deleteRecipe(id: String) {
        val recipe = _recipes.value.firstOrNull { it.id == id } ?: return
        addTombstone(recipe.id, recipe.title)
        _recipes.value = _recipes.value.filter { it.id != id }
        saveData()
    }

    fun toggleFavorite(id: String) {
        _recipes.value = _recipes.value.map {
            if (it.id == id) it.copy(isFavorite = !it.isFavorite) else it
        }
        saveData()
    }

    fun findRecipeMatchingURL(url: String): Recipe? {
        val clean = url.trim().lowercase()
        return _recipes.value.firstOrNull { r ->
            val src = r.sourceURL?.trim()?.lowercase() ?: ""
            src == clean || (src.contains("shorts/") && clean.contains("shorts/") && src.substringAfter("shorts/").take(11) == clean.substringAfter("shorts/").take(11))
        }
    }

    fun getRandomRecipe(
        scope: RecipeScope? = null,
        cuisine: Cuisine? = null,
        diet: DietType? = null,
        category: RecipeCategory? = null
    ): Recipe? {
        var pool = when (scope) {
            RecipeScope.MY_KITCHEN -> myRecipes
            RecipeScope.FAVORITES -> favoriteRecipes
            else -> curatedRecipes
        }
        if (pool.isEmpty()) pool = _recipes.value

        if (cuisine != null && cuisine != Cuisine.ALL) {
            pool = pool.filter { it.cuisine.equals(cuisine.label, ignoreCase = true) }
        }
        if (diet != null && diet != DietType.ALL) {
            pool = pool.filter { it.dietType == diet }
        }
        if (category != null && category != RecipeCategory.ALL) {
            pool = pool.filter { it.category.equals(category.label, ignoreCase = true) }
        }
        return pool.randomOrNull()
    }

    // MARK: - Grocery Operations
    fun addIngredientsToGroceries(ingredients: List<Ingredient>) {
        val current = _groceries.value.toMutableList()
        ingredients.forEach { ing ->
            current.add(
                GroceryItem(
                    name = ing.name,
                    amount = ing.amount,
                    unit = ing.unit,
                    category = "Produce / Pantry"
                )
            )
        }
        _groceries.value = current
        saveData()
    }

    fun toggleGroceryItem(id: String) {
        _groceries.value = _groceries.value.map {
            if (it.id == id) it.copy(isChecked = !it.isChecked) else it
        }
        saveData()
    }

    fun clearCheckedGroceries() {
        _groceries.value = _groceries.value.filter { !it.isChecked }
        saveData()
    }

    fun addCustomGrocery(name: String, amount: Double, unit: String) {
        val item = GroceryItem(name = name, amount = amount, unit = unit)
        _groceries.value = listOf(item) + _groceries.value
        saveData()
    }

    // MARK: - Thali Operations
    fun setThaliSlot(slotName: String, recipeId: String?) {
        val current = _thali.value.copy()
        when (slotName) {
            "grain" -> current.grainRecipeId = recipeId
            "sabzi" -> current.sabziRecipeId = recipeId
            "dal" -> current.dalRecipeId = recipeId
            "accompaniment" -> current.accompanimentRecipeId = recipeId
            "salad" -> current.saladRecipeId = recipeId
            "sweet" -> current.sweetRecipeId = recipeId
        }
        _thali.value = current
        saveData()
    }

    fun autoBalanceThali() {
        val curated = curatedRecipes
        val grain = curated.filter { it.category.contains("Rice", ignoreCase = true) || it.title.contains("Roti", ignoreCase = true) }.randomOrNull()
        val sabzi = curated.filter { it.category.equals("Sabzi", ignoreCase = true) }.randomOrNull()
        val dal = curated.filter { it.category.equals("Dal", ignoreCase = true) }.randomOrNull()
        val acc = curated.filter { it.category.contains("Street", ignoreCase = true) || it.title.contains("Raita", ignoreCase = true) }.randomOrNull()
        val sweet = curated.filter { it.category.equals("Bakery", ignoreCase = true) || it.title.contains("Halwa", ignoreCase = true) }.randomOrNull()

        _thali.value = ThaliPlan(
            grainRecipeId = grain?.id,
            sabziRecipeId = sabzi?.id,
            dalRecipeId = dal?.id,
            accompanimentRecipeId = acc?.id,
            saladRecipeId = null,
            sweetRecipeId = sweet?.id
        )
        saveData()
    }

    // MARK: - Profile & Settings
    private fun loadProfile() {
        val json = prefs.getString(keyProfile, null)
        if (json != null) {
            _profile.value = gson.fromJson(json, UserProfile::class.java) ?: UserProfile()
        }
        // Ensure API key synced
        val savedKey = prefs.getString(keyApiKey, "") ?: ""
        if (_profile.value.geminiApiKey.isEmpty() && savedKey.isNotEmpty()) {
            _profile.value.geminiApiKey = savedKey
        }
    }

    fun updateProfile(name: String, diet: DietType, apiKey: String) {
        val cleanKey = apiKey.trim()
        val p = _profile.value.copy(
            name = name.trim(),
            dietaryPreference = diet,
            geminiApiKey = cleanKey
        )
        _profile.value = p
        prefs.edit()
            .putString(keyProfile, gson.toJson(p))
            .putString(keyApiKey, cleanKey)
            .apply()
    }

    fun getApiKey(): String {
        return _profile.value.geminiApiKey.ifBlank {
            prefs.getString(keyApiKey, "") ?: ""
        }
    }

    fun setApiKey(key: String) {
        val clean = key.trim()
        val p = _profile.value.copy(geminiApiKey = clean)
        _profile.value = p
        prefs.edit()
            .putString(keyProfile, gson.toJson(p))
            .putString(keyApiKey, clean)
            .apply()
    }

    fun getPreferredModel(): String {
        return prefs.getString(keyModel, "gemini-3.6-flash") ?: "gemini-3.6-flash"
    }

    fun setPreferredModel(model: String) {
        prefs.edit().putString(keyModel, model.trim()).apply()
    }
}
