package com.chefpocket.app.ui.modals

import com.chefpocket.app.ui.theme.localized

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.chefpocket.app.data.models.*
import com.chefpocket.app.viewmodel.RecipeViewModel
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

@Composable
fun SettingsDialog(vm: RecipeViewModel, onClose: () -> Unit) {
    var name by rememberSaveable { mutableStateOf(vm.profile.value.name) }
    var diet by rememberSaveable { mutableStateOf(vm.profile.value.dietaryPreference) }
    var endpoint by rememberSaveable { mutableStateOf(vm.importSettings.endpoint) }
    var token by remember { mutableStateOf(vm.importSettings.token) }
    var error by remember { mutableStateOf("") }
    val theme by vm.theme.collectAsState()
    val language by vm.language.collectAsState()
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(modifier = Modifier.widthIn(max = 600.dp).fillMaxWidth(0.95f).imePadding(), shape = MaterialTheme.shapes.large) {
            Column(Modifier.verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Kitchen settings", style = MaterialTheme.typography.headlineSmall)
                OutlinedTextField(name, { name = it }, label = { Text("Your name") }, modifier = Modifier.fillMaxWidth())
                Text("Diet for automatic thali planning")
                DietType.values().forEach { choice ->
                    FilterChip(selected = diet == choice, onClick = { diet = choice }, label = { Text(choice.label) })
                }
                Text("Appearance")
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("system", "light", "dark").forEach { value ->
                        FilterChip(selected = theme == value, onClick = { vm.setTheme(value) }, label = { Text(value.replaceFirstChar { it.uppercase() }) })
                    }
                }
                val languages = mapOf("en" to "English", "hi" to "हिन्दी", "hinglish" to "Hinglish", "es" to "Español", "fr" to "Français", "ta" to "தமிழ்", "te" to "తెలుగు", "bn" to "বাংলা")
                ChoiceMenu("Interface language", languages[language] ?: "English", languages.values.toList()) { value -> vm.setLanguage(languages.entries.first { it.value == value }.key) }
                Text("Import service", style = MaterialTheme.typography.titleMedium)
                OutlinedTextField(endpoint, { endpoint = it }, label = { Text("HTTPS import endpoint") }, modifier = Modifier.fillMaxWidth(), singleLine = true)
                OutlinedTextField(token, { token = it }, label = { Text("Import access token") }, visualTransformation = PasswordVisualTransformation(), modifier = Modifier.fillMaxWidth(), singleLine = true)
                Text("Your app administrator supplies these settings. AI provider keys stay on the server.", style = MaterialTheme.typography.bodySmall)
                BackupControls(vm)
                if (error.isNotBlank()) Text(error, color = MaterialTheme.colorScheme.error)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TextButton(onClick = onClose) { Text(localized("Cancel")) }
                    Button(onClick = {
                        val url = endpoint.trim().toHttpUrlOrNull()
                        if (endpoint.isNotBlank() && (url == null || !url.isHttps || url.username.isNotEmpty() || url.password.isNotEmpty())) error = "Enter a valid HTTPS endpoint."
                        else try {
                            vm.importSettings.token = token
                            vm.importSettings.endpoint = endpoint
                            vm.repository.updateProfile(name.ifBlank { "Home Chef" }, diet, vm.repository.getApiKey())
                            onClose()
                        } catch (_: Exception) { error = "Could not save import access securely." }
                    }) { Text("Save") }
                }
            }
        }
    }
}

