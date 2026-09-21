package com.chefpocket.app.ui.screens

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.chefpocket.app.data.models.*
import com.chefpocket.app.ui.components.*
import com.chefpocket.app.ui.theme.*
import com.chefpocket.app.viewmodel.RecipeViewModel

// ==========================================
// 1. COOKBOOK SCREEN (HOME)
// ==========================================
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CookbookScreen(
    viewModel: RecipeViewModel,
    onRecipeClick: (Recipe) -> Unit
) {
    val recipes by viewModel.filteredRecipes.collectAsState()
    val scope by viewModel.selectedScope.collectAsState()
    val diet by viewModel.selectedDiet.collectAsState()
    val cuisine by viewModel.selectedCuisine.collectAsState()
    val category by viewModel.selectedCategory.collectAsState()
    val searchQuery by viewModel.searchQuery.collectAsState()

    val curatedCount by viewModel.curatedCount.collectAsState()
    val kitchenCount by viewModel.myKitchenCount.collectAsState()
    val favsCount by viewModel.favoritesCount.collectAsState()

    val clipboardURL by viewModel.clipboardDetectedURL.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text("ChefPocket", fontWeight = FontWeight.Bold, color = PrimaryOrange)
                },
                actions = {
                    // Quick Heart Favorites Button
                    IconButton(onClick = {
                        viewModel.setScope(if (scope == RecipeScope.FAVORITES) RecipeScope.CURATED else RecipeScope.FAVORITES)
                    }) {
                        Icon(
                            imageVector = if (scope == RecipeScope.FAVORITES) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Favorites",
                            tint = if (scope == RecipeScope.FAVORITES) Color.Red else MaterialTheme.colorScheme.onSurface
                        )
                    }

                    // Randomizer Spin
                    IconButton(onClick = { viewModel.showRandomizerDialog.value = true }) {
                        Icon(imageVector = Icons.Default.Shuffle, contentDescription = "Randomize", tint = PrimaryOrange)
                    }

                    // Add Recipe Action
                    IconButton(onClick = { viewModel.showAIImportDialog.value = true }) {
                        Icon(imageVector = Icons.Default.AddCircle, contentDescription = "Import", tint = PrimaryOrange)
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Clipboard Banner
            if (clipboardURL != null) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(PrimaryOrange.copy(alpha = 0.12f))
                        .padding(10.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Icon(Icons.Default.ContentPaste, contentDescription = null, tint = PrimaryOrange, modifier = Modifier.size(18.dp))
                        Text("Recipe link in clipboard", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                    }
                    Button(
                        onClick = { viewModel.extractRecipeFromVideo(clipboardURL!!) },
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("Extract", fontSize = 11.sp)
                    }
                }
            }

            // 3-Way Scope Segment: Curated (434) | Kitchen (X) | Favorites (Y)
            Box(modifier = Modifier.padding(horizontal = 16.dp, vertical = 4.dp)) {
                ScopeSegmentedControl(
                    selectedScope = scope,
                    curatedCount = curatedCount,
                    myKitchenCount = kitchenCount,
                    favoritesCount = favsCount,
                    onScopeSelected = { viewModel.setScope(it) }
                )
            }

            // Diet Filter Pills (All | Veg | Non-Veg)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                DietPillButton(
                    title = "All",
                    count = recipes.size,
                    isSelected = diet == DietType.ALL,
                    onClick = { viewModel.setDiet(DietType.ALL) }
                )
                DietPillButton(
                    title = "Veg",
                    count = recipes.count { it.dietType == DietType.VEG },
                    isSelected = diet == DietType.VEG,
                    dotColor = VegGreen,
                    onClick = { viewModel.setDiet(DietType.VEG) }
                )
                DietPillButton(
                    title = "Non-Veg",
                    count = recipes.count { it.dietType == DietType.NON_VEG },
                    isSelected = diet == DietType.NON_VEG,
                    dotColor = NonVegRed,
                    onClick = { viewModel.setDiet(DietType.NON_VEG) }
                )
            }

            // Cuisine & Category Filter Bar
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp),
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(Cuisine.values()) { c ->
                    FilterChip(
                        selected = cuisine == c,
                        onClick = { viewModel.setCuisine(if (cuisine == c) Cuisine.ALL else c) },
                        label = { Text(c.label, fontSize = 11.sp) }
                    )
                }
            }

            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { viewModel.setSearchQuery(it) },
                placeholder = { Text("Search 434 dishes, ingredients, tags...", fontSize = 13.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = PrimaryOrange) },
                singleLine = true,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp)
            )

            // Recipe List & Empty States
            if (recipes.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    if (scope == RecipeScope.FAVORITES) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Icon(Icons.Default.HeartBroken, contentDescription = null, tint = Color.Red.copy(alpha = 0.6f), modifier = Modifier.size(56.dp))
                            Text("No Favorites Saved Yet", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            Text("Tap the heart on any recipe to save it here.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Button(
                                onClick = { viewModel.setScope(RecipeScope.CURATED) },
                                colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text("Browse Curated Dishes")
                            }
                        }
                    } else if (scope == RecipeScope.MY_KITCHEN) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            Icon(Icons.Default.SoupKitchen, contentDescription = null, tint = PrimaryOrange, modifier = Modifier.size(56.dp))
                            Text("Your Kitchen is Empty", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                            Text("Import recipes from YouTube Shorts or Reels using the + button.", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Button(
                                onClick = { viewModel.showAIImportDialog.value = true },
                                colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                                shape = RoundedCornerShape(10.dp)
                            ) {
                                Text("Import Video Recipe")
                            }
                        }
                    } else {
                        Text("No recipes found matching your filters.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(bottom = 80.dp)
                ) {
                    items(recipes, key = { it.id }) { recipe ->
                        RecipeCard(
                            recipe = recipe,
                            onClick = { onRecipeClick(recipe) },
                            onFavoriteToggle = { viewModel.toggleFavorite(recipe.id) }
                        )
                    }
                }
            }
        }
    }
}

