import Foundation

// MARK: - Ingredient Nutritional Profile (ICMR-NIN & USDA Standards)
struct NutritionalDensity {
    let caloriesPer100g: Double
    let proteinPer100g: Double
}

class NutritionalCalculator {
    static let shared = NutritionalCalculator()
    
    // Standard ICMR-NIN (National Institute of Nutrition) & USDA FoodData Central densities
    private let ingredientDensities: [String: NutritionalDensity] = [
        // Dairy & Fats
        "paneer": NutritionalDensity(caloriesPer100g: 265, proteinPer100g: 18.3),
        "curd": NutritionalDensity(caloriesPer100g: 62, proteinPer100g: 3.5),
        "dahi": NutritionalDensity(caloriesPer100g: 62, proteinPer100g: 3.5),
        "milk": NutritionalDensity(caloriesPer100g: 65, proteinPer100g: 3.3),
        "ghee": NutritionalDensity(caloriesPer100g: 900, proteinPer100g: 0.0),
        "butter": NutritionalDensity(caloriesPer100g: 717, proteinPer100g: 0.9),
        "oil": NutritionalDensity(caloriesPer100g: 884, proteinPer100g: 0.0),
        "cream": NutritionalDensity(caloriesPer100g: 345, proteinPer100g: 2.7),
        "cheese": NutritionalDensity(caloriesPer100g: 402, proteinPer100g: 25.0),
        
        // Poultry, Meat & Seafood
        "chicken": NutritionalDensity(caloriesPer100g: 165, proteinPer100g: 31.0),
        "mutton": NutritionalDensity(caloriesPer100g: 258, proteinPer100g: 25.6),
        "fish": NutritionalDensity(caloriesPer100g: 130, proteinPer100g: 22.0),
        "prawn": NutritionalDensity(caloriesPer100g: 99, proteinPer100g: 20.0),
        "egg": NutritionalDensity(caloriesPer100g: 143, proteinPer100g: 12.6),
        
        // Lentils, Beans & Pulses (Raw equivalents)
        "dal": NutritionalDensity(caloriesPer100g: 343, proteinPer100g: 24.5),
        "toor dal": NutritionalDensity(caloriesPer100g: 343, proteinPer100g: 22.3),
        "moong dal": NutritionalDensity(caloriesPer100g: 347, proteinPer100g: 24.0),
        "chana dal": NutritionalDensity(caloriesPer100g: 372, proteinPer100g: 20.8),
        "urad dal": NutritionalDensity(caloriesPer100g: 341, proteinPer100g: 25.2),
        "masoor dal": NutritionalDensity(caloriesPer100g: 343, proteinPer100g: 25.1),
        "chole": NutritionalDensity(caloriesPer100g: 364, proteinPer100g: 19.3),
        "chickpeas": NutritionalDensity(caloriesPer100g: 364, proteinPer100g: 19.3),
        "rajma": NutritionalDensity(caloriesPer100g: 333, proteinPer100g: 24.0),
        "soybean": NutritionalDensity(caloriesPer100g: 446, proteinPer100g: 36.5),
        "tofu": NutritionalDensity(caloriesPer100g: 76, proteinPer100g: 8.0),
        
        // Grains & Flours
        "rice": NutritionalDensity(caloriesPer100g: 130, proteinPer100g: 2.7), // Cooked
        "basmati rice": NutritionalDensity(caloriesPer100g: 130, proteinPer100g: 3.0),
        "atta": NutritionalDensity(caloriesPer100g: 340, proteinPer100g: 12.1),
        "wheat flour": NutritionalDensity(caloriesPer100g: 340, proteinPer100g: 12.1),
        "maida": NutritionalDensity(caloriesPer100g: 364, proteinPer100g: 10.3),
        "besan": NutritionalDensity(caloriesPer100g: 387, proteinPer100g: 22.4),
        "oats": NutritionalDensity(caloriesPer100g: 389, proteinPer100g: 16.9),
        "suji": NutritionalDensity(caloriesPer100g: 360, proteinPer100g: 12.7),
        "rava": NutritionalDensity(caloriesPer100g: 360, proteinPer100g: 12.7),
        "poha": NutritionalDensity(caloriesPer100g: 350, proteinPer100g: 6.6),
        
        // Vegetables
        "potato": NutritionalDensity(caloriesPer100g: 77, proteinPer100g: 2.0),
        "aloo": NutritionalDensity(caloriesPer100g: 77, proteinPer100g: 2.0),
        "onion": NutritionalDensity(caloriesPer100g: 40, proteinPer100g: 1.1),
        "pyaz": NutritionalDensity(caloriesPer100g: 40, proteinPer100g: 1.1),
        "tomato": NutritionalDensity(caloriesPer100g: 18, proteinPer100g: 0.9),
        "tamatar": NutritionalDensity(caloriesPer100g: 18, proteinPer100g: 0.9),
        "spinach": NutritionalDensity(caloriesPer100g: 23, proteinPer100g: 2.9),
        "palak": NutritionalDensity(caloriesPer100g: 23, proteinPer100g: 2.9),
        "peas": NutritionalDensity(caloriesPer100g: 81, proteinPer100g: 5.4),
        "matar": NutritionalDensity(caloriesPer100g: 81, proteinPer100g: 5.4),
        "cauliflower": NutritionalDensity(caloriesPer100g: 25, proteinPer100g: 1.9),
        "gobi": NutritionalDensity(caloriesPer100g: 25, proteinPer100g: 1.9),
        
        // Nuts & Seeds
        "cashew": NutritionalDensity(caloriesPer100g: 553, proteinPer100g: 18.2),
        "kaju": NutritionalDensity(caloriesPer100g: 553, proteinPer100g: 18.2),
        "almond": NutritionalDensity(caloriesPer100g: 579, proteinPer100g: 21.2),
        "badam": NutritionalDensity(caloriesPer100g: 579, proteinPer100g: 21.2),
        "peanut": NutritionalDensity(caloriesPer100g: 567, proteinPer100g: 25.8)
    ]
    
