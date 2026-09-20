import Foundation
import SwiftUI

// MARK: - Enums
enum RecipeScope: String, CaseIterable, Identifiable {
    case curated = "Curated"
    case myKitchen = "My Kitchen"
    var id: String { rawValue }
}

enum DietType: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case veg = "Veg"
    case nonVeg = "Non-Veg"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .all: return "All"
        case .veg: return "Veg"
        case .nonVeg: return "Non-Veg"
        }
    }
    
    var label: String {
        switch self {
        case .all: return "All Dishes"
        case .veg: return "Vegetarian"
        case .nonVeg: return "Non-Vegetarian"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .all: return .primary
        case .veg: return .green
        case .nonVeg: return .red
        }
    }
}

enum MealType: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case snacks = "Snacks"
    case dinner = "Dinner"
    
    var id: String { rawValue }
    
    var sfSymbol: String {
        switch self {
        case .all: return "sparkles"
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .snacks: return "cup.and.saucer.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
}

enum RecipeCategory: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case bakery = "Bakery"
    case drinks = "Drinks & Shakes"
    case sabzi = "Sabzi"
    case dal = "Dal"
    case highProtein = "High-Protein"
    case breakfast = "Breakfast"
    case streetFood = "Street Food"
    case rice = "Rice & Biryani"
    case fusion = "Fusion"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all: return "sparkles"
        case .bakery: return "birthday.cake.fill"
        case .drinks: return "cup.and.saucer.fill"
        case .sabzi: return "leaf.fill"
        case .dal: return "bowl.fill"
        case .highProtein: return "flame.fill"
        case .breakfast: return "sun.max.fill"
        case .streetFood: return "takeoutbag.and.cup.and.straw.fill"
        case .rice: return "circle.grid.cross.fill"
        case .fusion: return "fork.knife"
        }
    }
}

enum GroceryCategory: String, CaseIterable, Codable, Identifiable {
    case sabziMandi = "Sabzi Mandi (Produce)"
    case masalaDabba = "Masala Dabba (Spices)"
    case dalsAndGrains = "Dals & Grains"
    case dairyAndGhee = "Dairy & Ghee"
    case meatAndEggs = "Meat, Fish & Eggs"
    case other = "Other Pantry"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sabziMandi: return "carrot.fill"
        case .masalaDabba: return "flame"
        case .dalsAndGrains: return "archivebox.fill"
        case .dairyAndGhee: return "drop.fill"
        case .meatAndEggs: return "fork.knife"
        case .other: return "bag.fill"
        }
    }
}

// MARK: - Models
struct Ingredient: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var amount: Double
    var unit: String
    var isChecked: Bool = false
}

struct GroceryItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var amount: String
    var category: GroceryCategory
    var isChecked: Bool = false
    var recipeSource: String?
}

struct Recipe: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var category: RecipeCategory
    var diet: DietType = .veg
    var mealTypes: [MealType] = [.lunch, .dinner]
    var isUserCreated: Bool = false
    var tags: [String]
    var sourceURL: String?
    var prepTimeMinutes: Int
    var calories: Int
    var proteinGrams: Int
    var whistleCount: Int? = nil
    var ingredients: [Ingredient]
    var instructions: [String]
    var isFavorite: Bool = false
}

struct ThaliPlan: Codable, Equatable {
    var dalRecipeId: UUID?
    var sabziRecipeId: UUID?
    var breadOrRice: String = "2x Whole Wheat Phulkas"
    var side: String = "Cucumber Onion Salad & Dahi"
}

