import SwiftUI

struct ThaliPlannerView: View {
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var languageManager = LanguageManager.shared
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
                    // 1. Hero Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageManager.t("thali_title"))
                                    .font(.title2)
                                    .bold()
                                Text(languageManager.t("thali_subtitle"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: randomizeThali) {
                                Label(languageManager.t("thali_suggest"), systemImage: "sparkles")
                                    .font(.caption)
                                    .bold()
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // 2. Nutrition Macro Meter Cards
                    HStack(spacing: 12) {
                        AestheticMacroStat(
                            title: "Total Protein",
                            value: "\(totalProtein)g",
                            icon: "flame.fill",
                            color: .orange
                        )
                        AestheticMacroStat(
                            title: "Total Calories",
                            value: "\(totalCalories) kcal",
                            icon: "bolt.fill",
                            color: .green
                        )
                        AestheticMacroStat(
                            title: "Complete Diet",
                            value: "4 Courses",
                            icon: "circle.grid.2x2.fill",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // 3. Royal Thali Platter Showcase (Visual assembly)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assembled Thali Platter")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Dal Course
                            if let dal = selectedDal {
                                ThaliCourseCard(
                                    courseNumber: "1",
                                    courseType: "Main Dal / Lentils",
                                    icon: "bowl.fill",
                                    color: .orange,
                                    recipe: dal,
                                    options: availableDals
                                ) { chosen in
                                    store.thali.dalRecipeId = chosen.id
                                    store.saveData()
                                }
                            }
                            
                            // Sabzi Course
                            if let sabzi = selectedSabzi {
                                ThaliCourseCard(
                                    courseNumber: "2",
                                    courseType: "Sabzi / Curry",
                                    icon: "leaf.fill",
                                    color: .green,
                                    recipe: sabzi,
                                    options: availableSabzis
                                ) { chosen in
                                    store.thali.sabziRecipeId = chosen.id
                                    store.saveData()
                                }
                            }
                            
                            // Bread & Rice Selection
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Text("3")
                                            .font(.caption2)
                                            .bold()
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        Text("Roti & Rice")
                                            .font(.subheadline)
                                            .bold()
                                    }
                                    Spacer()
                                    Text("6g protein • 160 kcal")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("Bread", selection: $store.thali.breadOrRice) {
                                    Text("2x Phulka Roti").tag("2x Whole Wheat Phulkas")
                                    Text("Steamed Basmati").tag("Steamed Basmati Rice")
                                    Text("Jeera Rice").tag("Jeera Rice")
                                    Text("Ajwain Paratha").tag("Ajwain Paratha")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: store.thali.breadOrRice) { _ in store.saveData() }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                    )
                            )
                            
                            // Accompaniment Selection
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    HStack(spacing: 6) {
                                        Text("4")
                                            .font(.caption2)
                                            .bold()
                                            .foregroundColor(.white)
                                            .frame(width: 18, height: 18)
                                            .background(Color.purple)
                                            .clipShape(Circle())
                                        Text("Dahi & Accompaniment")
                                            .font(.subheadline)
                                            .bold()
                                    }
                                    Spacer()
                                    Text("4g protein • 60 kcal")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("Side", selection: $store.thali.side) {
                                    Text("Cucumber Raita").tag("Cucumber Dahi Raita")
                                    Text("Kachumber Salad").tag("Kachumber Salad")
                                    Text("Curd & Achaar").tag("Plain Curd & Achaar")
                                    Text("Roasted Papad").tag("Roasted Papad")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: store.thali.side) { _ in store.saveData() }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // 4. Add to Sabzi Mandi Primary Button
                    Button(action: addThaliToGroceries) {
                        HStack(spacing: 8) {
                            Image(systemName: "cart.badge.plus")
                            Text(languageManager.t("thali_add_all"))
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle(languageManager.t("tab_thali"))
            .alert("Thali Ingredients Added!", isPresented: $showingAddedAlert) {
                Button("Great", role: .cancel) { }
            } message: {
                Text("All ingredients for \(selectedDal?.title ?? "Dal") and \(selectedSabzi?.title ?? "Sabzi") have been added to your Sabzi Mandi grocery list.")
            }
        }
    }
    
    private func randomizeThali() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        if let dal = selectedDal {
            store.addIngredientsToGroceries(recipe: dal)
        }
        if let sabzi = selectedSabzi {
            store.addIngredientsToGroceries(recipe: sabzi)
        }
        showingAddedAlert = true
    }
}

// MARK: - Aesthetic Components for Thali
struct AestheticMacroStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}

struct ThaliCourseCard: View {
    let courseNumber: String
    let courseType: String
    let icon: String
    let color: Color
    let recipe: Recipe
    let options: [Recipe]
    let onSelect: (Recipe) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Text(courseNumber)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white)
                        .frame(width: 18, height: 18)
                        .background(color)
                        .clipShape(Circle())
                    Text(courseType)
                        .font(.caption)
                        .bold()
                        .foregroundColor(color)
                }
                Spacer()
                Menu {
                    ForEach(options) { r in
                        Button(action: { onSelect(r) }) {
                            HStack {
                                Text(r.title)
                                if r.id == recipe.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Change")
                            .font(.caption)
                            .bold()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            HStack(spacing: 8) {
                FSSAIBadge(diet: recipe.diet, size: 12)
                Text(recipe.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                Label("\(recipe.proteinGrams)g protein", systemImage: "flame.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                Text("•")
                    .foregroundColor(.secondary)
                Label("\(recipe.calories) kcal", systemImage: "bolt.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Label("\(recipe.prepTimeMinutes)m prep", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}
