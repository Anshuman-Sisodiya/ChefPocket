package com.chefpocket.app.ui.modals

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.chefpocket.app.data.models.*
import com.chefpocket.app.ui.components.FSSAIBadge
import com.chefpocket.app.ui.components.MacroPill
import com.chefpocket.app.ui.theme.PrimaryOrange
import com.chefpocket.app.ui.theme.VegGreen
import com.chefpocket.app.viewmodel.RecipeViewModel

// MARK: - AI Video Import Dialog
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AIImportDialog(
    viewModel: RecipeViewModel,
    onDismiss: () -> Unit
) {
    var urlInput by remember { mutableStateOf(viewModel.clipboardDetectedURL.value ?: "") }
    var inlineKey by remember { mutableStateOf(viewModel.repository.getApiKey()) }
    var showKeyEditor by remember { mutableStateOf(false) }
    var selectedModel by remember { mutableStateOf(viewModel.repository.getPreferredModel()) }
    var keySavedBanner by remember { mutableStateOf(false) }

    val isExtracting by viewModel.isExtracting.collectAsState()
    val statusText by viewModel.extractionStatus.collectAsState()
    val errorText by viewModel.extractionError.collectAsState()
    val duplicateTitle by viewModel.duplicateRecipeTitle.collectAsState()

    val hasKey = inlineKey.isNotBlank()

    Dialog(
        onDismissRequest = { if (!isExtracting) onDismiss() },
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.95f)
                .fillMaxHeight(0.85f)
                .clip(RoundedCornerShape(24.dp)),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp)
                    .verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Header
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = onDismiss, enabled = !isExtracting) {
                        Text("Cancel", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Text(
                        text = "AI Video Import",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.width(48.dp))
                }

                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = null,
                    tint = PrimaryOrange,
                    modifier = Modifier.size(44.dp)
                )

                Text(
                    text = "Paste a YouTube Shorts or Instagram Reels link. Google Gemini AI will extract authentic ingredients, whistle counts, and steps.",
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    lineHeight = 18.sp,
                    modifier = Modifier.padding(horizontal = 8.dp)
                )

                // Video URL Input
                OutlinedTextField(
                    value = urlInput,
                    onValueChange = { urlInput = it },
                    label = { Text("Video Link") },
                    placeholder = { Text("https://youtube.com/shorts/...") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                // Error Banner
                if (errorText != null) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(10.dp))
                            .background(Color.Red.copy(alpha = 0.1f))
                            .padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Warning, contentDescription = null, tint = Color.Red, modifier = Modifier.size(18.dp))
                        Text(text = errorText ?: "", color = Color.Red, fontSize = 12.sp)
                    }
                }

                // Duplicate Alert
                if (duplicateTitle != null) {
                    AlertDialog(
                        onDismissRequest = { viewModel.duplicateRecipeTitle.value = null },
                        title = { Text("Already in Kitchen") },
                        text = { Text("This video has already been imported as '$duplicateTitle'.") },
                        confirmButton = {
                            Button(onClick = {
                                viewModel.duplicateRecipeTitle.value = null
                                viewModel.setScope(RecipeScope.MY_KITCHEN)
                                onDismiss()
                            }) { Text("View Dish") }
                        }
                    )
                }

                // Gemini API Key Card
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Icon(
                                imageVector = if (hasKey) Icons.Default.Verified else Icons.Default.Key,
                                contentDescription = null,
                                tint = if (hasKey) VegGreen else PrimaryOrange,
                                modifier = Modifier.size(16.dp)
                            )
                            Text(
                                text = if (hasKey) "Gemini API Key Active" else "Gemini API Key Setup",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = if (hasKey) VegGreen else PrimaryOrange
                            )
                        }

                        TextButton(onClick = { showKeyEditor = !showKeyEditor }) {
                            Text(if (showKeyEditor) "Done" else (if (hasKey) "Change" else "Add Key"), fontSize = 12.sp, color = PrimaryOrange)
                        }
                    }

                    if (showKeyEditor) {
                        OutlinedTextField(
                            value = inlineKey,
                            onValueChange = { inlineKey = it },
                            placeholder = { Text("Paste Google AI Studio Key") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp)
                        )
                        Button(
                            onClick = {
                                val clean = inlineKey.trim()
                                if (clean.isNotEmpty()) {
                                    viewModel.repository.setApiKey(clean)
                                    keySavedBanner = true
                                    showKeyEditor = false
                                }
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Save Key")
                        }
                    } else if (keySavedBanner) {
                        Text("✓ API Key successfully saved and active.", fontSize = 11.sp, color = VegGreen)
                    } else if (!hasKey) {
                        Text("Add your free Gemini API key from Google AI Studio to extract recipes.", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                // AI Engine Picker
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(10.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant)
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("AI Engine:", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    var expanded by remember { mutableStateOf(false) }

                    Box {
                        TextButton(onClick = { expanded = true }) {
                            Text(
                                when (selectedModel) {
                                    "gemini-3.6-flash" -> "Gemini 3.6 Flash (Recommended)"
                                    "gemini-3.8-flash" -> "Gemini 3.8 Flash"
                                    "gemini-3.0-flash" -> "Gemini 3.0 Flash"
                                    else -> "Gemini 2.0 Flash"
                                },
                                fontSize = 12.sp,
                                color = PrimaryOrange
                            )
                        }
                        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                            DropdownMenuItem(text = { Text("Gemini 3.6 Flash (Recommended)") }, onClick = {
                                selectedModel = "gemini-3.6-flash"
                                viewModel.repository.setPreferredModel("gemini-3.6-flash")
                                expanded = false
                            })
                            DropdownMenuItem(text = { Text("Gemini 3.8 Flash (Cutting Edge)") }, onClick = {
                                selectedModel = "gemini-3.8-flash"
                                viewModel.repository.setPreferredModel("gemini-3.8-flash")
                                expanded = false
                            })
                            DropdownMenuItem(text = { Text("Gemini 3.0 Flash") }, onClick = {
                                selectedModel = "gemini-3.0-flash"
                                viewModel.repository.setPreferredModel("gemini-3.0-flash")
                                expanded = false
                            })
                            DropdownMenuItem(text = { Text("Gemini 2.0 Flash") }, onClick = {
                                selectedModel = "gemini-2.0-flash"
                                viewModel.repository.setPreferredModel("gemini-2.0-flash")
                                expanded = false
                            })
                        }
                    }
                }

                // Progress Indicator
                if (isExtracting) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        CircularProgressIndicator(color = PrimaryOrange)
                        Text(text = statusText, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }

                // Extract Button
                Button(
                    onClick = { viewModel.extractRecipeFromVideo(urlInput, onDismiss) },
                    enabled = urlInput.isNotBlank() && !isExtracting,
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(50.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange)
                ) {
                    Icon(imageVector = Icons.Default.AutoAwesome, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(if (isExtracting) "Extracting Recipe..." else "Extract & Add to Kitchen", fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

// MARK: - "What Should I Cook?" Randomizer Dialog
@Composable
fun RandomizerDialog(
    viewModel: RecipeViewModel,
    onDismiss: () -> Unit,
    onRecipeSelected: (Recipe) -> Unit
) {
    var randomRecipe by remember {
        mutableStateOf(
            viewModel.repository.getRandomRecipe(
                scope = viewModel.selectedScope.value,
                cuisine = viewModel.selectedCuisine.value,
                diet = viewModel.selectedDiet.value,
                category = viewModel.selectedCategory.value
            )
        )
    }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth(0.92f)
                .clip(RoundedCornerShape(20.dp)),
            color = MaterialTheme.colorScheme.surface
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Icon(imageVector = Icons.Default.Shuffle, contentDescription = null, tint = PrimaryOrange, modifier = Modifier.size(36.dp))
                Text("What Should I Cook?", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)

                if (randomRecipe != null) {
                    val r = randomRecipe!!
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(MaterialTheme.colorScheme.surfaceVariant)
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            FSSAIBadge(diet = r.dietType)
                            Text(r.cuisine, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("•", fontSize = 11.sp)
                            Text(r.category, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Text(r.title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            MacroPill(label = "Protein", value = "${r.proteinGrams}g")
                            MacroPill(label = "Time", value = "${r.prepTimeMinutes}m")
                        }
                    }

                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(
                            onClick = {
                                randomRecipe = viewModel.repository.getRandomRecipe(
                                    scope = viewModel.selectedScope.value,
                                    cuisine = viewModel.selectedCuisine.value,
                                    diet = viewModel.selectedDiet.value,
                                    category = viewModel.selectedCategory.value
                                )
                            },
                            modifier = Modifier.weight(1f),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Spin Again")
                        }

                        Button(
                            onClick = {
                                onRecipeSelected(r)
                                onDismiss()
                            },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryOrange),
                            shape = RoundedCornerShape(10.dp)
                        ) {
                            Text("Let's Cook!")
                        }
                    }
                } else {
                    Text("No dishes match current filters.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