    /// Normalizes units to estimated gram weight
    private func normalizeToGrams(amount: Double, unit: String) -> Double {
        let u = unit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if u.contains("kg") {
            return amount * 1000.0
        } else if u.contains("g") || u.contains("gram") {
            return amount
        } else if u.contains("tbsp") || u.contains("tablespoon") {
            return amount * 15.0
        } else if u.contains("tsp") || u.contains("teaspoon") {
            return amount * 5.0
        } else if u.contains("cup") {
            return amount * 200.0
        } else if u.contains("ml") {
            return amount * 1.0
        } else if u.contains("l") || u.contains("litre") {
            return amount * 1000.0
        } else if u.contains("piece") || u.contains("egg") || u.contains("pc") {
            return amount * 50.0
        }
        return amount * 20.0
    }
    
    /// Finds the best matching nutritional density for an ingredient name
    private func findDensity(for name: String) -> NutritionalDensity? {
        let lower = name.lowercased()
        for (key, density) in ingredientDensities {
            if lower.contains(key) {
                return density
            }
        }
        return nil
    }
    
    /// Calculates deterministic calories and protein for a recipe
    func calculateNutrition(for ingredients: [Ingredient], servings: Int) -> (totalCalories: Int, totalProtein: Int, perServingCalories: Int, perServingProtein: Int) {
        var totalCals: Double = 0
        var totalProt: Double = 0
        
        for ing in ingredients {
            let grams = normalizeToGrams(amount: ing.amount, unit: ing.unit)
            if let density = findDensity(for: ing.name) {
                let ratio = grams / 100.0
                totalCals += density.caloriesPer100g * ratio
                totalProt += density.proteinPer100g * ratio
            } else {
                // Default estimate for unidentified items (herbs, mild spices, seasonings)
                totalCals += grams * 0.5
                totalProt += grams * 0.02
            }
        }
        
        let s = max(1, servings)
        let perServingCals = Int(round(totalCals / Double(s)))
        let perServingProt = Int(round(totalProt / Double(s)))
        
        return (
            totalCalories: Int(round(totalCals)),
            totalProtein: Int(round(totalProt)),
            perServingCalories: perServingCals,
            perServingProtein: perServingProt
        )
    }
}
