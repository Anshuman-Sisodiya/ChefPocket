import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var amount: Double
    var unit: String
    var isChecked: Bool = false
}

struct Recipe: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var sourceURL: String?
    var prepTimeMinutes: Int
    var calories: Int
    var proteinGrams: Int
    var ingredients: [Ingredient]
    var instructions: [String]
    var isFavorite: Bool = false
}

// Global persistence store with App Group and standard fallback
class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    
    let suiteName = "group.com.chefpocket.recipes"
    let storageKey = "saved_recipes_key"
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
    }
    
    init() {
        loadRecipes()
        if recipes.isEmpty {
            loadDefaultRecipe()
        }
    }
    
    func loadDefaultRecipe() {
        let paprikaSpaghetti = Recipe(
            title: "35g Protein Paprika Spaghetti",
            sourceURL: "https://youtube.com/shorts/DAx73ENDdM4",
            prepTimeMinutes: 20,
            calories: 520,
            proteinGrams: 35,
            ingredients: [
                Ingredient(name: "Almonds", amount: 10, unit: "pieces"),
                Ingredient(name: "Dried Red Chillies", amount: 4, unit: "whole"),
                Ingredient(name: "Red Bell Pepper", amount: 1, unit: "large"),
                Ingredient(name: "Paneer / Firm Tofu", amount: 180, unit: "g"),
                Ingredient(name: "Spaghetti", amount: 150, unit: "g"),
                Ingredient(name: "Garlic Cloves", amount: 4, unit: "cloves"),
                Ingredient(name: "Olive Oil", amount: 1, unit: "tbsp"),
                Ingredient(name: "Parmesan Cheese", amount: 25, unit: "g")
            ],
            instructions: [
                "Soak almonds and dried red chillies in boiling hot water.",
                "Roast chopped red bell pepper, onion, carrot, and garlic with olive oil, salt, and pepper.",
                "Blend roasted veggies, soaked almonds, chillies, paneer, and a splash of reserved pasta water until smooth.",
                "Sauté minced garlic and chilli flakes in olive oil, then pour in the blended sauce.",
                "Toss with boiled spaghetti and finish with freshly grated parmesan cheese."
            ]
        )
        recipes.append(paprikaSpaghetti)
        saveRecipes()
    }
    
    func saveRecipes() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    func loadRecipes() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            self.recipes = decoded
        }
    }
    
    func deleteRecipe(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        saveRecipes()
    }
    
    func toggleIngredient(recipeId: UUID, ingredientId: UUID) {
        guard let recipeIdx = recipes.firstIndex(where: { $0.id == recipeId }),
              let ingIdx = recipes[recipeIdx].ingredients.firstIndex(where: { $0.id == ingredientId }) else { return }
        
        recipes[recipeIdx].ingredients[ingIdx].isChecked.toggle()
        saveRecipes()
    }
    
    func toggleFavorite(recipeId: UUID) {
        guard let idx = recipes.firstIndex(where: { $0.id == recipeId }) else { return }
        recipes[idx].isFavorite.toggle()
        saveRecipes()
    }
    
    func addFromURL(_ urlString: String) {
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let isShort = cleanURL.contains("shorts") || cleanURL.contains("youtube") || cleanURL.contains("youtu.be")
        let defaultTitle = isShort ? "Imported YouTube Recipe" : "Imported Video Recipe"
        
        let newRecipe = Recipe(
            title: defaultTitle,
            sourceURL: cleanURL,
            prepTimeMinutes: 15,
            calories: 480,
            proteinGrams: 30,
            ingredients: [
                Ingredient(name: "Main Protein / Veggies", amount: 200, unit: "g"),
                Ingredient(name: "Seasoning / Spices", amount: 1, unit: "tsp"),
                Ingredient(name: "Cooking Oil / Butter", amount: 1, unit: "tbsp")
            ],
            instructions: [
                "Extracted from link: \(cleanURL)",
                "Follow video creator's instructions for ingredient prep and cooking.",
                "Serve hot and enjoy!"
            ]
        )
        recipes.insert(newRecipe, at: 0)
        saveRecipes()
        
        // Asynchronously fetch video title from YouTube oEmbed if applicable
        if isShort, let encoded = cleanURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let oEmbedURL = URL(string: "https://www.youtube.com/oembed?url=\(encoded)&format=json") {
            let targetId = newRecipe.id
            URLSession.shared.dataTask(with: oEmbedURL) { [weak self] data, _, _ in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let fetchedTitle = json["title"] as? String else { return }
                
                DispatchQueue.main.async {
                    if let idx = self?.recipes.firstIndex(where: { $0.id == targetId }) {
                        self?.recipes[idx].title = fetchedTitle
                        self?.saveRecipes()
                    }
                }
            }.resume()
        }
    }
}