// ==========================================
// 2. RECIPE DETAIL SCREEN
// ==========================================
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipeDetailScreen(
    recipe: Recipe,
    viewModel: RecipeViewModel,
    onBack: () -> Unit,
    onCookModeClick: () -> Unit
) {
    var multiplier by remember { mutableStateOf(1) }
    val context = LocalContext.current
    var isFav by remember { mutableStateOf(recipe.isFavorite) }
    var groceryAddedMsg by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(recipe.title, maxLines = 1, style = MaterialTheme.typography.titleMedium) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = {
                        isFav = !isFav
                        viewModel.toggleFavorite(recipe.id)
                    }) {
                        Icon(
                            imageVector = if (isFav) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                            contentDescription = "Favorite",
                            tint = if (isFav) Color.Red else MaterialTheme.colorScheme.onSurface
                        )
                    }
                    IconButton(onClick = {
                        val shareText = """
🍳 ${recipe.title} (${recipe.diet})
Prep Time: ${recipe.prepTimeMinutes}m | Calories: ${recipe.calories} kcal | Protein: ${recipe.proteinGrams}g
${if (recipe.whistleCount != null) "Pressure Cooker: ${recipe.whistleCount} whistles\n" else ""}
🛒 INGREDIENTS:
${recipe.ingredients.joinToString("\n") { "• ${it.name} - ${String.format("%.1f", it.amount * multiplier)} ${it.unit}" }}

👨‍🍳 INSTRUCTIONS:
${recipe.instructions.mapIndexed { i, step -> "${i + 1}. $step" }.joinToString("\n")}

Shared via ChefPocket App
""".trimIndent()
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            putExtra(Intent.EXTRA_TEXT, shareText)
                            type = "text/plain"
                        }
                        context.startActivity(Intent.createChooser(sendIntent, "Share Recipe"))
                    }) {
                        Icon(Icons.Default.Share, contentDescription = "Share")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Badges & Cuisine
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FSSAIBadge(diet = recipe.dietType, size = 16)
                Text(recipe.cuisine, fontWeight = FontWeight.Bold, color = PrimaryOrange)
                Text("•")
                Text(recipe.category, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }

            Text(recipe.title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)

            // Macros Card
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .padding(12.dp),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                MacroPill("Protein", "${recipe.proteinGrams * multiplier}g")
                MacroPill("Calories", "${recipe.calories * multiplier} kcal")
                MacroPill("Prep Time", "${recipe.prepTimeMinutes}m")
                if (recipe.whistleCount != null) {
                    MacroPill("Whistles", "${recipe.whistleCount}", color = Color(0xFF009688))
                }
            }

            // Serving Multiplier
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Servings", fontWeight = FontWeight.Bold)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    listOf(1, 2, 3, 4).forEach { m ->
                        FilterChip(
                            selected = multiplier == m,
                            onClick = { multiplier = m },
                            label = { Text("${m}x") }
                        )
                    }
                }
            }

            // Ingredients
            Text("Ingredients", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            recipe.ingredients.forEach { ing ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text("• ${ing.name}", fontSize = 14.sp)
                    Text("${String.format("%.1f", ing.amount * multiplier)} ${ing.unit}", fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                }
            }

            // Add Ingredients to Grocery List
            Button(
                onClick = {
                    viewModel.repository.addIngredientsToGroceries(recipe.ingredients)
                    groceryAddedMsg = true
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant, contentColor = MaterialTheme.colorScheme.onSurfaceVariant),
                shape = RoundedCornerShape(10.dp)
            ) {
                Icon(Icons.Default.AddShoppingCart, contentDescription = null, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(6.dp))
                Text(if (groceryAddedMsg) "✓ Added to Sabzi Mandi" else "Add All to Sabzi Mandi")
            }

            // Instructions
            Text("Cooking Instructions", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            recipe.instructions.forEachIndexed { idx, step ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Text("${idx + 1}.", fontWeight = FontWeight.Bold, color = PrimaryOrange)
                    Text(step, fontSize = 14.sp, lineHeight = 20.sp)
                }
            }

            // Cook Mode Launcher Button
            Button(
                onClick = onCookModeClick,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                shape = RoundedCornerShape(12.dp)
            ) {
                Icon(Icons.Default.OutdoorGrill, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Start Cook Mode", fontWeight = FontWeight.Bold)
            }

            // Delete Custom Recipe (if user created)
            if (recipe.isUserCreated) {
                OutlinedButton(
                    onClick = {
                        viewModel.deleteRecipe(recipe.id)
                        onBack()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(Icons.Default.Delete, contentDescription = null, tint = Color.Red)
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Delete Recipe from Kitchen")
                }
            }
        }
    }
}

