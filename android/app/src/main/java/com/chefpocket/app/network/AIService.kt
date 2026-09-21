package com.chefpocket.app.network

import com.chefpocket.app.data.models.*
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.URLEncoder
import java.util.concurrent.TimeUnit

class AIService {
    companion object {
        val shared = AIService()
    }

    private val client = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(45, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val gson = Gson()

    suspend fun extractRecipe(
        urlString: String,
        userApiKey: String?,
        preferredModel: String = "gemini-3.6-flash",
        statusCallback: (String) -> Unit = {}
    ): Recipe = withContext(Dispatchers.IO) {
        val cleanURL = urlString.trim()
        if (cleanURL.isEmpty()) {
            throw IllegalArgumentException("Please provide a valid YouTube Shorts or Instagram Reels link.")
        }

        val activeKey = userApiKey?.trim() ?: ""
        if (activeKey.isEmpty()) {
            throw IllegalArgumentException("Gemini API Key missing. Please add your free key in the setup card below.")
        }

        statusCallback("Analyzing video link & creator ingredients...")
        val (title, description) = fetchVideoMetadataAndCaption(cleanURL)

        statusCallback("Generating recipe with Gemini AI... ✨")
        callGeminiAPI(
            videoTitle = title,
            videoDescription = description,
            videoURL = cleanURL,
            apiKey = activeKey,
            preferredModel = preferredModel
        )
    }

    private fun fetchVideoMetadataAndCaption(urlString: String): Pair<String, String> {
        var targetURL = urlString
        if (urlString.contains("shorts/")) {
            val id = urlString.substringAfter("shorts/").substringBefore("?").substringBefore("/")
            targetURL = "https://www.youtube.com/watch?v=$id"
        } else if (urlString.contains("youtu.be/")) {
            val id = urlString.substringAfter("youtu.be/").substringBefore("?").substringBefore("/")
            targetURL = "https://www.youtube.com/watch?v=$id"
        }

        var title = ""
        var description = ""

        // 1. Query oEmbed with Mobile Safari User-Agent
        try {
            val encoded = URLEncoder.encode(targetURL, "UTF-8")
            val oembedUrl = "https://www.youtube.com/oembed?url=$encoded&format=json"
            val req = Request.Builder()
                .url(oembedUrl)
                .header("User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)")
                .build()

            client.newCall(req).execute().use { resp ->
                if (resp.isSuccessful) {
                    val body = resp.body?.string()
                    if (!body.isNullOrBlank()) {
                        val json = JsonParser.parseString(body).asJsonObject
                        if (json.has("title")) {
                            title = json.get("title").asString
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Fetch page HTML for meta description
        try {
            val pageReq = Request.Builder()
                .url(targetURL)
                .header("User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko)")
                .build()

            client.newCall(pageReq).execute().use { resp ->
                if (resp.isSuccessful) {
                    val html = resp.body?.string() ?: ""
                    if (html.contains("property=\"og:description\" content=\"")) {
                        description = html.substringAfter("property=\"og:description\" content=\"").substringBefore("\"")
                    } else if (html.contains("name=\"description\" content=\"")) {
                        description = html.substringAfter("name=\"description\" content=\"").substringBefore("\"")
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        if (title.isEmpty()) {
            title = if (urlString.contains("shorts") || urlString.contains("youtube")) "Chef Special YouTube Dish" else "Trending Video Dish"
        }
        return Pair(title, description)
    }

    private suspend fun callGeminiAPI(
        videoTitle: String,
        videoDescription: String,
        videoURL: String,
        apiKey: String,
        preferredModel: String
    ): Recipe {
        val candidateModels = mutableListOf<String>()
        if (preferredModel.isNotBlank()) {
            candidateModels.add(preferredModel.trim())
        }
        val defaults = listOf(
            "gemini-3.6-flash",
            "gemini-3.8-flash",
            "gemini-3.5-flash",
            "gemini-3.0-flash",
            "gemini-2.5-flash",
            "gemini-2.0-flash",
            "gemini-1.5-flash-latest",
            "gemini-1.5-flash",
            "gemini-2.0-flash-lite"
        )
        for (m in defaults) {
            if (!candidateModels.contains(m)) {
                candidateModels.add(m)
            }
        }

        var lastException: Exception? = null

        for (model in candidateModels) {
            try {
                return executeGeminiRequest(model, videoTitle, videoDescription, videoURL, apiKey)
            } catch (e: GeminiNotFoundException) {
                lastException = e
                continue
            } catch (e: Exception) {
                throw e
            }
        }

        // Auto-Discovery fallback
        val dynamicModel = fetchFirstAvailableModel(apiKey)
        if (dynamicModel != null) {
            return executeGeminiRequest(dynamicModel, videoTitle, videoDescription, videoURL, apiKey)
        }

        throw lastException ?: Exception("Could not find a supported Gemini model. Verify key permissions in Google AI Studio.")
    }

    private fun fetchFirstAvailableModel(apiKey: String): String? {
        return try {
            val url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey"
            val req = Request.Builder().url(url).build()
            client.newCall(req).execute().use { resp ->
                if (resp.isSuccessful) {
                    val body = resp.body?.string() ?: return null
                    val json = JsonParser.parseString(body).asJsonObject
                    if (json.has("models")) {
                        val arr = json.getAsJsonArray("models")
                        for (item in arr) {
                            val obj = item.asJsonObject
                            val name = obj.get("name")?.asString ?: ""
                            val methods = obj.getAsJsonArray("supportedGenerationMethods")?.map { it.asString } ?: emptyList()
                            if (methods.contains("generateContent")) {
                                val clean = name.replace("models/", "")
                                if (clean.contains("flash") || clean.contains("gemini")) {
                                    return clean
                                }
                            }
                        }
                    }
                }
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun executeGeminiRequest(
        model: String,
        videoTitle: String,
        videoDescription: String,
        videoURL: String,
        apiKey: String
    ): Recipe {
        val endpoint = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey"

        val promptText = """
        You are an elite Michelin-trained executive chef assistant. Analyze this video metadata and extract the exact culinary recipe.
        
        Video Title: "$videoTitle"
        Video Caption / Description: "$videoDescription"
        Video URL: "$videoURL"
        
        CRITICAL RULES:
        1. Identify the exact dish name from the title/caption.
        2. Extract authentic ingredients with precise metric amounts (grams, ml, tbsp, tsp, piece).
        3. If it is an Indian pressure cooker dish (dal, rajma, chana, biryani, mutton, etc.), determine the exact cooker whistle count (e.g. 2, 3, 4 whistles). If not a pressure cooker recipe, set whistleCount to null.
        4. Accurately calculate calories and protein grams per serving.
        5. Provide numbered, professional cooking instructions with specific heat levels and cooking cues. Never include YouTube URLs or 'extracted from' lines in instructions.
        6. Determine Diet ("Veg" or "Non-Veg").
        7. Determine Cuisine ("Indian Regional", "Continental & Italian", "Asian & Indo-Chinese", "Mexican & Tex-Mex", "Middle Eastern", "Cafe & Bistro", "Bakery & Breads", or "Drinks & Brews").
        8. Determine Category ("Sabzi", "Dal", "High-Protein", "Breakfast", "Street Food", "Rice & Biryani", "Bakery", "Drinks & Shakes", or "Fusion").
        
        STRICT REQUIREMENT: Respond ONLY with a valid JSON object (no markdown quotes, no explanation, no text before or after):
        {
          "title": "Dish Name",
          "category": "Sabzi",
          "cuisine": "Indian Regional",
          "diet": "Veg",
          "mealTypes": ["Lunch", "Dinner"],
          "prepTimeMinutes": 25,
          "calories": 380,
          "proteinGrams": 24,
          "whistleCount": 3,
          "tags": ["Authentic", "Video Import", "High-Protein"],
          "ingredients": [
            {"name": "Paneer / Chicken", "amount": 250, "unit": "g"},
            {"name": "Desi Ghee", "amount": 2, "unit": "tbsp"},
            {"name": "Cumin Seeds", "amount": 1, "unit": "tsp"}
          ],
          "instructions": [
            "Heat ghee in a pan on medium heat and splutter cumin seeds.",
            "Add aromatics, sauté until golden brown, and add spices.",
            "Cover and cook until tender. Serve hot."
          ]
        }
        """.trimIndent()

        val rootJson = JsonObject()
        val contentsArr = com.google.gson.JsonArray()
        val contentObj = JsonObject()
        val partsArr = com.google.gson.JsonArray()
        val partObj = JsonObject()
        partObj.addProperty("text", promptText)
        partsArr.add(partObj)
        contentObj.add("parts", partsArr)
        contentsArr.add(contentObj)
        rootJson.add("contents", contentsArr)

        val genConfig = JsonObject()
        genConfig.addProperty("temperature", 0.2)
        rootJson.add("generationConfig", genConfig)

        val body = rootJson.toString().toRequestBody("application/json".toMediaType())
        val req = Request.Builder()
            .url(endpoint)
            .post(body)
            .build()

        client.newCall(req).execute().use { resp ->
            val respCode = resp.code
            val respBody = resp.body?.string() ?: ""

            if (!resp.isSuccessful) {
                if (respCode == 404) {
                    throw GeminiNotFoundException("Model $model returned 404")
                }
                var errMsg = "Gemini API Error ($respCode)"
                try {
                    val errJson = JsonParser.parseString(respBody).asJsonObject
                    if (errJson.has("error")) {
                        val errObj = errJson.getAsJsonObject("error")
                        val msg = errObj.get("message")?.asString ?: ""
                        if (msg.contains("API_KEY_INVALID") || msg.contains("API key not valid")) {
                            errMsg = "Invalid Gemini API Key. Please verify in Google AI Studio."
                        } else if (msg.contains("RESOURCE_EXHAUSTED") || respCode == 429) {
                            errMsg = "Gemini quota exceeded. Please wait a moment."
                        } else {
                            errMsg = "$msg ($respCode)"
                        }
                    }
                } catch (e: Exception) {
                    // fallback
                }
                throw Exception(errMsg)
            }

            // Parse response
            val root = JsonParser.parseString(respBody).asJsonObject
            val candidateText = root.getAsJsonArray("candidates")
                ?.get(0)?.asJsonObject
                ?.getAsJsonObject("content")
                ?.getAsJsonArray("parts")
                ?.get(0)?.asJsonObject
                ?.get("text")?.asString
                ?: throw Exception("Could not parse recipe structure from AI response.")

            var cleanJson = candidateText.replace("```json", "").replace("```", "").trim()
            if (cleanJson.contains("{") && cleanJson.contains("}")) {
                cleanJson = cleanJson.substring(cleanJson.indexOf("{"), cleanJson.lastIndexOf("}") + 1)
            }

            val recipeObj = JsonParser.parseString(cleanJson).asJsonObject
            val title = recipeObj.get("title")?.asString ?: videoTitle
            val category = recipeObj.get("category")?.asString ?: "Sabzi"
            val cuisine = recipeObj.get("cuisine")?.asString ?: "Indian Regional"
            val diet = recipeObj.get("diet")?.asString ?: "Veg"
            val prep = recipeObj.get("prepTimeMinutes")?.asInt ?: 20
            val cals = recipeObj.get("calories")?.asInt ?: 350
            val protein = recipeObj.get("proteinGrams")?.asInt ?: 20
            val whistle = if (recipeObj.has("whistleCount") && !recipeObj.get("whistleCount").isJsonNull) {
                recipeObj.get("whistleCount").asInt
            } else null

            val ings = mutableListOf<Ingredient>()
            recipeObj.getAsJsonArray("ingredients")?.forEach { item ->
                val o = item.asJsonObject
                ings.add(
                    Ingredient(
                        name = o.get("name")?.asString ?: "Ingredient",
                        amount = o.get("amount")?.asDouble ?: 1.0,
                        unit = o.get("unit")?.asString ?: "g"
                    )
                )
            }

            val steps = mutableListOf<String>()
            recipeObj.getAsJsonArray("instructions")?.forEach { step ->
                val s = step.asString
                val lower = s.lowercase().trim()
                if (!lower.startsWith("extracted from") && !lower.startsWith("source:") && !lower.contains("http")) {
                    steps.add(s)
                }
            }

            return Recipe(
                title = title,
                category = category,
                cuisine = cuisine,
                diet = diet,
                isUserCreated = true,
                sourceURL = videoURL,
                prepTimeMinutes = prep,
                calories = cals,
                proteinGrams = protein,
                whistleCount = whistle,
                ingredients = if (ings.isNotEmpty()) ings else listOf(Ingredient(name = "Main ingredients", amount = 250.0, unit = "g")),
                instructions = if (steps.isNotEmpty()) steps else listOf("Prepare ingredients according to video instructions, cook and serve hot.")
            )
        }
    }
}

class GeminiNotFoundException(msg: String) : Exception(msg)
