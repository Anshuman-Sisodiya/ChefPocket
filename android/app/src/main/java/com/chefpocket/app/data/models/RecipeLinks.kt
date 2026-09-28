package com.chefpocket.app.data.models

import java.net.URI
import java.net.URLDecoder

object RecipeLinks {
    fun identity(value: String): String = runCatching {
        val uri = URI(value.trim())
        val host = uri.host?.lowercase() ?: return value.trim()
        val path = uri.path ?: ""
        if (host in setOf("youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be")) {
            val id = if (host == "youtu.be") path.trim('/').substringBefore('/') else if (path.startsWith("/shorts/") || path.startsWith("/embed/")) path.split('/').getOrNull(2) else uri.rawQuery?.split('&')?.firstOrNull { it.substringBefore('=') == "v" }?.substringAfter('=')?.let { URLDecoder.decode(it, "UTF-8") }
            if (!id.isNullOrBlank()) return "youtube:$id" // Video IDs are case-sensitive.
        }
        if (host in setOf("instagram.com", "www.instagram.com")) return "instagram:" + path.trim('/')
        "$host$path?" + (uri.rawQuery ?: "")
    }.getOrDefault(value.trim())
}