// ==========================================
// 3. THALI PLANNER SCREEN
// ==========================================
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ThaliScreen(viewModel: RecipeViewModel) {
    val thali by viewModel.thali.collectAsState()
    val recipes by viewModel.recipes.collectAsState()

    val grain = recipes.firstOrNull { it.id == thali.grainRecipeId }
    val sabzi = recipes.firstOrNull { it.id == thali.sabziRecipeId }
    val dal = recipes.firstOrNull { it.id == thali.dalRecipeId }
    val acc = recipes.firstOrNull { it.id == thali.accompanimentRecipeId }
    val sweet = recipes.firstOrNull { it.id == thali.sweetRecipeId }

    val totalCalories = (grain?.calories ?: 0) + (sabzi?.calories ?: 0) + (dal?.calories ?: 0) + (acc?.calories ?: 0) + (sweet?.calories ?: 0)
    val totalProtein = (grain?.proteinGrams ?: 0) + (sabzi?.proteinGrams ?: 0) + (dal?.proteinGrams ?: 0) + (acc?.proteinGrams ?: 0) + (sweet?.proteinGrams ?: 0)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Thali Planner", fontWeight = FontWeight.Bold, color = PrimaryOrange) },
                actions = {
                    Button(
                        onClick = { viewModel.repository.autoBalanceThali() },
                        colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                        shape = RoundedCornerShape(8.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("Auto-Balance", fontSize = 11.sp)
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Thali Macros Summary
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(PrimaryOrange.copy(alpha = 0.12f))
                    .padding(14.dp),
                horizontalArrangement = Arrangement.SpaceAround
            ) {
                MacroPill("Total Energy", "$totalCalories kcal", color = PrimaryOrange)
                MacroPill("Total Protein", "${totalProtein}g", color = PrimaryOrangeDark)
            }

            Text("6-Compartment Authentic Thali", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

            ThaliSlotCard(slot = "Grain / Roti / Rice", recipe = grain)
            ThaliSlotCard(slot = "Main Sabzi", recipe = sabzi)
            ThaliSlotCard(slot = "Dal / Curry", recipe = dal)
            ThaliSlotCard(slot = "Accompaniment / Raita", recipe = acc)
            ThaliSlotCard(slot = "Mithai / Sweet", recipe = sweet)
        }
    }
}

@Composable
fun ThaliSlotCard(slot: String, recipe: Recipe?) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(slot, fontSize = 11.sp, color = PrimaryOrange, fontWeight = FontWeight.Bold)
                Text(recipe?.title ?: "Not Selected", fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
            }
            if (recipe != null) {
                Text("${recipe.calories} kcal | ${recipe.proteinGrams}g P", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }
    }
}

