package com.chefpocket.app.data.models

import java.util.UUID

enum class RecipeScope(val label: String) {
    CURATED("Curated"),
    MY_KITCHEN("My Kitchen"),
    FAVORITES("Favorites")
}

enum class DietType(val label: String) {
    ALL("All"),
    VEG("Veg"),
    NON_VEG("Non-Veg")
}

enum class Cuisine(val label: String) {
    ALL("All"),
    INDIAN("Indian Regional"),
    CONTINENTAL("Continental & Italian"),
    ASIAN("Asian & Indo-Chinese"),
    MEXICAN("Mexican & Tex-Mex"),
    MIDDLE_EASTERN("Middle Eastern"),
    CAFE("Cafe & Bistro"),
    BAKERY("Bakery & Breads"),
    DRINKS("Drinks & Brews");

    companion object {
        fun fromString(str: String?): Cuisine {
            if (str == null) return INDIAN
            return values().firstOrNull { it.label.equals(str, ignoreCase = true) || it.name.equals(str, ignoreCase = true) } ?: INDIAN
        }
    }
}

enum class RecipeCategory(val label: String) {
    ALL("All"),
    SABZI("Sabzi"),
    DAL("Dal"),
    HIGH_PROTEIN("High-Protein"),
    BREAKFAST("Breakfast"),
    STREET_FOOD("Street Food"),
    RICE("Rice & Biryani"),
    BAKERY("Bakery"),
    DRINKS("Drinks & Shakes"),
    FUSION("Fusion");

    companion object {
        fun fromString(str: String?): RecipeCategory {
            if (str == null) return SABZI
            return values().firstOrNull { it.label.equals(str, ignoreCase = true) || it.name.equals(str, ignoreCase = true) } ?: SABZI
        }
    }
}

enum class MealType(val label: String) {
    ALL("All"),
    BREAKFAST("Breakfast"),
    LUNCH("Lunch"),
    DINNER("Dinner"),
    SNACK("Snack")
}

data class Ingredient(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val amount: Double,
    val unit: String,
    var isChecked: Boolean = false
)

data class Recipe(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val category: String = RecipeCategory.SABZI.label,
    val cuisine: String = Cuisine.INDIAN.label,
    val diet: String = DietType.VEG.label,
    val mealTypes: List<String> = listOf("Lunch", "Dinner"),
    var isUserCreated: Boolean = false,
    val tags: List<String> = emptyList(),
    val sourceURL: String? = null,
    val prepTimeMinutes: Int = 20,
    val calories: Int = 350,
    val proteinGrams: Int = 15,
    val whistleCount: Int? = null,
    val ingredients: List<Ingredient> = emptyList(),
    val instructions: List<String> = emptyList(),
    var isFavorite: Boolean = false
) {
    val dietType: DietType
        get() = if (diet.equals("Non-Veg", ignoreCase = true)) DietType.NON_VEG else DietType.VEG
}

data class GroceryItem(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val amount: Double,
    val unit: String,
    val category: String = "Pantry",
    var isChecked: Boolean = false
)

data class ThaliPlan(
    var grainRecipeId: String? = null,
    var sabziRecipeId: String? = null,
    var dalRecipeId: String? = null,
    var accompanimentRecipeId: String? = null,
    var saladRecipeId: String? = null,
    var sweetRecipeId: String? = null
)

data class UserProfile(
    var name: String = "Home Chef",
    var email: String = "chef@pocket.local",
    var dietaryPreference: DietType = DietType.ALL,
    var geminiApiKey: String = "",
    var isGoogleAccount: Boolean = false
)
