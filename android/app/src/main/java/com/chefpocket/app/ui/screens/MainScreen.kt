package com.chefpocket.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.chefpocket.app.ui.modals.AIImportDialog
import com.chefpocket.app.ui.modals.RandomizerDialog
import com.chefpocket.app.ui.theme.ChefPocketTheme
import com.chefpocket.app.ui.theme.PrimaryOrange
import com.chefpocket.app.viewmodel.RecipeViewModel

enum class BottomTab(val label: String, val icon: ImageVector) {
    COOKBOOK("Cookbook", Icons.Default.MenuBook),
    THALI("Thali", Icons.Default.DinnerDining),
    GROCERY("Mandi", Icons.Default.ShoppingCart),
    COOK_MODE("Cook", Icons.Default.OutdoorGrill)
}

@Composable
fun MainScreen(viewModel: RecipeViewModel) {
    ChefPocketTheme {
        var currentTab by remember { mutableStateOf(BottomTab.COOKBOOK) }
        val activeRecipe by viewModel.activeRecipe.collectAsState()
        val showAIImport by viewModel.showAIImportDialog.collectAsState()
        val showRandomizer by viewModel.showRandomizerDialog.collectAsState()

        var isCookModeActive by remember { mutableStateOf(false) }

        if (isCookModeActive) {
            CookModeScreen(
                recipe = activeRecipe,
                onClose = { isCookModeActive = false }
            )
        } else if (activeRecipe != null) {
            RecipeDetailScreen(
                recipe = activeRecipe!!,
                viewModel = viewModel,
                onBack = { viewModel.activeRecipe.value = null },
                onCookModeClick = { isCookModeActive = true }
            )
        } else {
            Scaffold(
                bottomBar = {
                    NavigationBar(
                        containerColor = MaterialTheme.colorScheme.surface,
                        contentColor = MaterialTheme.colorScheme.onSurface
                    ) {
                        BottomTab.values().forEach { tab ->
                            NavigationBarItem(
                                selected = currentTab == tab,
                                onClick = { currentTab = tab },
                                icon = {
                                    Icon(
                                        imageVector = tab.icon,
                                        contentDescription = tab.label,
                                        tint = if (currentTab == tab) PrimaryOrange else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                },
                                label = {
                                    Text(
                                        text = tab.label,
                                        color = if (currentTab == tab) PrimaryOrange else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            )
                        }
                    }
                }
            ) { padding ->
                Box(modifier = Modifier.padding(padding)) {
                    when (currentTab) {
                        BottomTab.COOKBOOK -> CookbookScreen(
                            viewModel = viewModel,
                            onRecipeClick = { viewModel.activeRecipe.value = it }
                        )
                        BottomTab.THALI -> ThaliScreen(viewModel = viewModel)
                        BottomTab.GROCERY -> GroceryScreen(viewModel = viewModel)
                        BottomTab.COOK_MODE -> CookModeScreen(
                            recipe = viewModel.filteredRecipes.collectAsState().value.firstOrNull(),
                            onClose = { currentTab = BottomTab.COOKBOOK }
                        )
                    }
                }
            }
        }

        // Modals / Dialogs
        if (showAIImport) {
            AIImportDialog(
                viewModel = viewModel,
                onDismiss = { viewModel.showAIImportDialog.value = false }
            )
        }

        if (showRandomizer) {
            RandomizerDialog(
                viewModel = viewModel,
                onDismiss = { viewModel.showRandomizerDialog.value = false },
                onRecipeSelected = { viewModel.activeRecipe.value = it }
            )
        }
    }
}