@Composable
fun ManualRecipeDialog(vm: RecipeViewModel, onClose: () -> Unit) {
    var title by rememberSaveable { mutableStateOf("") }
    var ingredients by rememberSaveable { mutableStateOf("") }
    var steps by rememberSaveable { mutableStateOf("") }
    var servings by rememberSaveable { mutableStateOf("2") }
    var minutes by rememberSaveable { mutableStateOf("20") }
    var calories by rememberSaveable { mutableStateOf("0") }
    var protein by rememberSaveable { mutableStateOf("0") }
    var whistles by rememberSaveable { mutableStateOf("") }
    var diet by rememberSaveable { mutableStateOf(DietType.VEG) }
    var category by rememberSaveable { mutableStateOf(RecipeCategory.SABZI) }
    var cuisine by rememberSaveable { mutableStateOf(Cuisine.INDIAN) }
    var error by remember { mutableStateOf("") }
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.widthIn(max = 640.dp).fillMaxWidth(0.95f).fillMaxHeight(0.9f).imePadding(), shape = MaterialTheme.shapes.large) {
            Column(Modifier.verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Create a recipe", style = MaterialTheme.typography.headlineSmall)
                OutlinedTextField(title, { title = it }, label = { Text("Dish name") }, modifier = Modifier.fillMaxWidth())
                ChoiceMenu("Diet", diet.label, DietType.values().filter { it != DietType.ALL }.map { it.label }) { label -> diet = DietType.values().first { it.label == label } }
                ChoiceMenu("Category", category.label, RecipeCategory.values().filter { it != RecipeCategory.ALL }.map { it.label }) { label -> category = RecipeCategory.values().first { it.label == label } }
                ChoiceMenu("Cuisine", cuisine.label, Cuisine.values().filter { it != Cuisine.ALL }.map { it.label }) { label -> cuisine = Cuisine.values().first { it.label == label } }
                OutlinedTextField(servings, { servings = it }, label = { Text("Servings (1–100)") })
                OutlinedTextField(minutes, { minutes = it }, label = { Text("Preparation time in minutes") })
                OutlinedTextField(calories, { calories = it }, label = { Text("Calories per serving (0 if unknown)") })
                OutlinedTextField(protein, { protein = it }, label = { Text("Protein grams per serving (0 if unknown)") })
                OutlinedTextField(whistles, { whistles = it }, label = { Text("Whistles (optional)") })
                OutlinedTextField(ingredients, { ingredients = it }, label = { Text("Ingredients: one per line") }, supportingText = { Text("Use name | amount | unit, e.g. Rice | 200 | g") }, minLines = 4, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(steps, { steps = it }, label = { Text("Instructions: one step per line") }, minLines = 4, modifier = Modifier.fillMaxWidth())
                if (error.isNotEmpty()) Text(error, color = MaterialTheme.colorScheme.error)
                Row {
                    TextButton(onClick = onClose) { Text(localized("Cancel")) }
                    Button(onClick = {
                        try {
                            val count = servings.toIntOrNull(); val time = minutes.toIntOrNull()
                            val energy = calories.toIntOrNull(); val grams = protein.toIntOrNull()
                            val whistle = whistles.takeIf { it.isNotBlank() }?.toIntOrNull()
                            require(title.isNotBlank() && count != null && count in 1..100 && time != null && time >= 0 && energy != null && energy >= 0 && grams != null && grams >= 0 && (whistles.isBlank() || (whistle != null && whistle in 1..50))) { "Check the name, servings and numeric fields." }
                            val parsed = ingredients.lines().filter { it.isNotBlank() }.map { line ->
                                val parts = line.split('|').map { it.trim() }
                                require(parts.size == 3) { "Use name | amount | unit for each ingredient." }
                                val amount = parts[1].toDoubleOrNull()
                                require(parts[0].isNotEmpty() && parts[2].isNotEmpty() && amount != null && amount.isFinite() && amount > 0) { "Enter a positive amount and unit for each ingredient." }
                                Ingredient(name = parts[0], amount = amount, unit = parts[2])
                            }
                            val instructions = steps.lines().map { it.trim() }.filter { it.isNotEmpty() }
                            require(parsed.isNotEmpty() && instructions.isNotEmpty()) { "Add ingredients and cooking steps." }
                            vm.addCustomRecipe(Recipe(title = title.trim(), diet = diet.label, category = category.label, cuisine = cuisine.label, servings = count, prepTimeMinutes = time, calories = energy, proteinGrams = grams, whistleCount = whistle, ingredients = parsed, instructions = instructions, isUserCreated = true))
                            onClose()
                        } catch (e: IllegalArgumentException) { error = e.message ?: "Check recipe details." }
                    }) { Text("Save recipe") }
                }
            }
        }
    }
}

@Composable
private fun ChoiceMenu(label: String, selected: String, values: List<String>, choose: (String) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        OutlinedButton(onClick = { expanded = true }) { Text("$label: $selected") }
        DropdownMenu(expanded, onDismissRequest = { expanded = false }) {
            values.forEach { value -> DropdownMenuItem(text = { Text(value) }, onClick = { choose(value); expanded = false }) }
        }
    }
}
