import Foundation

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
    case other = "Other Pantry"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sabziMandi: return "carrot.fill"
        case .masalaDabba: return "flame"
        case .dalsAndGrains: return "archivebox.fill"
        case .dairyAndGhee: return "drop.fill"
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
    var tags: [String]
    var sourceURL: String?
    var prepTimeMinutes: Int
    var calories: Int
    var proteinGrams: Int
    var whistleCount: Int? = nil // For pressure cooker Indian recipes
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
    
    let suiteName = "group.com.chefpocket.recipes"
    let recipesKey = "saved_recipes_key_v2"
    let groceriesKey = "saved_groceries_key_v2"
    let thaliKey = "saved_thali_key_v2"
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    init() {
        loadData()
        if recipes.isEmpty {
            loadComprehensiveRecipes()
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
    
    func getRandomRecipe(category: RecipeCategory? = nil) -> Recipe? {
        let pool = category == nil || category == .all ? recipes : recipes.filter { $0.category == category }
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
        if lower.contains("onion") || lower.contains("tomato") || lower.contains("garlic") || lower.contains("ginger") ||
            lower.contains("chilli") || lower.contains("chili") || lower.contains("coriander") || lower.contains("palak") ||
            lower.contains("spinach") || lower.contains("potato") || lower.contains("gobi") || lower.contains("cauliflower") ||
            lower.contains("methi") || lower.contains("bell pepper") || lower.contains("carrot") || lower.contains("lemon") {
            return .sabziMandi
        } else if lower.contains("jeera") || lower.contains("cumin") || lower.contains("haldi") || lower.contains("turmeric") ||
                    lower.contains("garam masala") || lower.contains("hing") || lower.contains("coriander powder") ||
                    lower.contains("mustard") || lower.contains("pepper") || lower.contains("cardamom") || lower.contains("clove") ||
                    lower.contains("cinnamon") || lower.contains("chilli flakes") || lower.contains("paprika") || lower.contains("salt") {
            return .masalaDabba
        } else if lower.contains("dal") || lower.contains("lentil") || lower.contains("chana") || lower.contains("toor") ||
                    lower.contains("moong") || lower.contains("urad") || lower.contains("rice") || lower.contains("atta") ||
                    lower.contains("flour") || lower.contains("besan") || lower.contains("oats") || lower.contains("spaghetti") {
            return .dalsAndGrains
        } else if lower.contains("paneer") || lower.contains("ghee") || lower.contains("dahi") || lower.contains("curd") ||
                    lower.contains("yogurt") || lower.contains("butter") || lower.contains("milk") || lower.contains("cheese") {
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
            tags: ["Video Import", "Trending"],
            sourceURL: clean,
            prepTimeMinutes: 15,
            calories: 450,
            proteinGrams: 28,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Main Protein (Paneer / Tofu / Chicken)", amount: 200, unit: "g"),
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
    
    // MARK: - Inbuilt Popular Indian & High-Protein Recipes
    private func loadComprehensiveRecipes() {
        let paneerBhurji = Recipe(
            title: "Dhaba Style Paneer Bhurji",
            category: .sabzi,
            tags: ["High-Protein", "Quick (<20m)", "Pure Veg", "Dhaba Style"],
            sourceURL: "https://youtube.com/shorts/DAx73ENDdM4",
            prepTimeMinutes: 15,
            calories: 420,
            proteinGrams: 32,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Fresh Paneer (Crumbled)", amount: 250, unit: "g"),
                Ingredient(name: "Onions (Finely Chopped)", amount: 2, unit: "medium"),
                Ingredient(name: "Tomatoes (Chopped)", amount: 2, unit: "medium"),
                Ingredient(name: "Green Chillies (Slit)", amount: 2, unit: "whole"),
                Ingredient(name: "Desi Ghee / Butter", amount: 1.5, unit: "tbsp"),
                Ingredient(name: "Ginger Garlic Paste", amount: 1, unit: "tbsp"),
                Ingredient(name: "Kasuri Methi", amount: 1, unit: "tsp"),
                Ingredient(name: "Pav Bhaji Masala / Garam Masala", amount: 1, unit: "tsp"),
                Ingredient(name: "Turmeric & Kashmiri Red Chilli", amount: 1, unit: "tsp")
            ],
            instructions: [
                "Heat ghee in a kadhai. Add cumin seeds and let them splutter.",
                "Add finely chopped onions and sauté until golden translucent (about 4 minutes).",
                "Add ginger-garlic paste and green chillies; sauté for 1 minute until raw aroma fades.",
                "Add tomatoes, turmeric, chilli powder, salt, and pav bhaji masala. Cook on medium flame until oil separates.",
                "Crumble fresh paneer and gently fold it into the spiced onion-tomato masala.",
                "Sprinkle crushed kasuri methi and fresh coriander. Cook for just 2 minutes so paneer stays melt-in-mouth soft.",
                "Serve piping hot with whole wheat parathas or toasted butter pav!"
            ],
            isFavorite: true
        )
        
        let dalTadka = Recipe(
            title: "Homestyle Dal Tadka (Ghee Jeera)",
            category: .dal,
            tags: ["Comfort Food", "High-Protein", "Pure Veg", "Everyday Staple"],
            sourceURL: "https://youtube.com/shorts/dal-tadka",
            prepTimeMinutes: 20,
            calories: 340,
            proteinGrams: 18,
            whistleCount: 3,
            ingredients: [
                Ingredient(name: "Toor Dal (Pigeon Peas)", amount: 100, unit: "g"),
                Ingredient(name: "Yellow Moong Dal", amount: 50, unit: "g"),
                Ingredient(name: "Desi Ghee", amount: 2, unit: "tbsp"),
                Ingredient(name: "Cumin Seeds (Jeera)", amount: 1, unit: "tsp"),
                Ingredient(name: "Garlic Cloves (Finely Sliced)", amount: 6, unit: "cloves"),
                Ingredient(name: "Dry Red Kashmiri Chillies", amount: 2, unit: "whole"),
                Ingredient(name: "Hing (Asafoetida)", amount: 0.25, unit: "tsp"),
                Ingredient(name: "Turmeric & Salt", amount: 1, unit: "tsp"),
                Ingredient(name: "Fresh Coriander", amount: 2, unit: "tbsp")
            ],
            instructions: [
                "Wash toor dal and moong dal thoroughly. Pressure cook with 3 cups water, turmeric, and salt for 3 whistles.",
                "Let the pressure release naturally; whisk the dal until smooth and creamy.",
                "In a small tadka pan, heat 2 tablespoons of desi ghee on medium heat.",
                "Add cumin seeds and let them crackle vigorously.",
                "Add sliced garlic and fry until crisp and golden brown (garlic aroma is key!).",
                "Add whole dry red chillies, hing, and a pinch of Kashmiri red chilli for vibrant color.",
                "Pour sizzling tadka immediately over the hot dal and cover with a lid for 2 minutes to trap the smoke aroma.",
                "Garnish with fresh coriander and serve with steamed basmati rice!"
            ],
            isFavorite: true
        )
        
        let moongChilla = Recipe(
            title: "Crispy Paneer-Stuffed Moong Dal Chilla",
            category: .breakfast,
            tags: ["High-Protein", "Quick (<20m)", "Gym Meal", "Low Calorie"],
            sourceURL: "https://youtube.com/shorts/moong-chilla",
            prepTimeMinutes: 12,
            calories: 380,
            proteinGrams: 26,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Soaked Yellow Moong Dal (Blended)", amount: 120, unit: "g"),
                Ingredient(name: "Grated Paneer (For Stuffing)", amount: 100, unit: "g"),
                Ingredient(name: "Grated Carrot & Beetroot", amount: 40, unit: "g"),
                Ingredient(name: "Green Chilli & Ginger", amount: 1, unit: "tsp"),
                Ingredient(name: "Ajwain (Carom Seeds)", amount: 0.5, unit: "tsp"),
                Ingredient(name: "Ghee / Oil (For Drizzle)", amount: 1, unit: "tsp"),
                Ingredient(name: "Chaat Masala", amount: 0.5, unit: "tsp")
            ],
            instructions: [
                "Blend soaked moong dal with ginger, green chilli, and salt into a smooth dosa-like batter.",
                "Heat a cast-iron tawa or non-stick pan, pour a ladle of batter and spread into a thin circle.",
                "Drizzle half a teaspoon of ghee around the edges and cook until golden and crisp underneath.",
                "Flip once for 30 seconds, then flip back.",
                "Generously top one half with grated paneer, crunchy carrots, and a sprinkle of chaat masala.",
                "Fold in half like a taco and slice. Serve with homemade mint-coriander chutney!"
            ],
            isFavorite: true
        )
        
        let dalMakhani = Recipe(
            title: "Restaurant Style Dal Makhani",
            category: .dal,
            tags: ["Dhaba Style", "Comfort Food", "Pure Veg", "Rich Gravy"],
            sourceURL: "https://youtube.com/shorts/dal-makhani",
            prepTimeMinutes: 35,
            calories: 490,
            proteinGrams: 24,
            whistleCount: 5,
            ingredients: [
                Ingredient(name: "Whole Black Urad Dal", amount: 150, unit: "g"),
                Ingredient(name: "Rajma (Red Kidney Beans)", amount: 40, unit: "g"),
                Ingredient(name: "Fresh Tomato Puree", amount: 150, unit: "g"),
                Ingredient(name: "White Butter (Makhan)", amount: 30, unit: "g"),
                Ingredient(name: "Fresh Cream", amount: 2, unit: "tbsp"),
                Ingredient(name: "Kashmiri Red Chilli Powder", amount: 1.5, unit: "tsp"),
                Ingredient(name: "Kasuri Methi (Roasted)", amount: 1, unit: "tsp"),
                Ingredient(name: "Ginger Garlic Paste", amount: 1.5, unit: "tbsp")
            ],
            instructions: [
                "Pressure cook overnight-soaked black urad and rajma with salt and a touch of butter for 5-6 whistles until soft.",
                "Mash the dal lightly with the back of a ladle to release natural starch and creaminess.",
                "In a handi, melt butter, add ginger garlic paste, tomato puree, and Kashmiri chilli powder. Cook until glossy.",
                "Pour in the cooked dal with its cooking liquid and simmer on very low heat for 25-30 minutes, stirring occasionally.",
                "Finish with a generous dollop of butter, roasted kasuri methi, and fresh cream.",
                "Serve with garlic naan or tandoori roti."
            ]
        )
        
        let soyaCurry = Recipe(
            title: "High-Protein Soya Chunk Curry",
            category: .highProtein,
            tags: ["High-Protein", "Gym Meal", "Budget Friendly", "Pure Veg"],
            sourceURL: "https://youtube.com/shorts/soya-curry",
            prepTimeMinutes: 20,
            calories: 410,
            proteinGrams: 45,
            whistleCount: 2,
            ingredients: [
                Ingredient(name: "Soya Chunks (Boiled & Squeezed)", amount: 90, unit: "g"),
                Ingredient(name: "Thick Dahi / Curd", amount: 3, unit: "tbsp"),
                Ingredient(name: "Onions (Pureed)", amount: 2, unit: "medium"),
                Ingredient(name: "Tomatoes (Pureed)", amount: 2, unit: "medium"),
                Ingredient(name: "Mustard Oil / Ghee", amount: 1, unit: "tbsp"),
                Ingredient(name: "Coriander & Cumin Powder", amount: 1, unit: "tbsp"),
                Ingredient(name: "Garam Masala", amount: 1, unit: "tsp")
            ],
            instructions: [
                "Boil soya chunks in salted water for 5 mins; squeeze out all excess water completely.",
                "Marinate soya chunks in curd, red chilli powder, and a pinch of turmeric for 10 minutes.",
                "Heat oil in a pan, lightly roast the marinated soya chunks for 3 minutes and set aside.",
                "In the same pan, cook onion-tomato puree with spices until thick and fragrant.",
                "Add 1 cup hot water and the roasted soya chunks. Cover and simmer for 10 minutes until flavors absorb deeply.",
                "Garnish with coriander. Packs a staggering 45g of clean plant protein!"
            ]
        )
        
        let alooGobi = Recipe(
            title: "Dhaba Aloo Gobi Adraki",
            category: .sabzi,
            tags: ["Sabzi", "Quick (<20m)", "Comfort Food", "Pure Veg"],
            sourceURL: "https://youtube.com/shorts/aloo-gobi",
            prepTimeMinutes: 18,
            calories: 280,
            proteinGrams: 10,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Cauliflower (Cut into Florets)", amount: 250, unit: "g"),
                Ingredient(name: "Potatoes (Cubed)", amount: 2, unit: "medium"),
                Ingredient(name: "Fresh Ginger (Cut into Juliennes)", amount: 2, unit: "inch"),
                Ingredient(name: "Green Chillies", amount: 2, unit: "slit"),
                Ingredient(name: "Mustard Oil", amount: 1.5, unit: "tbsp"),
                Ingredient(name: "Amchur (Dry Mango Powder)", amount: 0.5, unit: "tsp"),
                Ingredient(name: "Turmeric, Cumin & Red Chilli", amount: 1, unit: "tsp")
            ],
            instructions: [
                "Heat mustard oil until smoking, then reduce heat and add cumin seeds and fresh ginger juliennes.",
                "Add potato cubes and cauliflower florets; toss on high flame for 3 minutes for a golden sear.",
                "Lower heat, add turmeric, red chilli, salt, and cover with a lid for 10-12 minutes without adding water.",
                "Open lid, stir in amchur powder, garam masala, and fresh coriander.",
                "Cook uncovered for 2 minutes until crisp and aromatic. Perfect dry sabzi for your thali!"
            ]
        )
        
        let pindiChole = Recipe(
            title: "Amritsari Pindi Chana",
            category: .sabzi,
            tags: ["Dhaba Style", "High-Protein", "Street Food"],
            sourceURL: "https://youtube.com/shorts/pindi-chana",
            prepTimeMinutes: 25,
            calories: 460,
            proteinGrams: 22,
            whistleCount: 5,
            ingredients: [
                Ingredient(name: "Kabuli Chana (Chickpeas)", amount: 180, unit: "g"),
                Ingredient(name: "Tea Bag (For authentic dark color)", amount: 1, unit: "bag"),
                Ingredient(name: "Anardana (Pomegranate Seed Powder)", amount: 1, unit: "tbsp"),
                Ingredient(name: "Chole Masala", amount: 1.5, unit: "tbsp"),
                Ingredient(name: "Desi Ghee (For Tadka)", amount: 2, unit: "tbsp"),
                Ingredient(name: "Ginger Juliennes & Green Chillies", amount: 2, unit: "tbsp")
            ],
            instructions: [
                "Boil soaked chickpeas with a black tea bag, salt, and cinnamon for 5-6 whistles until melt-in-mouth tender.",
                "Discard tea bag. Drain chickpeas, reserving the dark broth.",
                "Toss boiled chickpeas with anardana powder, chole masala, coriander powder, and amchur.",
                "Heat desi ghee in a pan, fry ginger juliennes and green chillies, and pour sizzling ghee over the spiced chole.",
                "Add a splash of chickpea broth and simmer for 8 minutes until the gravy coats the chickpeas.",
                "Serve with fluffy bhature or steamed rice."
            ]
        )
        
        let pavBhaji = Recipe(
            title: "Mumbai Chowpatty Pav Bhaji",
            category: .streetFood,
            tags: ["Street Food", "Comfort Food", "Quick (<20m)"],
            sourceURL: "https://youtube.com/shorts/pav-bhaji",
            prepTimeMinutes: 20,
            calories: 510,
            proteinGrams: 14,
            whistleCount: 3,
            ingredients: [
                Ingredient(name: "Boiled Potatoes, Cauliflower, Peas", amount: 350, unit: "g"),
                Ingredient(name: "Finely Chopped Onions & Capsicum", amount: 150, unit: "g"),
                Ingredient(name: "Finely Pureed Tomatoes", amount: 150, unit: "g"),
                Ingredient(name: "Salted Amul Butter", amount: 40, unit: "g"),
                Ingredient(name: "Everest Pav Bhaji Masala", amount: 2, unit: "tbsp"),
                Ingredient(name: "Kashmiri Chilli Paste (For Red Hue)", amount: 1, unit: "tbsp"),
                Ingredient(name: "Lemon & Fresh Coriander", amount: 1, unit: "lemon")
            ],
            instructions: [
                "Pressure cook potatoes, cauliflower, carrots, and green peas for 3 whistles; mash thoroughly.",
                "On a flat tawa or pan, melt butter, sauté onions and green capsicum until soft.",
                "Add tomato puree, chilli paste, and pav bhaji masala. Mash continuously with a potato masher.",
                "Add the mashed vegetable mix with a cup of warm water; vigorously mash and simmer for 8 minutes.",
                "Finish with extra butter, chopped coriander, and a squeeze of fresh lemon juice.",
                "Serve with piping hot butter-toasted pav!"
            ]
        )
        
        let palakPaneer = Recipe(
            title: "Silky Dhaba Palak Paneer",
            category: .sabzi,
            tags: ["High-Protein", "Pure Veg", "Comfort Food"],
            sourceURL: "https://youtube.com/shorts/palak-paneer",
            prepTimeMinutes: 20,
            calories: 390,
            proteinGrams: 26,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Fresh Spinach (Palak Leaves)", amount: 300, unit: "g"),
                Ingredient(name: "Paneer Cubes (Lightly Sauteed)", amount: 200, unit: "g"),
                Ingredient(name: "Garlic (Crushed)", amount: 6, unit: "cloves"),
                Ingredient(name: "Fresh Cream / Malai", amount: 1.5, unit: "tbsp"),
                Ingredient(name: "Ghee", amount: 1, unit: "tbsp"),
                Ingredient(name: "Kasuri Methi", amount: 1, unit: "tsp")
            ],
            instructions: [
                "Blanch palak in boiling water for exactly 2 minutes, then plunge immediately into ice-cold water to keep vivid green color.",
                "Blend blanched palak with green chillies into a silky smooth puree.",
                "Heat ghee in a pan, fry lots of crushed garlic until light golden.",
                "Add finely chopped onions, tomatoes, and cumin; cook until soft.",
                "Pour in the vibrant green palak puree and simmer on low for 5 minutes.",
                "Gently add paneer cubes, fresh cream, and crushed kasuri methi.",
                "Simmer for 2 minutes and serve with warm rotis or naan."
            ]
        )
        
        let eggBhurji = Recipe(
            title: "Irani Cafe Mumbai Egg Bhurji",
            category: .breakfast,
            tags: ["High-Protein", "Quick (<20m)", "Street Food"],
            sourceURL: "https://youtube.com/shorts/egg-bhurji",
            prepTimeMinutes: 10,
            calories: 360,
            proteinGrams: 24,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Whole Eggs (Whisked)", amount: 4, unit: "large"),
                Ingredient(name: "Finely Diced Onions", amount: 2, unit: "medium"),
                Ingredient(name: "Finely Diced Tomatoes", amount: 1, unit: "large"),
                Ingredient(name: "Green Chillies", amount: 2, unit: "finely cut"),
                Ingredient(name: "Butter / Ghee", amount: 1.5, unit: "tbsp"),
                Ingredient(name: "Turmeric & Pav Bhaji Masala", amount: 1, unit: "tsp")
            ],
            instructions: [
                "Melt butter in a pan; sauté onions and chillies on medium flame until golden brown.",
                "Add tomatoes and spices, cooking until tomatoes turn soft and jammy.",
                "Pour in whisked eggs and gently scramble continuously on medium-low heat.",
                "Remove from heat while eggs are still creamy and moist (do not overcook).",
                "Garnish with chopped coriander and serve with hot buttered toast or pav."
            ]
        )
        
        let paprikaPasta = Recipe(
            title: "35g Protein Paprika Spaghetti",
            category: .fusion,
            tags: ["High-Protein", "Trending", "Fusion"],
            sourceURL: "https://youtube.com/shorts/DAx73ENDdM4",
            prepTimeMinutes: 20,
            calories: 520,
            proteinGrams: 35,
            whistleCount: nil,
            ingredients: [
                Ingredient(name: "Paneer / Firm Tofu", amount: 180, unit: "g"),
                Ingredient(name: "Spaghetti", amount: 150, unit: "g"),
                Ingredient(name: "Almonds (Soaked)", amount: 10, unit: "pieces"),
                Ingredient(name: "Dried Kashmiri Chillies", amount: 4, unit: "whole"),
                Ingredient(name: "Red Bell Pepper", amount: 1, unit: "large"),
                Ingredient(name: "Garlic Cloves", amount: 4, unit: "cloves"),
                Ingredient(name: "Olive Oil", amount: 1, unit: "tbsp"),
                Ingredient(name: "Parmesan Cheese", amount: 25, unit: "g")
            ],
            instructions: [
                "Soak almonds and dried chillies in hot water. Roast bell pepper, onions, and garlic in olive oil.",
                "Blend roasted veggies, soaked almonds, chillies, and paneer with pasta water until ultra-velvety.",
                "Sauté minced garlic in olive oil, pour in the vibrant red sauce, and toss with boiled spaghetti.",
                "Finish with freshly grated parmesan cheese."
            ]
        )

        recipes = [paneerBhurji, dalTadka, moongChilla, dalMakhani, soyaCurry, alooGobi, pindiChole, pavBhaji, palakPaneer, eggBhurji, paprikaPasta]
        saveData()
    }
}
