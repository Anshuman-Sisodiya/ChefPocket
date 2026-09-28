package com.chefpocket.app.ui.modals

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import com.chefpocket.app.viewmodel.RecipeViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun BackupControls(vm: RecipeViewModel) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var status by remember { mutableStateOf("") }
    val export = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
        if (uri != null) scope.launch {
            try {
                val snapshot = vm.repository.exportBackup()
                withContext(Dispatchers.IO) { context.contentResolver.openOutputStream(uri)?.bufferedWriter()?.use { it.write(snapshot) } ?: error("Cannot open backup file") }
                status = "Backup saved."
            } catch (_: Exception) { status = "Could not save the backup." }
        }
    }
    val restore = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) scope.launch {
            try {
                val json = withContext(Dispatchers.IO) {
                    context.contentResolver.openInputStream(uri)?.use { input ->
                        val out = java.io.ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        while (true) { val count = input.read(buffer); if (count < 0) break; require(out.size() + count <= 5_000_000) { "Backup too large" }; out.write(buffer, 0, count) }
                        out.toString("UTF-8")
                    } ?: error("Cannot open backup")
                }
                vm.repository.importBackup(json)
                status = "Backup merged into your kitchen."
            } catch (_: Exception) { status = "Could not restore. Choose a valid ChefPocket Android backup under 5 MB." }
        }
    }
    Text("Kitchen backups", style = MaterialTheme.typography.titleMedium)
    TextButton(onClick = { export.launch("ChefPocket-backup.json") }) { Text("Export backup") }
    TextButton(onClick = { restore.launch(arrayOf("application/json", "application/octet-stream")) }) { Text("Restore backup") }
    if (status.isNotBlank()) Text(status, style = MaterialTheme.typography.bodySmall)
}
