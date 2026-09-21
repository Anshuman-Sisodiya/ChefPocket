import Foundation
import SwiftUI

// MARK: - Enums
enum RecipeScope: String, CaseIterable, Identifiable {
    case curated = "Curated"
    case myKitchen = "My Kitchen"
    case favorites = "Favorites"
    var id: String { rawValue }
}

enum Cuisine: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case indian = "Indian Regional"
    case continental = "Continental & Italian"
    case asian = "Asian & Indo-Chinese"
    case mexican = "Mexican & Tex-Mex"
    case middleEastern = "Middle Eastern"
    case cafe = "Cafe & Bistro"
    case bakery = "Bakery & Breads"
    case drinks = "Drinks & Brews"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .all: return "globe"
        case .indian: return "flame.fill"
        case .continental: return "fork.knife"
        case .asian: return "takeoutbag.and.cup.and.straw.fill"
        case .mexican: return "flame"
        case .middleEastern: return "sun.max.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .bakery: return "birthday.cake.fill"
        case .drinks: return "mug.fill"
        }
    }
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
    var cuisine: Cuisine = .indian
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
    
    enum CodingKeys: String, CodingKey {
        case id, title, category, cuisine, diet, mealTypes, isUserCreated, tags, sourceURL
        case prepTimeMinutes, calories, proteinGrams, whistleCount, ingredients, instructions, isFavorite
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        category: RecipeCategory,
        cuisine: Cuisine = .indian,
        diet: DietType = .veg,
        mealTypes: [MealType] = [.lunch, .dinner],
        isUserCreated: Bool = false,
        tags: [String],
        sourceURL: String? = nil,
        prepTimeMinutes: Int,
        calories: Int,
        proteinGrams: Int,
        whistleCount: Int? = nil,
        ingredients: [Ingredient],
        instructions: [String],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.cuisine = cuisine
        self.diet = diet
        self.mealTypes = mealTypes
        self.isUserCreated = isUserCreated
        self.tags = tags
        self.sourceURL = sourceURL
        self.prepTimeMinutes = prepTimeMinutes
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.whistleCount = whistleCount
        self.ingredients = ingredients
        self.instructions = instructions
        self.isFavorite = isFavorite
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(RecipeCategory.self, forKey: .category)
        cuisine = try container.decodeIfPresent(Cuisine.self, forKey: .cuisine) ?? .indian
        diet = try container.decodeIfPresent(DietType.self, forKey: .diet) ?? .veg
        mealTypes = try container.decodeIfPresent([MealType].self, forKey: .mealTypes) ?? [.lunch, .dinner]
        isUserCreated = try container.decodeIfPresent(Bool.self, forKey: .isUserCreated) ?? false
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        prepTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .prepTimeMinutes) ?? 25
        calories = try container.decodeIfPresent(Int.self, forKey: .calories) ?? 350
        proteinGrams = try container.decodeIfPresent(Int.self, forKey: .proteinGrams) ?? 10
        whistleCount = try container.decodeIfPresent(Int.self, forKey: .whistleCount)
        ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
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
    @Published var selectedCuisine: Cuisine = .all
    @Published var selectedDiet: DietType = .all
    @Published var selectedMealType: MealType = .all
    @Published var selectedCategory: RecipeCategory = .all
    
    let suiteName = "group.com.chefpocket.recipes"
    
    // PERMANENT UNVERSIONED USER STORAGE KEYS
    let permanentUserRecipesKey = "chefpocket_user_custom_recipes_permanent"
    let permanentFavoritesKey = "chefpocket_user_favorites_permanent"
    let deletedTombstonesKey = "chefpocket_deleted_recipe_tombstones_permanent"
    let migrationCompletedKey = "chefpocket_did_migrate_v131"
    
    // CACHED / SYSTEM KEYS
    let recipesKey = "saved_recipes_key_v7"
    let groceriesKey = "saved_groceries_key_v7"
    let thaliKey = "saved_thali_key_v7"
    
    // HISTORICAL KEYS FOR RETROACTIVE MIGRATION SCAN
    private let historicalRecipeKeys = [
        "saved_recipes_key",
        "saved_recipes_key_v1",
        "saved_recipes_key_v2",
        "saved_recipes_key_v3",
        "saved_recipes_key_v4",
        "saved_recipes_key_v5",
        "saved_recipes_key_v6"
    ]
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    var curatedRecipes: [Recipe] {
        recipes.filter { !$0.isUserCreated }
    }
    
    var myRecipes: [Recipe] {
        recipes.filter { $0.isUserCreated }
    }
    
    var favoriteRecipes: [Recipe] {
        recipes.filter { $0.isFavorite }
    }
    
    init() {
        // 1. Run migration scan ONCE to recover any custom recipes from historical versions
        migrateHistoricalUserData()
        
        // 2. Load permanent user data + bundled recipes
        loadData()
        
        // 3. Ensure bundled recipes are always present and up-to-date
        if curatedRecipes.count < 350 {
            loadBundledRecipes()
        }
    }
    
    // MARK: - Retroactive Migration Scanner (Run Once & Purge)
    /// Recovers all user-created recipes and favorites from historical versions (v1...v6) and permanently protects them.
    func migrateHistoricalUserData() {
        // Guard: If migration already completed, do NOT re-run to avoid resurrecting deleted recipes!
        if defaults.bool(forKey: migrationCompletedKey) {
            return
        }
        
        var recoveredCustom: [Recipe] = []
        var recoveredFavorites: Set<String> = []
        let tombstones = getDeletedTombstones()
        
        // 1. Load any already-permanent custom recipes
        if let permData = defaults.data(forKey: permanentUserRecipesKey) ?? UserDefaults.standard.data(forKey: permanentUserRecipesKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: permData) {
            recoveredCustom.append(contentsOf: decoded)
        }
        
        // 2. Load existing permanent favorites
        if let favData = defaults.data(forKey: permanentFavoritesKey) ?? UserDefaults.standard.data(forKey: permanentFavoritesKey),
           let favList = try? JSONDecoder().decode([String].self, from: favData) {
            recoveredFavorites.formUnion(favList)
        }
        
        // 3. Scan historical keys
        let targets = [defaults, UserDefaults.standard]
        for def in targets {
            for key in historicalRecipeKeys {
                if let data = def.data(forKey: key),
                   let list = try? JSONDecoder().decode([Recipe].self, from: data) {
                    for r in list {
                        // Skip any recipe that was previously deleted!
                        if tombstones.contains(r.id.uuidString) || tombstones.contains(r.title.lowercased()) {
                            continue
                        }
                        if r.isUserCreated {
                            if !recoveredCustom.contains(where: { $0.id == r.id || $0.title.lowercased() == r.title.lowercased() }) {
                                recoveredCustom.append(r)
                            }
                        }
                        if r.isFavorite {
                            recoveredFavorites.insert(r.id.uuidString)
                            recoveredFavorites.insert(r.title.lowercased())
                        }
                    }
                }
                // Purge legacy key so stale items are never re-read!
                def.removeObject(forKey: key)
            }
        }
        
        // Filter recovered custom against tombstones
        recoveredCustom = recoveredCustom.filter { !tombstones.contains($0.id.uuidString) && !tombstones.contains($0.title.lowercased()) }
        
        // 4. Persist recovered items to permanent storage
        if let encodedCustom = try? JSONEncoder().encode(recoveredCustom) {
            defaults.set(encodedCustom, forKey: permanentUserRecipesKey)
            UserDefaults.standard.set(encodedCustom, forKey: permanentUserRecipesKey)
        }
        if let encodedFavs = try? JSONEncoder().encode(Array(recoveredFavorites)) {
            defaults.set(encodedFavs, forKey: permanentFavoritesKey)
            UserDefaults.standard.set(encodedFavs, forKey: permanentFavoritesKey)
        }
        
        // Mark migration completed
        defaults.set(true, forKey: migrationCompletedKey)
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
    }
    
    private func getDeletedTombstones() -> Set<String> {
        if let data = defaults.data(forKey: deletedTombstonesKey) ?? UserDefaults.standard.data(forKey: deletedTombstonesKey),
           let list = try? JSONDecoder().decode([String].self, from: data) {
            return Set(list)
        }
        return []
    }
    
    private func removeTombstone(id: UUID, title: String) {
        var stones = getDeletedTombstones()
        stones.remove(id.uuidString)
        stones.remove(title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
        if let encoded = try? JSONEncoder().encode(Array(stones)) {
            defaults.set(encoded, forKey: deletedTombstonesKey)
            UserDefaults.standard.set(encoded, forKey: deletedTombstonesKey)
        }
    }

    private func recordDeletedTombstone(id: UUID, title: String) {
        var stones = getDeletedTombstones()
        stones.insert(id.uuidString)
        stones.insert(title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
        if let encoded = try? JSONEncoder().encode(Array(stones)) {
            defaults.set(encoded, forKey: deletedTombstonesKey)
            UserDefaults.standard.set(encoded, forKey: deletedTombstonesKey)
        }
    }
    
    // MARK: - Data Loading & Saving
    func loadData() {
        let tombstones = getDeletedTombstones()
        
        // A. Load permanent user custom recipes
        var userRecipes: [Recipe] = []
        if let data = defaults.data(forKey: permanentUserRecipesKey) ?? UserDefaults.standard.data(forKey: permanentUserRecipesKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            userRecipes = decoded.filter { !tombstones.contains($0.id.uuidString) && !tombstones.contains($0.title.lowercased()) }
        }
        
        // B. Load favorite IDs
        var favoriteSet: Set<String> = []
        if let favData = defaults.data(forKey: permanentFavoritesKey) ?? UserDefaults.standard.data(forKey: permanentFavoritesKey),
           let favList = try? JSONDecoder().decode([String].self, from: favData) {
            favoriteSet = Set(favList)
        }
        
        // C. Load bundled curated recipes
        var bundled = fetchBundledRecipes()
        
        // D. Apply favorites to bundled recipes
        for i in 0..<bundled.count {
            if favoriteSet.contains(bundled[i].id.uuidString) || favoriteSet.contains(bundled[i].title.lowercased()) {
                bundled[i].isFavorite = true
            }
        }
        
        // E. Merge: User recipes first, then curated
        self.recipes = userRecipes + bundled
        
        // F. Load groceries & thali
        if let data = defaults.data(forKey: groceriesKey),
           let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            self.groceries = decoded
        } else if let data = defaults.data(forKey: "saved_groceries_key_v6"),
                  let decoded = try? JSONDecoder().decode([GroceryItem].self, from: data) {
            self.groceries = decoded
        }
        
        if let data = defaults.data(forKey: thaliKey),
           let decoded = try? JSONDecoder().decode(ThaliPlan.self, from: data) {
            self.thali = decoded
        } else if let data = defaults.data(forKey: "saved_thali_key_v6"),
                  let decoded = try? JSONDecoder().decode(ThaliPlan.self, from: data) {
            self.thali = decoded
        }
    }
    
    func saveData() {
        // 1. Permanently persist user custom recipes
        let custom = myRecipes
        if let encodedCustom = try? JSONEncoder().encode(custom) {
            defaults.set(encodedCustom, forKey: permanentUserRecipesKey)
            UserDefaults.standard.set(encodedCustom, forKey: permanentUserRecipesKey)
        }
        
        // 2. Permanently persist favorites
        let favoriteIdentifiers = recipes.filter { $0.isFavorite }.map { $0.id.uuidString }
        if let encodedFavs = try? JSONEncoder().encode(favoriteIdentifiers) {
            defaults.set(encodedFavs, forKey: permanentFavoritesKey)
            UserDefaults.standard.set(encodedFavs, forKey: permanentFavoritesKey)
        }
        
        // 3. Cache full active recipe list
        if let encoded = try? JSONEncoder().encode(recipes) {
            defaults.set(encoded, forKey: recipesKey)
        }
        if let encoded = try? JSONEncoder().encode(groceries) {
            defaults.set(encoded, forKey: groceriesKey)
        }
        if let encoded = try? JSONEncoder().encode(thali) {
            defaults.set(encoded, forKey: thaliKey)
        }
        
        // Post notification for cloud sync listeners
        NotificationCenter.default.post(name: NSNotification.Name("ChefPocketDataDidChange"), object: nil)
    }
    
    private func fetchBundledRecipes() -> [Recipe] {
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
        return loaded
    }
    
    private func loadBundledRecipes() {
        let custom = myRecipes
        var bundled = fetchBundledRecipes()
        
        var favoriteSet: Set<String> = []
        if let favData = defaults.data(forKey: permanentFavoritesKey),
           let favList = try? JSONDecoder().decode([String].self, from: favData) {
            favoriteSet = Set(favList)
        }
        
        for i in 0..<bundled.count {
            if favoriteSet.contains(bundled[i].id.uuidString) || favoriteSet.contains(bundled[i].title.lowercased()) {
                bundled[i].isFavorite = true
            }
        }
        
        if !bundled.isEmpty {
            self.recipes = custom + bundled
            saveData()
        }
    }
    
    func resetToInbuiltRecipes() {
        loadBundledRecipes()
    }
    
    // MARK: - URL Normalization & Deduplication
    static func normalizeURL(_ urlString: String) -> String {
        var clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return "" }
        
        // Remove tracking query strings (?si=..., &feature=..., etc.)
        if let qIdx = clean.firstIndex(of: "?") {
            let query = String(clean[qIdx...])
            if clean.contains("watch?v=") {
                if let vRange = query.range(of: "v=") {
                    let afterV = String(query[vRange.upperBound...])
                    let vid = afterV.split(separator: "&").first ?? ""
                    return "yt:\(vid)"
                }
            }
            clean = String(clean[..<qIdx])
        }
        
        // YouTube Shorts: /shorts/ABC123xyz
        if clean.contains("/shorts/") {
            let parts = clean.components(separatedBy: "/shorts/")
            if let last = parts.last {
                let vid = last.split(separator: "/").first?.split(separator: "?").first ?? ""
                return "yt:\(vid)"
            }
        }
        
        // youtu.be/ABC123xyz
        if clean.contains("youtu.be/") {
            let parts = clean.components(separatedBy: "youtu.be/")
            if let last = parts.last {
                let vid = last.split(separator: "/").first?.split(separator: "?").first ?? ""
                return "yt:\(vid)"
            }
        }
        
        // Instagram: /reel/ABC123xyz or /p/ABC123xyz
        if clean.contains("/reel/") {
            let parts = clean.components(separatedBy: "/reel/")
            if let last = parts.last {
                let code = last.split(separator: "/").first?.split(separator: "?").first ?? ""
                return "ig:\(code)"
            }
        }
        if clean.contains("/p/") {
            let parts = clean.components(separatedBy: "/p/")
            if let last = parts.last {
                let code = last.split(separator: "/").first?.split(separator: "?").first ?? ""
                return "ig:\(code)"
            }
        }
        
        return clean
    }
    
    func findRecipe(matchingURL urlString: String) -> Recipe? {
        let targetNorm = RecipeStore.normalizeURL(urlString)
        guard !targetNorm.isEmpty else { return nil }
        return recipes.first { r in
            if let s = r.sourceURL, !s.isEmpty {
                return RecipeStore.normalizeURL(s) == targetNorm
            }
            return false
        }
    }
    
    // MARK: - Recipe Actions
    @discardableResult
    func addRecipe(_ recipe: Recipe) -> (recipe: Recipe, isNew: Bool) {
        // Prevent adding duplicate recipe with same source link
        if let s = recipe.sourceURL, !s.isEmpty, let existing = findRecipe(matchingURL: s) {
            return (existing, false)
        }
        
        removeTombstone(id: recipe.id, title: recipe.title)
        
        var newR = recipe
        newR.isUserCreated = true
        recipes.insert(newR, at: 0)
        saveData()
        return (newR, true)
    }
    
    func deleteRecipe(id: UUID) {
        if let r = recipes.first(where: { $0.id == id }) {
            recordDeletedTombstone(id: r.id, title: r.title)
        }
        recipes.removeAll(where: { $0.id == id })
        saveData()
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        for idx in offsets {
            if idx < recipes.count {
                let r = recipes[idx]
                recordDeletedTombstone(id: r.id, title: r.title)
            }
        }
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
    
    func getRandomRecipe(
        scope: RecipeScope? = nil,
        cuisine: Cuisine? = nil,
        diet: DietType? = nil,
        meal: MealType? = nil,
        category: RecipeCategory? = nil
    ) -> Recipe? {
        var pool: [Recipe]
        switch scope {
        case .myKitchen:
            pool = myRecipes
        case .favorites:
            pool = favoriteRecipes
        default:
            pool = curatedRecipes
        }
        if pool.isEmpty { pool = recipes }
        
        if let cu = cuisine, cu != .all {
            pool = pool.filter { $0.cuisine == cu }
        }
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
            lower.contains("prawn") || lower.contains("egg") || lower.contains("keema") || lower.contains("surmai") || lower.contains("pomfret") ||
            lower.contains("salmon") || lower.contains("shrimp") || lower.contains("beef") || lower.contains("bacon") || lower.contains("pepperoni") {
            return .meatAndEggs
        } else if lower.contains("onion") || lower.contains("tomato") || lower.contains("garlic") || lower.contains("ginger") ||
            lower.contains("chilli") || lower.contains("chili") || lower.contains("coriander") || lower.contains("palak") ||
            lower.contains("spinach") || lower.contains("potato") || lower.contains("gobi") || lower.contains("cauliflower") ||
            lower.contains("methi") || lower.contains("bell pepper") || lower.contains("capsicum") || lower.contains("carrot") ||
            lower.contains("lemon") || lower.contains("lime") || lower.contains("shallot") || lower.contains("zucchini") ||
            lower.contains("cabbage") || lower.contains("mushroom") || lower.contains("scallion") || lower.contains("avocado") ||
            lower.contains("mint") || lower.contains("basil") || lower.contains("parsley") || lower.contains("rosemary") || lower.contains("thyme") {
            return .sabziMandi
        } else if lower.contains("tea") || lower.contains("coffee") || lower.contains("cocoa") ||
                    lower.contains("chocolate") || lower.contains("vanilla") || lower.contains("baking") ||
                    lower.contains("yeast") || lower.contains("saffron") || lower.contains("kesar") ||
                    lower.contains("rose water") || lower.contains("jeera") || lower.contains("cumin") || lower.contains("haldi") || lower.contains("turmeric") ||
                    lower.contains("garam masala") || lower.contains("hing") || lower.contains("coriander powder") ||
                    lower.contains("mustard") || lower.contains("pepper") || lower.contains("cardamom") || lower.contains("clove") ||
                    lower.contains("cinnamon") || lower.contains("chilli flakes") || lower.contains("paprika") || lower.contains("salt") ||
                    lower.contains("fennel") || lower.contains("anardana") || lower.contains("sumac") || lower.contains("za'atar") || lower.contains("nutmeg") {
            return .masalaDabba
        } else if lower.contains("dal") || lower.contains("lentil") || lower.contains("chana") || lower.contains("toor") ||
                    lower.contains("moong") || lower.contains("urad") || lower.contains("rice") || lower.contains("atta") ||
                    lower.contains("flour") || lower.contains("besan") || lower.contains("oats") || lower.contains("spaghetti") ||
                    lower.contains("penne") || lower.contains("fettuccine") || lower.contains("fusilli") || lower.contains("pasta") ||
                    lower.contains("noodles") || lower.contains("rajma") || lower.contains("poha") || lower.contains("beans") || lower.contains("chickpea") {
            return .dalsAndGrains
        } else if lower.contains("paneer") || lower.contains("ghee") || lower.contains("dahi") || lower.contains("curd") ||
                    lower.contains("yogurt") || lower.contains("butter") || lower.contains("milk") || lower.contains("cheese") ||
                    lower.contains("cream") || lower.contains("ricotta") || lower.contains("mozzarella") || lower.contains("parmesan") ||
                    lower.contains("cheddar") || lower.contains("burrata") || lower.contains("halloumi") || lower.contains("feta") {
            return .dairyAndGhee
        } else {
            return .other
        }
    }
}
