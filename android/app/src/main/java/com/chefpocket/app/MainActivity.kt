package com.chefpocket.app

import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import com.chefpocket.app.ui.screens.MainScreen
import com.chefpocket.app.viewmodel.RecipeViewModel

class MainActivity : ComponentActivity() {
    private val viewModel: RecipeViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handleIntent(intent)
        checkClipboard()

        setContent {
            MainScreen(viewModel = viewModel)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // 1. Android Share Sheet: user tapped "Share" on YouTube Shorts / Reels
        if (Intent.ACTION_SEND == intent.action && "text/plain" == intent.type) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!sharedText.isNullOrBlank()) {
                val url = extractURL(sharedText)
                if (url != null) {
                    viewModel.clipboardDetectedURL.value = url
                    viewModel.showAIImportDialog.value = true
                }
            }
        }

        // 2. Custom deep-link scheme: chefpocket://import?url=...
        if (Intent.ACTION_VIEW == intent.action) {
            val data: Uri? = intent.data
            if (data?.scheme == "chefpocket") {
                val urlParam = data.getQueryParameter("url")
                if (!urlParam.isNullOrBlank()) {
                    viewModel.clipboardDetectedURL.value = urlParam
                    viewModel.showAIImportDialog.value = true
                }
            }
        }
    }

    private fun checkClipboard() {
        try {
            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            val clip = clipboard.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0).text?.toString() ?: ""
                val url = extractURL(text)
                if (url != null && (url.contains("youtube.com") || url.contains("youtu.be") || url.contains("instagram.com"))) {
                    viewModel.clipboardDetectedURL.value = url
                }
            }
        } catch (e: Exception) {
            // Ignore clipboard errors
        }
    }

    private fun extractURL(text: String): String? {
        val parts = text.split("\\s+".toRegex())
        for (part in parts) {
            if (part.startsWith("http://") || part.startsWith("https://")) {
                return part
            }
        }
        return null
    }
}
