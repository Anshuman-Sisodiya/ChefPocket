import Foundation

enum DietType: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case veg = "Veg"
    case nonVeg = "Non-Veg"
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .all: return "🍽️"
        case .veg: return "🟢"
        case .nonVeg: return "🔴"
        }
    }
    
    var label: String {
        switch self {
        case .all: return "All Dishes"
        case .veg: return "Pure Veg"
        case .nonVeg: return "Non-Veg"
        }
    }
}

enum RecipeCategory: String, CaseIterable, Codable, Identifiable {
    case all = "All"
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

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var groceries: [GroceryItem] = []
    @Published var thali: ThaliPlan = ThaliPlan()
    @Published var selectedDiet: DietType = .all
    
    let suiteName = "group.com.chefpocket.recipes"
    let recipesKey = "saved_recipes_key_v3"
    let groceriesKey = "saved_groceries_key_v3"
    let thaliKey = "saved_thali_key_v3"
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    init() {
        loadData()
        if recipes.isEmpty || recipes.count < 50 {
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
        recipes.insert(recipe, at: 0)
        saveData()
    }
    
    func resetToInbuiltRecipes() {
        loadBundledRecipes()
    }
    
    func getRandomRecipe(diet: DietType? = nil, category: RecipeCategory? = nil) -> Recipe? {
        var pool = recipes
        if let d = diet, d != .all {
            pool = pool.filter { $0.diet == d }
        }
        if let c = category, c != .all {
            pool = pool.filter { $0.category == c }
        }
        return pool.randomElement()
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
        } else if lower.contains("jeera") || lower.contains("cumin") || lower.contains("haldi") || lower.contains("turmeric") ||
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
    
    // MARK: - Video Link Import
    func addFromURL(_ urlString: String) {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let isShort = clean.contains("shorts") || clean.contains("youtube") || clean.contains("youtu.be")
        let defaultTitle = isShort ? "Imported YouTube Recipe" : "Imported Video Recipe"
        
        let newRecipe = Recipe(
            title: defaultTitle,
            category: .highProtein,
            diet: .veg,
            tags: ["Video Import", "Trending"],
            sourceURL: clean,
            prepTimeMinutes: 15,
            calories: 450,
            proteinGrams: 28,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Main Ingredient / Protein", amount: 200, unit: "g"),
                Ingredient(name: "Finely Chopped Onion", amount: 1, unit: "medium"),
                Ingredient(name: "Tomatoes", amount: 2, unit: "medium"),
                Ingredient(name: "Ginger Garlic Paste", amount: 1, unit: "tbsp"),
                Ingredient(name: "Desi Ghee / Olive Oil", amount: 1, unit: "tbsp"),
                Ingredient(name: "Garam Masala & Turmeric", amount: 1, unit: "tsp")
            ],
            instructions: [
                "Extracted from: \(clean)",
                "Heat ghee in a pan and sauté ginger garlic paste with cumin seeds until fragrant.",
                "Add onions and tomatoes, cooking until the oil releases from the masala.",
                "Toss in the main protein and spices, cooking for 6-8 minutes on medium flame.",
                "Garnish with freshly chopped coriander and serve hot with rotis or rice."
            ]
        )
        recipes.insert(newRecipe, at: 0)
        saveData()
        
        if isShort, let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let oEmbedURL = URL(string: "https://www.youtube.com/oembed?url=\(encoded)&format=json") {
            let targetId = newRecipe.id
            URLSession.shared.dataTask(with: oEmbedURL) { [weak self] data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let fetchedTitle = json["title"] as? String else { return }
                
                DispatchQueue.main.async {
                    if let idx = self?.recipes.firstIndex(where: { $0.id == targetId }) {
                        self?.recipes[idx].title = fetchedTitle
                        self?.saveData()
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - Bundled 125+ Recipes Loader
    private func loadBundledRecipes() {
        if let url = Bundle.main.url(forResource: "RecipesData", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data),
           !decoded.isEmpty {
            self.recipes = decoded
            saveData()
            return
        }
        
        // Secondary check in bundle directory
        let bundlePath = Bundle.main.bundlePath
        let jsonPath = (bundlePath as NSString).appendingPathComponent("RecipesData.json")
        if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data),
           !decoded.isEmpty {
            self.recipes = decoded
            saveData()
            return
        }
    }
}
