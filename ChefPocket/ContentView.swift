import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecipeBookView()
                .tabItem {
                    Label("Cookbook", systemImage: "book.closed.fill")
                }
                .tag(0)
            
            ThaliPlannerView()
                .tabItem {
                    Label("Thali", systemImage: "circle.grid.cross.fill")
                }
                .tag(1)
            
            GroceryListView()
                .tabItem {
                    Label("Sabzi Mandi", systemImage: "basket.fill")
                }
                .tag(2)
            
            CookModeView()
                .tabItem {
                    Label("Cook Mode", systemImage: "timer")
                }
                .tag(3)
        }
        .tint(.orange)
    }
}

struct RecipeBookView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var searchText = ""
    @State private var selectedCategory: RecipeCategory = .all
    @State private var showingImportSheet = false
    @State private var showingManualCreateSheet = false
    @State private var showingRandomizerModal = false
    @State private var randomizedRecipe: Recipe? = nil
    @State private var detectedClipboardURL: String? = nil
    
    private var filteredRecipes: [Recipe] {
        store.recipes.filter { recipe in
            let matchesCategory = selectedCategory == .all || recipe.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.ingredients.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) ||
                recipe.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Clipboard Detection Banner
                if let detectedURL = detectedClipboardURL {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Link Found in Clipboard")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(detectedURL)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button("Import") {
                                withAnimation {
                                    store.addFromURL(detectedURL)
                                    detectedClipboardURL = nil
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .font(.caption)
                            .bold()
                            
                            Button(action: {
                                withAnimation { detectedClipboardURL = nil }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Aaj Kya Banau? Hero Banner
                Section {
                    Button(action: spinAajKyaBanau) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "dice.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Aaj Kya Banau? 🎲")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Can't decide? Tap for instant meal inspiration!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Category Pills
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(RecipeCategory.allCases) { cat in
                                Button(action: {
                                    withAnimation { selectedCategory = cat }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.iconName)
                                            .font(.caption2)
                                        Text(cat.rawValue)
                                            .font(.caption)
                                            .bold()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? Color.orange : Color(.systemGray6))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .cornerRadius(20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
                }
                
                // Recipe List
                Section(header: Text("\(selectedCategory.rawValue) Recipes (\(filteredRecipes.count))")) {
                    if filteredRecipes.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("No matching recipes found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                EnhancedRecipeRow(recipe: recipe)
                            }
                        }
                        .onDelete(perform: store.deleteRecipe)
                    }
                }
            }
            .navigationTitle("ChefPocket")
            .searchable(text: $searchText, prompt: "Search dishes or fridge ingredients (paneer, dal...)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingImportSheet = true }) {
                            Label("Import from Video Link", systemImage: "link.badge.plus")
                        }
                        Button(action: { showingManualCreateSheet = true }) {
                            Label("Create Custom Recipe", systemImage: "square.and.pencil")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportRecipeModal(isPresented: $showingImportSheet)
            }
            .sheet(isPresented: $showingManualCreateSheet) {
                ManualRecipeModal(isPresented: $showingManualCreateSheet)
            }
            .sheet(isPresented: $showingRandomizerModal) {
                if let r = randomizedRecipe {
                    AajKyaBanauResultSheet(recipe: r, isPresented: $showingRandomizerModal)
                }
            }
            .onAppear {
                checkClipboard()
            }
        }
    }
    
    private func spinAajKyaBanau() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        if let pick = store.recipes.randomElement() {
            randomizedRecipe = pick
            showingRandomizerModal = true
        }
    }
    
    private func checkClipboard() {
        if let string = UIPasteboard.general.string {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if (trimmed.contains("youtube.com") || trimmed.contains("youtu.be") || trimmed.contains("instagram.com")) &&
                !store.recipes.contains(where: { $0.sourceURL == trimmed }) {
                detectedClipboardURL = trimmed
            }
        }
    }
}

