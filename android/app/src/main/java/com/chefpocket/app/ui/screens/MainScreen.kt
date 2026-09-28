package com.chefpocket.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.activity.compose.BackHandler
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.unit.dp
import com.chefpocket.app.ui.modals.ManualRecipeDialog
import com.chefpocket.app.ui.modals.SettingsDialog
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
import com.chefpocket.app.ui.theme.*
import androidx.compose.ui.platform.LocalContext
import com.chefpocket.app.viewmodel.RecipeViewModel

enum class BottomTab(val label: String, val icon: ImageVector) {
    COOKBOOK("Cookbook", Icons.Default.MenuBook),
    THALI("Thali", Icons.Default.DinnerDining),
    GROCERY("Mandi", Icons.Default.ShoppingCart),
    COOK_MODE("Cook", Icons.Default.OutdoorGrill)
}

@Composable
fun MainScreen(viewModel: RecipeViewModel) {
    val theme by viewModel.theme.collectAsState()
    val language by viewModel.language.collectAsState()
    val context = LocalContext.current
    val strings = remember(language) { KitchenLanguage(context, language) }
    CompositionLocalProvider(LocalKitchenLanguage provides strings) {
    ChefPocketTheme(darkTheme = if (theme == "system") isSystemInDarkTheme() else theme == "dark") {
        var currentTab by rememberSaveable { mutableStateOf(BottomTab.COOKBOOK) }
        val activeRecipe by viewModel.activeRecipe.collectAsState()
        val showAIImport by viewModel.showAIImportDialog.collectAsState()
        val showRandomizer by viewModel.showRandomizerDialog.collectAsState()

        var isCookModeActive by rememberSaveable { mutableStateOf(false) }

        BackHandler(enabled = isCookModeActive || activeRecipe != null) {
            if (isCookModeActive) isCookModeActive = false else viewModel.activeRecipe.value = null
        }
        if (isCookModeActive) {
            CookModeScreen(
                recipe = activeRecipe,
                viewModel = viewModel,
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
                                        text = localized(tab.label),
                                        color = if (currentTab == tab) PrimaryOrange else MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            )
                        }
                    }
                }
            ) { padding ->
                Box(modifier = Modifier.padding(padding).fillMaxSize(), contentAlignment = Alignment.TopCenter) {
                    when (currentTab) {
                        BottomTab.COOKBOOK -> CookbookScreen(
                            viewModel = viewModel,
                            onRecipeClick = { viewModel.activeRecipe.value = it }
                        )
                        BottomTab.THALI -> ThaliScreen(viewModel = viewModel)
                        BottomTab.GROCERY -> GroceryScreen(viewModel = viewModel)
                        BottomTab.COOK_MODE -> CookRecipePicker(viewModel) {
                            viewModel.activeRecipe.value = it
                            isCookModeActive = true
                        }
                    }
                }
            }
        }

        val showManual by viewModel.showCreateRecipeDialog.collectAsState()
        val showSettings by viewModel.showProfileDialog.collectAsState()
        if (showManual) ManualRecipeDialog(viewModel) { viewModel.showCreateRecipeDialog.value = false }

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
        if (showSettings) SettingsDialog(viewModel) { viewModel.showProfileDialog.value = false }
    }
    }
}
