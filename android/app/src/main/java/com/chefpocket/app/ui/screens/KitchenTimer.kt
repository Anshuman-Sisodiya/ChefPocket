package com.chefpocket.app.ui.screens

import com.chefpocket.app.ui.theme.localized

import android.os.SystemClock
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.chefpocket.app.data.models.Recipe
import com.chefpocket.app.viewmodel.RecipeViewModel
import kotlinx.coroutines.delay

@Composable
fun CookRecipePicker(vm: RecipeViewModel, onSelect: (Recipe) -> Unit) {
    val recipes by vm.recipes.collectAsState()
    var query by rememberSaveable { mutableStateOf("") }
    LazyColumn(Modifier.widthIn(max = 900.dp).fillMaxSize(), contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        item { Text("Cook mode", style = MaterialTheme.typography.headlineMedium) }
        item { KitchenTimer(vm) }
        item { OutlinedTextField(query, { query = it }, label = { Text("Choose a recipe") }, modifier = Modifier.fillMaxWidth()) }
        items(recipes.filter { it.title.contains(query, true) }, key = { it.id }) { recipe ->
            OutlinedButton(onClick = { onSelect(recipe) }, modifier = Modifier.fillMaxWidth()) { Text(recipe.title) }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun KitchenTimer(vm: RecipeViewModel) {
    val deadline by vm.timerDeadline.collectAsState()
    val remaining by vm.timerRemaining.collectAsState()
    LaunchedEffect(deadline) {
        val end = deadline ?: return@LaunchedEffect
        while (true) {
            val seconds = ((end - SystemClock.elapsedRealtime() + 999) / 1000).toInt().coerceAtLeast(0)
            vm.timerRemaining.value = seconds
            if (seconds == 0) { vm.timerDeadline.value = null; break }
            delay(250)
        }
    }
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Kitchen timer", style = MaterialTheme.typography.titleMedium)
            Text("%02d:%02d".format(remaining / 60, remaining % 60), style = MaterialTheme.typography.headlineLarge)
            Text("Keep Cook mode open for the countdown. The timer uses elapsed time when you return.", style = MaterialTheme.typography.bodySmall)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(3, 5, 10, 15, 30).forEach { minutes ->
                    OutlinedButton(onClick = { vm.startTimer(minutes * 60) }) { Text("${minutes}m") }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(onClick = { if (deadline != null) vm.pauseTimer() else vm.startTimer(remaining) }, enabled = remaining > 0) { Text(if (deadline != null) "Pause" else "Resume") }
                TextButton(onClick = { vm.pauseTimer(); vm.timerRemaining.value = 0 }) { Text(localized("Reset")) }
            }
        }
    }
}