struct EnhancedRecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 12) {
                Label("\(recipe.proteinGrams)g Protein", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .bold()
                
                Label("\(recipe.calories) kcal", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Label("\(recipe.prepTimeMinutes)m", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let whistles = recipe.whistleCount {
                    Label("\(whistles) 💨", systemImage: "bell.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @State private var multiplier: Double = 1.0
    @State private var showingAddedAlert = false
    
    private var liveRecipe: Recipe {
        store.recipes.first(where: { $0.id == recipe.id }) ?? recipe
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Macro Card
                HStack(spacing: 12) {
                    MacroPill(label: "Protein", val: "\(Int(Double(liveRecipe.proteinGrams) * multiplier))g", color: .orange)
                    MacroPill(label: "Calories", val: "\(Int(Double(liveRecipe.calories) * multiplier)) kcal", color: .green)
                    MacroPill(label: "Time", val: "\(liveRecipe.prepTimeMinutes)m", color: .blue)
                    if let whistles = liveRecipe.whistleCount {
                        MacroPill(label: "Whistles", val: "\(whistles) 💨", color: .purple)
                    }
                }
                .padding(.horizontal)
                
                // Serving Scaler
                VStack(alignment: .leading, spacing: 6) {
                    Text("Servings: \(Int(multiplier))x")
                        .font(.subheadline)
                        .bold()
                    Picker("Scale", selection: $multiplier) {
                        Text("1x").tag(1.0)
                        Text("2x").tag(2.0)
                        Text("4x").tag(4.0)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                // Action Buttons: Add to Groceries & Cook Mode
                HStack(spacing: 12) {
                    Button(action: {
                        store.addIngredientsToGroceries(recipe: liveRecipe)
                        showingAddedAlert = true
                    }) {
                        Label("Add to Groceries", systemImage: "cart.badge.plus")
                            .font(.subheadline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: CookModeView()) {
                        Label("Cook Mode ⏱️", systemImage: "timer")
                            .font(.subheadline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Ingredients Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Ingredients")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("Tap to check off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(liveRecipe.ingredients) { ing in
                        Button(action: {
                            store.toggleIngredient(recipeId: liveRecipe.id, ingredientId: ing.id)
                        }) {
                            HStack {
                                Image(systemName: ing.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(ing.isChecked ? .orange : .secondary)
                                    .font(.title3)
                                
                                Text(ing.name)
                                    .strikethrough(ing.isChecked)
                                    .foregroundColor(ing.isChecked ? .secondary : .primary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", ing.amount * multiplier)) \(ing.unit)")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .padding(.horizontal)
                
                // Instructions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Step-by-Step Instructions")
                        .font(.title2)
                        .bold()
                    
                    ForEach(Array(liveRecipe.instructions.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.orange))
                            
                            Text(step)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                
                // Video Source Link
                if let sourceURL = liveRecipe.sourceURL, let url = URL(string: sourceURL) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("Watch Original Video Recipe")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .foregroundColor(.orange)
                        .font(.headline)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(liveRecipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { store.toggleFavorite(recipeId: liveRecipe.id) }) {
                    Image(systemName: liveRecipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Ingredients Added!", isPresented: $showingAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ingredients for \(liveRecipe.title) have been categorized and placed into your Sabzi Mandi list.")
        }
    }
}

struct AajKyaBanauResultSheet: View {
    let recipe: Recipe
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)
                
                Text("Tonight's Recommendation:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(recipe.title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Label("\(recipe.proteinGrams)g Protein", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                    Label("\(recipe.prepTimeMinutes) mins", systemImage: "clock")
                        .foregroundColor(.blue)
                    Label("\(recipe.calories) kcal", systemImage: "bolt.fill")
                        .foregroundColor(.green)
                }
                .font(.subheadline)
                .bold()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Ingredients:")
                        .font(.headline)
                    ForEach(recipe.ingredients.prefix(4)) { ing in
                        Text("• \(ing.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                Spacer()
                
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    Text("View Full Recipe")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
}

struct MacroPill: View {
    let label: String
    let val: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(val)
                .font(.headline)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
}

struct ImportRecipeModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: RecipeStore
    @State private var inputURL = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Paste Video Link")) {
                    TextField("https://youtube.com/shorts/... or Instagram Reels", text: $inputURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                
                Section {
                    Button(action: {
                        if !inputURL.isEmpty {
                            store.addFromURL(inputURL)
                            isPresented = false
                        }
                    }) {
                        Text("Extract Recipe")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                            .foregroundColor(inputURL.isEmpty ? .secondary : .orange)
                    }
                    .disabled(inputURL.isEmpty)
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