// MARK: - RecipeStore
class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var groceries: [GroceryItem] = []
    @Published var thali: ThaliPlan = ThaliPlan()
    
    // UI Filters
    @Published var selectedScope: RecipeScope = .curated
    @Published var selectedDiet: DietType = .all
    @Published var selectedMealType: MealType = .all
    @Published var selectedCategory: RecipeCategory = .all
    
    let suiteName = "group.com.chefpocket.recipes"
    let recipesKey = "saved_recipes_key_v5"
    let groceriesKey = "saved_groceries_key_v5"
    let thaliKey = "saved_thali_key_v5"
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    var curatedRecipes: [Recipe] {
        recipes.filter { !$0.isUserCreated }
    }
    
    var myRecipes: [Recipe] {
        recipes.filter { $0.isUserCreated }
    }
    
    init() {
        loadData()
        if recipes.isEmpty || curatedRecipes.count < 150 {
            loadBundledRecipes()
        }
    }
    
    func loadData() {
        if let data = defaults.data(forKey: recipesKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            self.recipes = decoded
        }
        if let data = defaults.data(forKey: groceriesKey),
           let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            self.groceries = decoded
        }
        if let data = defaults.data(forKey: thaliKey),
           let decoded = try? JSONDecoder().decode(ThaliPlan.self, from: data) {
            self.thali = decoded
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            defaults.set(encoded, forKey: recipesKey)
        }
        if let encoded = try? JSONEncoder().encode(groceries) {
            defaults.set(encoded, forKey: groceriesKey)
        }
        if let encoded = try? JSONEncoder().encode(thali) {
            defaults.set(encoded, forKey: thaliKey)
        }
    }
    
    // MARK: - Recipe Actions
    func deleteRecipe(id: UUID) {
        recipes.removeAll(where: { $0.id == id })
        saveData()
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        saveData()
    }
    
    func toggleIngredient(recipeId: UUID, ingredientId: UUID) {
        guard let rIdx = recipes.firstIndex(where: { $0.id == recipeId }),
              let iIdx = recipes[rIdx].ingredients.firstIndex(where: { $0.id == ingredientId }) else { return }
        recipes[rIdx].ingredients[iIdx].isChecked.toggle()
        saveData()
    }
    
    func toggleFavorite(recipeId: UUID) {
        guard let idx = recipes.firstIndex(where: { $0.id == recipeId }) else { return }
        recipes[idx].isFavorite.toggle()
        saveData()
    }
    
    func addRecipe(_ recipe: Recipe) {
        var newR = recipe
        newR.isUserCreated = true
        recipes.insert(newR, at: 0)
        saveData()
    }
    
    func resetToInbuiltRecipes() {
        loadBundledRecipes()
    }
    
    func getRandomRecipe(scope: RecipeScope? = nil, diet: DietType? = nil, meal: MealType? = nil, category: RecipeCategory? = nil) -> Recipe? {
        var pool = (scope == .myKitchen) ? myRecipes : (scope == .curated ? curatedRecipes : recipes)
        if pool.isEmpty { pool = recipes }
        
        if let d = diet, d != .all {
            pool = pool.filter { $0.diet == d }
        }
        if let m = meal, m != .all {
            pool = pool.filter { $0.mealTypes.contains(m) }
        }
        if let c = category, c != .all {
            pool = pool.filter { $0.category == c }
        }
        return pool.randomElement() ?? recipes.randomElement()
    }
    
    // MARK: - Grocery Actions
    func addIngredientsToGroceries(recipe: Recipe) {
        for ing in recipe.ingredients {
            let cat = categorizeIngredient(ing.name)
            let item = GroceryItem(
                name: ing.name,
                amount: "\(String(format: "%.1f", ing.amount)) \(ing.unit)",
                category: cat,
                recipeSource: recipe.title
            )
            groceries.append(item)
        }
        saveData()
    }
    
    func addCustomGrocery(name: String, amount: String, category: GroceryCategory) {
        let item = GroceryItem(name: name, amount: amount, category: category)
        groceries.append(item)
        saveData()
    }
    
    func toggleGroceryItem(id: UUID) {
        guard let idx = groceries.firstIndex(where: { $0.id == id }) else { return }
        groceries[idx].isChecked.toggle()
        saveData()
    }
    
    func clearCompletedGroceries() {
        groceries.removeAll(where: { $0.isChecked })
        saveData()
    }
    
    func deleteGrocery(at offsets: IndexSet) {
        groceries.remove(atOffsets: offsets)
        saveData()
    }
    
    private func categorizeIngredient(_ name: String) -> GroceryCategory {
        let lower = name.lowercased()
        if lower.contains("chicken") || lower.contains("mutton") || lower.contains("lamb") || lower.contains("fish") ||
            lower.contains("prawn") || lower.contains("egg") || lower.contains("keema") || lower.contains("surmai") || lower.contains("pomfret") {
            return .meatAndEggs
        } else if lower.contains("onion") || lower.contains("tomato") || lower.contains("garlic") || lower.contains("ginger") ||
            lower.contains("chilli") || lower.contains("chili") || lower.contains("coriander") || lower.contains("palak") ||
            lower.contains("spinach") || lower.contains("potato") || lower.contains("gobi") || lower.contains("cauliflower") ||
            lower.contains("methi") || lower.contains("bell pepper") || lower.contains("carrot") || lower.contains("lemon") || lower.contains("shallot") {
            return .sabziMandi
        } else if lower.contains("tea") || lower.contains("coffee") || lower.contains("cocoa") ||
                    lower.contains("chocolate") || lower.contains("vanilla") || lower.contains("baking") ||
                    lower.contains("yeast") || lower.contains("saffron") || lower.contains("kesar") ||
                    lower.contains("rose water") || lower.contains("jeera") || lower.contains("cumin") || lower.contains("haldi") || lower.contains("turmeric") ||
                    lower.contains("garam masala") || lower.contains("hing") || lower.contains("coriander powder") ||
                    lower.contains("mustard") || lower.contains("pepper") || lower.contains("cardamom") || lower.contains("clove") ||
                    lower.contains("cinnamon") || lower.contains("chilli flakes") || lower.contains("paprika") || lower.contains("salt") || lower.contains("fennel") || lower.contains("anardana") {
            return .masalaDabba
        } else if lower.contains("dal") || lower.contains("lentil") || lower.contains("chana") || lower.contains("toor") ||
                    lower.contains("moong") || lower.contains("urad") || lower.contains("rice") || lower.contains("atta") ||
                    lower.contains("flour") || lower.contains("besan") || lower.contains("oats") || lower.contains("spaghetti") || lower.contains("rajma") || lower.contains("poha") {
            return .dalsAndGrains
        } else if lower.contains("paneer") || lower.contains("ghee") || lower.contains("dahi") || lower.contains("curd") ||
                    lower.contains("yogurt") || lower.contains("butter") || lower.contains("milk") || lower.contains("cheese") || lower.contains("cream") {
            return .dairyAndGhee
        } else {
            return .other
        }
    }
    
    // MARK: - Bundled 125+ Recipes Loader
    private func loadBundledRecipes() {
        let existingUserCreated = recipes.filter { $0.isUserCreated }
        
        var loaded: [Recipe] = []
        if let url = Bundle.main.url(forResource: "RecipesData", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            loaded = decoded
        } else {
            let bundlePath = Bundle.main.bundlePath
            let jsonPath = (bundlePath as NSString).appendingPathComponent("RecipesData.json")
            if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
               let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
                loaded = decoded
            }
        }
        
        if !loaded.isEmpty {
            self.recipes = existingUserCreated + loaded
            saveData()
        }
    }
}
