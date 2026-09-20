import SwiftUI

struct ThaliPlannerView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showingAddedAlert = false
    
    private var availableDals: [Recipe] {
        let filtered = store.recipes.filter { (store.selectedDiet == .all || $0.diet == store.selectedDiet) && $0.category == .dal }
        return filtered.isEmpty ? store.recipes.filter { $0.category == .dal } : filtered
    }
    
    private var availableSabzis: [Recipe] {
        let filtered = store.recipes.filter { (store.selectedDiet == .all || $0.diet == store.selectedDiet) && ($0.category == .sabzi || $0.category == .highProtein) }
        return filtered.isEmpty ? store.recipes.filter { $0.category == .sabzi || $0.category == .highProtein } : filtered
    }
    
    private var selectedDal: Recipe? {
        store.recipes.first(where: { $0.id == store.thali.dalRecipeId }) ?? availableDals.first
    }
    
    private var selectedSabzi: Recipe? {
        store.recipes.first(where: { $0.id == store.thali.sabziRecipeId }) ?? availableSabzis.first
    }
    
    private var totalCalories: Int {
        let dalCal = selectedDal?.calories ?? 0
        let sabziCal = selectedSabzi?.calories ?? 0
        let rotiCal = 160 // 2x Phulkas avg
        let sideCal = 60
        return dalCal + sabziCal + rotiCal + sideCal
    }
    
    private var totalProtein: Int {
        let dalP = selectedDal?.proteinGrams ?? 0
        let sabziP = selectedSabzi?.proteinGrams ?? 0
        let rotiP = 6
        let sideP = 4
        return dalP + sabziP + rotiP + sideP
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("🍱 Aaj Ki Thali Planner")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button(action: randomizeThali) {
                                Label("Randomize", systemImage: "dice.fill")
                                    .font(.caption)
                                    .bold()
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                            }
                        }
                        Text("Balanced Indian dining: Pair a Dal with a Sabzi and Roti for complete protein & nutrition.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Thali Nutrition Macro Meter
                    HStack(spacing: 12) {
                        MacroStatBox(title: "Total Protein", value: "\(totalProtein)g", color: .orange, icon: "flame.fill")
                        MacroStatBox(title: "Total Calories", value: "\(totalCalories) kcal", color: .green, icon: "bolt.fill")
                        MacroStatBox(title: "Course Count", value: "4 Items", color: .blue, icon: "circle.grid.2x2.fill")
                    }
                    .padding(.horizontal)
                    
                    // Thali Assembly Cards
                    VStack(spacing: 14) {
                        // 1. Dal Selector
                        ThaliItemPickerCard(
                            title: "1. Main Dal (Lentils)",
                            icon: "bowl.fill",
                            color: .orange,
                            selectedItem: selectedDal?.title ?? "Select Dal",
                            macros: "\(selectedDal?.proteinGrams ?? 0)g protein • \(selectedDal?.calories ?? 0) kcal",
                            options: availableDals,
                            onSelect: { recipe in
                                store.thali.dalRecipeId = recipe.id
                                store.saveData()
                            }
                        )
                        
                        // 2. Sabzi Selector
                        ThaliItemPickerCard(
                            title: "2. Sabzi / Curry",
                            icon: "leaf.fill",
                            color: .green,
                            selectedItem: selectedSabzi?.title ?? "Select Sabzi",
                            macros: "\(selectedSabzi?.proteinGrams ?? 0)g protein • \(selectedSabzi?.calories ?? 0) kcal",
                            options: availableSabzis,
                            onSelect: { recipe in
                                store.thali.sabziRecipeId = recipe.id
                                store.saveData()
                            }
                        )
                        
                        // 3. Bread & Rice
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("3. Roti & Rice", systemImage: "circle.grid.cross.fill")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("6g protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Picker("Bread", selection: $store.thali.breadOrRice) {
                                Text("2x Phulka Roti").tag("2x Whole Wheat Phulkas")
                                Text("Steamed Basmati Rice").tag("Steamed Basmati Rice")
                                Text("Jeera Rice").tag("Jeera Rice")
                                Text("Ajwain Paratha").tag("Ajwain Paratha")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: store.thali.breadOrRice) { _ in store.saveData() }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
                        
                        // 4. Accompaniment / Salad
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("4. Dahi & Salad", systemImage: "drop.fill")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.purple)
                                Spacer()
                                Text("4g protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Picker("Accompaniment", selection: $store.thali.side) {
                                Text("Cucumber Dahi Raita").tag("Cucumber Dahi Raita")
                                Text("Kachumber Salad").tag("Kachumber Salad")
                                Text("Plain Curd & Achaar").tag("Plain Curd & Achaar")
                                Text("Roasted Papad").tag("Roasted Papad")
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: store.thali.side) { _ in store.saveData() }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
                    }
                    .padding(.horizontal)
                    
                    // Add Entire Thali to Groceries Button
                    Button(action: addThaliToGroceries) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                            Text("Add Entire Thali to Sabzi Mandi List")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .navigationTitle("Thali Planner")
            .alert("Thali Ingredients Added!", isPresented: $showingAddedAlert) {
                Button("Great", role: .cancel) { }
            } message: {
                Text("All ingredients for \(selectedDal?.title ?? "Dal") and \(selectedSabzi?.title ?? "Sabzi") have been organized into your Sabzi Mandi grocery list.")
            }
        }
    }
    
    private func randomizeThali() {
        withAnimation(.spring()) {
            if let dal = availableDals.randomElement() {
                store.thali.dalRecipeId = dal.id
            }
            if let sabzi = availableSabzis.randomElement() {
                store.thali.sabziRecipeId = sabzi.id
            }
            store.saveData()
        }
    }
    
    private func addThaliToGroceries() {
        if let dal = selectedDal {
            store.addIngredientsToGroceries(recipe: dal)
        }
        if let sabzi = selectedSabzi {
            store.addIngredientsToGroceries(recipe: sabzi)
        }
        showingAddedAlert = true
    }
}

struct MacroStatBox: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
}

struct ThaliItemPickerCard: View {
    let title: String
    let icon: String
    let color: Color
    let selectedItem: String
    let macros: String
    let options: [Recipe]
    let onSelect: (Recipe) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(color)
                Spacer()
                Menu {
                    ForEach(options) { r in
                        Button(action: { onSelect(r) }) {
                            Text("\(r.diet.symbol) \(r.title)")
                        }
                    }
                } label: {
                    Text("Change")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.orange)
                }
            }
            
            Text(selectedItem)
                .font(.headline)
                .lineLimit(1)
            
            Text(macros)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
    }
}
