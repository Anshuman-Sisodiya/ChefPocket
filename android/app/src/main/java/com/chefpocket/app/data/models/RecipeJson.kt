package com.chefpocket.app.data.models

import com.google.gson.*
import java.util.UUID

object RecipeJson {
    // Gson bypasses Kotlin constructors. Populate absent fields before deserializing old bundles/backups.
    val gson: Gson = GsonBuilder().registerTypeAdapter(Recipe::class.java, JsonDeserializer<Recipe> { element, _, _ ->
        val obj = element.asJsonObject.deepCopy()
        val defaults = JsonParser.parseString("""{"category":"Sabzi","cuisine":"Indian Regional","diet":"Veg","mealTypes":["Lunch","Dinner"],"tags":[],"servings":2,"ingredients":[],"instructions":[],"prepTimeMinutes":20,"calories":0,"proteinGrams":0}""").asJsonObject
        defaults.entrySet().forEach { (name, value) -> if (!obj.has(name) || obj[name].isJsonNull) obj.add(name, value) }
        if (!obj.has("id") || obj["id"].isJsonNull) obj.addProperty("id", UUID.randomUUID().toString())
        obj.getAsJsonArray("ingredients").forEach {
            val ingredient = it.asJsonObject
            if (!ingredient.has("id") || ingredient["id"].isJsonNull) ingredient.addProperty("id", UUID.randomUUID().toString())
        }
        val recipe = Gson().fromJson(obj, Recipe::class.java)
        require(!recipe.title.isNullOrBlank() && recipe.ingredients.all { !it.name.isNullOrBlank() && !it.unit.isNullOrBlank() && it.amount.isFinite() && it.amount > 0 }) { "Invalid recipe data" }
        recipe.copy(servings = recipe.servings.coerceAtLeast(1))
    }).create()
}
