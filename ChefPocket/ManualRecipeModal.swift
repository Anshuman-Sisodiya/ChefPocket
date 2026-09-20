import SwiftUI

struct ManualRecipeModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: RecipeStore
    
    @State private var title = ""
    @State private var cuisine: Cuisine = .indian
    @State private var category: RecipeCategory = .sabzi
    @State private var diet: DietType = .veg
    @State private var selectedMeal: MealType = .dinner
    @State private var prepTime = 15
    @State private var calories = 350
    @State private var protein = 20
    @State private var whistles = 0
    @State private var ingredientInput = ""
    @State private var instructionInput = ""
    
    @State private var ingredientsList: [Ingredient] = []
    @State private var instructionsList: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Details")) {
                    TextField("Recipe Title (e.g. Dhaba Paneer Tikka)", text: $title)
                    
                    Picker("Diet", selection: $diet) {
                        Text("Vegetarian").tag(DietType.veg)
                        Text("Non-Vegetarian").tag(DietType.nonVeg)
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Cuisine", selection: $cuisine) {
                        ForEach(Cuisine.allCases.filter { $0 != .all }) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(RecipeCategory.allCases.filter { $0 != .all }) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    
                    Picker("Primary Meal", selection: $selectedMeal) {
                        ForEach(MealType.allCases.filter { $0 != .all }) { meal in
                            Text(meal.rawValue).tag(meal)
                        }
                    }
                }
                
                Section(header: Text("Cooking & Macros")) {
                    Stepper("Prep Time: \(prepTime) mins", value: $prepTime, in: 5...120, step: 5)
                    Stepper("Calories: \(calories) kcal", value: $calories, in: 50...1500, step: 25)
                    Stepper("Protein: \(protein) g", value: $protein, in: 0...100, step: 2)
                    Stepper("Cooker Whistles: \(whistles == 0 ? "None" : "\(whistles) whistles")", value: $whistles, in: 0...10)
                }
                
                Section(header: Text("Ingredients")) {
                    HStack {
                        TextField("e.g. 200g Paneer, 1 tsp Jeera", text: $ingredientInput)
                        Button(action: addIngredient) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                        }
                        .disabled(ingredientInput.isEmpty)
                    }
                    
                    ForEach(ingredientsList) { ing in
                        HStack {
                            Text("• \(ing.name)")
                            Spacer()
                            Text("\(String(format: "%.1f", ing.amount)) \(ing.unit)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { idx in ingredientsList.remove(atOffsets: idx) }
                }
                
                Section(header: Text("Step-by-Step Instructions")) {
                    HStack {
                        TextField("Add cooking step...", text: $instructionInput)
                        Button(action: addInstruction) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                        }
                        .disabled(instructionInput.isEmpty)
                    }
                    
                    ForEach(Array(instructionsList.enumerated()), id: \.offset) { idx, step in
                        Text("\(idx + 1). \(step)")
                    }
                    .onDelete { idx in instructionsList.remove(atOffsets: idx) }
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                        isPresented = false
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func addIngredient() {
        guard !ingredientInput.isEmpty else { return }
        let ing = Ingredient(name: ingredientInput.trimmingCharacters(in: .whitespaces), amount: 1, unit: "serving")
        ingredientsList.append(ing)
        ingredientInput = ""
    }
    
    private func addInstruction() {
        guard !instructionInput.isEmpty else { return }
        instructionsList.append(instructionInput.trimmingCharacters(in: .whitespaces))
        instructionInput = ""
    }
    
    private func saveRecipe() {
        let recipe = Recipe(
            title: title,
            category: category,
            cuisine: cuisine,
            diet: diet,
            mealTypes: [selectedMeal],
            isUserCreated: true,
            tags: ["Home Recipe", cuisine.rawValue, category.rawValue, diet.rawValue],
            sourceURL: nil,
            prepTimeMinutes: prepTime,
            calories: calories,
            proteinGrams: protein,
            whistleCount: whistles > 0 ? whistles : nil,
            ingredients: ingredientsList.isEmpty ? [Ingredient(name: "Ingredients as required", amount: 1, unit: "plate")] : ingredientsList,
            instructions: instructionsList.isEmpty ? ["Cook and serve hot."] : instructionsList
        )
        store.addRecipe(recipe)
        store.selectedScope = .myKitchen
    }
}
