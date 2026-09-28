package com.chefpocket.app.network

import com.chefpocket.app.data.models.Recipe
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import kotlinx.coroutines.suspendCancellableCoroutine
import okhttp3.*
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class AIService {
    companion object { val shared = AIService() }
    private val client = OkHttpClient.Builder().callTimeout(120, TimeUnit.SECONDS)
        .connectTimeout(15, TimeUnit.SECONDS).readTimeout(120, TimeUnit.SECONDS)
        .followRedirects(false).build()

    suspend fun extractRecipe(urlString: String, settings: ImportSettings, sourceText: String = ""): Recipe {
        val source = urlString.trim().toHttpUrlOrNull()
        require(source != null && source.isHttps && source.host in setOf("youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be", "instagram.com", "www.instagram.com") && source.username.isEmpty() && source.password.isEmpty() && source.port == 443) { "Enter an HTTPS YouTube or Instagram link." }
        val endpoint = settings.endpoint.toHttpUrlOrNull()
        require(endpoint != null && endpoint.isHttps && endpoint.username.isEmpty() && endpoint.password.isEmpty() && settings.token.isNotBlank()) { "Configure your import service and access token in Settings." }
        require(sourceText.length <= 30000) { "Paste up to 30,000 characters of recipe text." }
        val payload = JsonObject().apply { addProperty("url", source.toString()); addProperty("sourceText", sourceText) }
        val request = Request.Builder().url(endpoint).header("Authorization", "Bearer " + settings.token)
            .post(payload.toString().toRequestBody("application/json".toMediaType())).build()
        return suspendCancellableCoroutine { continuation ->
            val call = client.newCall(request)
            continuation.invokeOnCancellation { call.cancel() }
            call.enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    if (continuation.isActive) continuation.resumeWithException(e)
                }
                override fun onResponse(call: Call, response: Response) {
                    response.use {
                        try {
                            val body = response.body ?: error("Empty response from import service.")
                            val sourceBody = body.source()
                            sourceBody.request(1_000_001)
                            require(sourceBody.buffer.size <= 1_000_000) { "Import response is too large." }
                            val json = JsonParser.parseString(sourceBody.readUtf8()).asJsonObject
                            if (!response.isSuccessful) error(json.getAsJsonObject("error")?.get("message")?.asString ?: "Import service is unavailable.")
                            val recipe = Gson().fromJson(json.getAsJsonObject("recipe"), Recipe::class.java)
                            require(recipe != null && !recipe.title.isNullOrBlank() && !recipe.ingredients.isNullOrEmpty() && !recipe.instructions.isNullOrEmpty() && recipe.servings > 0 && recipe.ingredients.all { it.amount.isFinite() && it.amount > 0 && !it.name.isNullOrBlank() }) { "The service returned an incomplete recipe." }
                            if (continuation.isActive) continuation.resume(recipe)
                        } catch (e: Exception) { if (continuation.isActive) continuation.resumeWithException(e) }
                    }
                }
            })
        }
    }
}
