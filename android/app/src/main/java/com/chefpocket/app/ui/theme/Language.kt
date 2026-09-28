package com.chefpocket.app.ui.theme

import android.content.Context
import androidx.compose.runtime.*
import com.google.gson.JsonParser

class KitchenLanguage(context: Context, val code: String) {
    private val dictionaries = JsonParser.parseString(context.assets.open("translations.json").bufferedReader().use { it.readText() }).asJsonObject
    fun text(english: String): String {
        val key = dictionaries.getAsJsonObject("en").entrySet().firstOrNull { it.value.asString == english }?.key ?: return english
        return dictionaries.getAsJsonObject(code)?.get(key)?.asString ?: english
    }
}
val LocalKitchenLanguage = staticCompositionLocalOf<KitchenLanguage?> { null }
@Composable
fun localized(english: String): String = LocalKitchenLanguage.current?.text(english) ?: english