// ==========================================
// 4. SABZI MANDI (GROCERY LIST)
// ==========================================
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroceryScreen(viewModel: RecipeViewModel) {
    val groceries by viewModel.groceries.collectAsState()
    var newItemName by remember { mutableStateOf("") }
    var newItemAmount by remember { mutableStateOf("1") }
    var newItemUnit by remember { mutableStateOf("kg") }
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sabzi Mandi", fontWeight = FontWeight.Bold, color = PrimaryOrange) },
                actions = {
                    IconButton(onClick = {
                        val text = "🛒 Sabzi Mandi Grocery List:\n" + groceries.joinToString("\n") {
                            "${if (it.isChecked) "[✓]" else "[ ]"} ${it.name} - ${it.amount} ${it.unit}"
                        }
                        val sendIntent = Intent(Intent.ACTION_SEND).apply {
                            putExtra(Intent.EXTRA_TEXT, text)
                            type = "text/plain"
                        }
                        context.startActivity(Intent.createChooser(sendIntent, "Share Grocery List"))
                    }) {
                        Icon(Icons.Default.Share, contentDescription = "Share")
                    }
                    IconButton(onClick = { viewModel.repository.clearCheckedGroceries() }) {
                        Icon(Icons.Default.DeleteSweep, contentDescription = "Clear Completed")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Quick Add Input
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = newItemName,
                    onValueChange = { newItemName = it },
                    placeholder = { Text("Add item (e.g. Paneer)") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(10.dp)
                )
                Button(
                    onClick = {
                        if (newItemName.isNotBlank()) {
                            val amt = newItemAmount.toDoubleOrNull() ?: 1.0
                            viewModel.repository.addCustomGrocery(newItemName.trim(), amt, newItemUnit)
                            newItemName = ""
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                    shape = RoundedCornerShape(10.dp)
                ) {
                    Text("Add")
                }
            }

            // Grocery Checklist
            if (groceries.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Sabzi Mandi list is empty. Add items above or export from recipe pages.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            } else {
                LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(groceries, key = { it.id }) { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(MaterialTheme.colorScheme.surfaceVariant)
                                .clickable { viewModel.repository.toggleGroceryItem(item.id) }
                                .padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Checkbox(
                                    checked = item.isChecked,
                                    onCheckedChange = { viewModel.repository.toggleGroceryItem(item.id) }
                                )
                                Text(item.name, fontWeight = FontWeight.Medium)
                            }
                            Text("${item.amount} ${item.unit}", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 12.sp)
                        }
                    }
                }
            }
        }
    }
}

// ==========================================
// 5. COOK MODE SCREEN
// ==========================================
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CookModeScreen(
    recipe: Recipe?,
    onClose: () -> Unit
) {
    if (recipe == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Select a recipe to start Cook Mode.")
        }
        return
    }

    var currentStep by remember { mutableStateOf(0) }
    var whistleTracker by remember { mutableStateOf(0) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(recipe.title, maxLines = 1) },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(20.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                // Step Progress Bar
                LinearProgressIndicator(
                    progress = (currentStep + 1).toFloat() / recipe.instructions.size.toFloat(),
                    color = PrimaryOrange,
                    modifier = Modifier.fillMaxWidth()
                )

                Text(
                    "STEP ${currentStep + 1} OF ${recipe.instructions.size}",
                    color = PrimaryOrange,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp
                )

                // Instruction Text
                Text(
                    text = recipe.instructions.getOrElse(currentStep) { "Enjoy your meal!" },
                    style = MaterialTheme.typography.titleLarge,
                    lineHeight = 32.sp
                )

                // Pressure Cooker Whistle Counter
                if (recipe.whistleCount != null) {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        colors = CardDefaults.cardColors(containerColor = PrimaryOrange.copy(alpha = 0.1f))
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text("Whistle Tracker", fontWeight = FontWeight.Bold)
                                Text("Target: ${recipe.whistleCount} whistles", fontSize = 12.sp)
                            }
                            Button(
                                onClick = { whistleTracker++ },
                                colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange)
                            ) {
                                Text("$whistleTracker / ${recipe.whistleCount}")
                            }
                        }
                    }
                }
            }

            // Navigation Buttons
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(
                    onClick = { if (currentStep > 0) currentStep-- },
                    enabled = currentStep > 0,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("Previous")
                }
                Button(
                    onClick = {
                        if (currentStep < recipe.instructions.size - 1) {
                            currentStep++
                        } else {
                            onClose()
                        }
                    },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange)
                ) {
                    Text(if (currentStep < recipe.instructions.size - 1) "Next Step" else "Done")
                }
            }
        }
    }
}
