package com.chefpocket.app.data.models

import org.junit.Assert.*
import org.junit.Test

class RecipeDataTest {
    @Test fun bundledRecipesHaveUsableCollectionsAndStableIds() {
        val json = java.io.File("src/main/assets/recipes_data.json").readText()
        val recipes = RecipeJson.gson.fromJson(json, Array<Recipe>::class.java).toList()
        assertEquals(434, recipes.size)
        assertEquals(recipes.size, recipes.map { it.id }.toSet().size)
        assertTrue(recipes.all { it.servings > 0 && it.ingredients.isNotEmpty() && it.instructions.isNotEmpty() && it.cuisine.isNotBlank() })
    }
    @Test fun legacyJsonHasDefaults() {
        val recipe = RecipeJson.gson.fromJson("""{"title":"Rice","ingredients":[{"name":"Rice","amount":100,"unit":"g"}]}""", Recipe::class.java)
        assertEquals(2, recipe.servings)
        assertEquals("Indian Regional", recipe.cuisine)
        assertNotNull(recipe.mealTypes)
        assertNotNull(recipe.ingredients.first().id)
        assertTrue(recipe.instructions.isEmpty())
    }
    @Test fun servingsScaleOnlyIngredients() {
        val recipe = Recipe(title = "Rice", servings = 2, calories = 180, ingredients = listOf(Ingredient(name = "Rice", amount = 100.0, unit = "g")))
        assertEquals(50.0, recipe.scaledIngredients(1).first().amount, 0.001)
        assertEquals(200.0, recipe.scaledIngredients(4).first().amount, 0.001)
        assertEquals(180, recipe.calories)
        assertEquals(100.0, recipe.ingredients.first().amount, 0.001)
    }
    @Test fun youtubeAliasesDeduplicateWithoutLowercasingVideoIds() {
        val canonical = RecipeLinks.identity("https://www.youtube.com/watch?feature=share&v=AbCd1234567")
        assertEquals(canonical, RecipeLinks.identity("https://youtu.be/AbCd1234567?si=tracking"))
        assertEquals(canonical, RecipeLinks.identity("https://youtube.com/shorts/AbCd1234567"))
        assertNotEquals(canonical, RecipeLinks.identity("https://youtu.be/abcd1234567"))
        assertNotEquals(canonical, RecipeLinks.identity("https://youtube.com.evil.test/shorts/AbCd1234567"))
    }
    @Test fun explicitNullDefaultsAreRecovered() {
        val recipe = RecipeJson.gson.fromJson("""{"title":"Dal","ingredients":null,"tags":null,"cuisine":null,"servings":0}""", Recipe::class.java)
        assertEquals(1, recipe.servings)
        assertTrue(recipe.ingredients.isEmpty())
        assertTrue(recipe.tags.isEmpty())
        assertEquals("Indian Regional", recipe.cuisine)
    }
    @Test(expected = IllegalArgumentException::class) fun negativeIngredientsRejected() {
        RecipeJson.gson.fromJson("""{"title":"Rice","ingredients":[{"name":"Rice","amount":-1,"unit":"g"}]}""", Recipe::class.java)
    }
}
