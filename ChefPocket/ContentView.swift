import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CookbookHomeView()
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

// MARK: - Vector FSSAI Badge (No Emojis)
struct FSSAIBadge: View {
    let diet: DietType
    var size: CGFloat = 13
    
    var body: some View {
        if diet != .all {
            ZStack {
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(diet == .veg ? Color.green : Color.red, lineWidth: 1.2)
                    .frame(width: size, height: size)
                
                Circle()
                    .fill(diet == .veg ? Color.green : Color.red)
                    .frame(width: size * 0.52, height: size * 0.52)
            }
        }
    }
}

// MARK: - Cookbook Home View
struct CookbookHomeView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var auth: AuthManager
    
    @State private var searchText = ""
    @State private var showingProfileSheet = false
    @State private var showingAuthModal = false
    @State private var showingImportSheet = false
    @State private var showingManualCreateSheet = false
    @State private var showingRandomizerModal = false
    @State private var randomizedRecipe: Recipe? = nil
    @State private var detectedClipboardURL: String? = nil
    @State private var showingResetAlert = false
    
    // Active scope recipes
    private var scopeRecipes: [Recipe] {
        store.selectedScope == .myKitchen ? store.myRecipes : store.curatedRecipes
    }
    
    private var vegCount: Int { scopeRecipes.filter { $0.diet == .veg }.count }
    private var nonVegCount: Int { scopeRecipes.filter { $0.diet == .nonVeg }.count }
    
    private var filteredRecipes: [Recipe] {
        scopeRecipes.filter { recipe in
            let matchesDiet = store.selectedDiet == .all || recipe.diet == store.selectedDiet
            let matchesMeal = store.selectedMealType == .all || recipe.mealTypes.contains(store.selectedMealType)
            let matchesSearch = searchText.isEmpty ||
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.ingredients.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) ||
                recipe.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            return matchesDiet && matchesMeal && matchesSearch
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Top Greeting Header
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CHEF POCKET")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .tracking(1.2)
                            
                            Text(greetingText)
                                .font(.title2)
                                .bold()
                        }
                        
                        Spacer()
                        
                        // Add Recipe Menu Button
                        Menu {
                            Button(action: { showingImportSheet = true }) {
                                Label("Import Video Link (AI)", systemImage: "sparkles")
                            }
                            Button(action: { showingManualCreateSheet = true }) {
                                Label("Create Custom Recipe", systemImage: "square.and.pencil")
                            }
                            Divider()
                            Button(role: .destructive, action: { showingResetAlert = true }) {
                                Label("Reload Inbuilt Recipes", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.orange)
                                .clipShape(Circle())
                        }
                        
                        // Profile Avatar Button
                        Button(action: {
                            if auth.isAuthenticated {
                                showingProfileSheet = true
                            } else {
                                showingAuthModal = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 34, height: 34)
                                
                                if let user = auth.currentUser {
                                    Text(String(user.name.prefix(1)).uppercased())
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // 2. Clipboard Banner (if detected)
                    if let detectedURL = detectedClipboardURL {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Recipe link in clipboard")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(detectedURL)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button("Extract") {
                                extractClipboardURL(detectedURL)
                            }
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button(action: { detectedClipboardURL = nil }) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // 3. Inbuilt vs My Kitchen Scope Toggle
                    HStack(spacing: 0) {
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { store.selectedScope = .curated } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.closed.fill")
                                    .font(.caption2)
                                Text("Curated Classics")
                                    .font(.subheadline)
                                    .fontWeight(store.selectedScope == .curated ? .bold : .medium)
                                Text("(\(store.curatedRecipes.count))")
                                    .font(.caption2)
                                    .foregroundColor(store.selectedScope == .curated ? .white.opacity(0.85) : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(store.selectedScope == .curated ? Color.orange : Color.clear)
                            .foregroundColor(store.selectedScope == .curated ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { store.selectedScope = .myKitchen } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "fork.knife")
                                    .font(.caption2)
                                Text("My Kitchen")
                                    .font(.subheadline)
                                    .fontWeight(store.selectedScope == .myKitchen ? .bold : .medium)
                                Text("(\(store.myRecipes.count))")
                                    .font(.caption2)
                                    .foregroundColor(store.selectedScope == .myKitchen ? .white.opacity(0.85) : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(store.selectedScope == .myKitchen ? Color.orange : Color.clear)
                            .foregroundColor(store.selectedScope == .myKitchen ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(3)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                    // 4. Diet Pill Selector (All | Veg | Non-Veg) - Never Truncated
                    HStack(spacing: 8) {
                        DietPillButton(
                            title: "All",
                            count: scopeRecipes.count,
                            isSelected: store.selectedDiet == .all,
                            dotColor: nil
                        ) {
                            withAnimation { store.selectedDiet = .all }
                        }
                        
                        DietPillButton(
                            title: "Veg",
                            count: vegCount,
                            isSelected: store.selectedDiet == .veg,
                            dotColor: .green
                        ) {
                            withAnimation { store.selectedDiet = .veg }
                        }
                        
                        DietPillButton(
                            title: "Non-Veg",
                            count: nonVegCount,
                            isSelected: store.selectedDiet == .nonVeg,
                            dotColor: .red
                        ) {
                            withAnimation { store.selectedDiet = .nonVeg }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 5. Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search dishes, paneer, chicken, dal...", text: $searchText)
                            .font(.subheadline)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // 6. Meal Occasions Bar (Breakfast, Lunch, Snacks, Dinner)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MealType.allCases) { meal in
                                Button(action: {
                                    withAnimation { store.selectedMealType = meal }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: meal.sfSymbol)
                                            .font(.caption2)
                                        Text(meal.rawValue)
                                            .font(.caption)
                                            .fontWeight(store.selectedMealType == meal ? .bold : .medium)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(store.selectedMealType == meal ? Color.primary : Color(.systemGray6))
                                    .foregroundColor(store.selectedMealType == meal ? Color(.systemBackground) : .primary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 7. Subtle "Aaj Kya Banau?" Prompt Card
                    Button(action: spinAajKyaBanau) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Aaj Kya Banau?")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.primary)
                                    FSSAIBadge(diet: store.selectedDiet, size: 10)
                                }
                                Text("Can't decide? Tap for an instant meal suggestion.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray5), lineWidth: 1))
                        .padding(.horizontal)
                    }
                    
                    // 8. Recipe List / Empty State
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(store.selectedDiet.label) • \(store.selectedMealType.rawValue)")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                            Text("\(filteredRecipes.count) dishes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if filteredRecipes.isEmpty {
                            if store.selectedScope == .myKitchen && store.myRecipes.isEmpty {
                                // My Kitchen Empty State
                                VStack(spacing: 14) {
                                    Image(systemName: "fork.knife.circle")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    VStack(spacing: 4) {
                                        Text("Your Kitchen is Empty")
                                            .font(.headline)
                                        Text("Import recipe videos from YouTube Shorts or create secret family recipes using the + button.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }
                                    
                                    Button(action: { showingImportSheet = true }) {
                                        Label("Import Video Recipe", systemImage: "sparkles")
                                            .font(.caption)
                                            .bold()
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .background(Color.orange)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    Text("No dishes match current filters")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                        AestheticRecipeCard(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 32)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfileSheet) {
                UserProfileSheet()
            }
            .sheet(isPresented: $showingAuthModal) {
                AuthModalView()
            }
            .sheet(isPresented: $showingImportSheet) {
                AIImportModal(isPresented: $showingImportSheet)
            }
            .sheet(isPresented: $showingManualCreateSheet) {
                ManualRecipeModal(isPresented: $showingManualCreateSheet)
            }
            .sheet(isPresented: $showingRandomizerModal) {
                if let r = randomizedRecipe {
                    AajKyaBanauResultSheet(recipe: r, isPresented: $showingRandomizerModal)
                }
            }
            .alert("Reload All 125 Inbuilt Recipes?", isPresented: $showingResetAlert) {
                Button("Reload", role: .destructive) {
                    store.resetToInbuiltRecipes()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will refresh all 125 curated recipes without affecting your custom recipes in My Kitchen.")
            }
            .onAppear {
                checkClipboard()
            }
        }
    }
    
    private var greetingText: String {
        if let name = auth.currentUser?.name, !name.isEmpty {
            return "Hello, \(name)"
        }
        return "Chef's Kitchen"
    }
    
    private func checkClipboard() {
        if let clip = UIPasteboard.general.string,
           (clip.contains("youtube.com") || clip.contains("youtu.be") || clip.contains("instagram.com")) {
            detectedClipboardURL = clip
        }
    }
    
    private func extractClipboardURL(_ urlString: String) {
        Task {
            let apiKey = auth.currentUser?.geminiApiKey
            if let recipe = try? await AIService.shared.extractRecipe(from: urlString, userApiKey: apiKey) {
                await MainActor.run {
                    store.addRecipe(recipe)
                    detectedClipboardURL = nil
                    store.selectedScope = .myKitchen
                }
            }
        }
    }
    
    private func spinAajKyaBanau() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let pick = store.getRandomRecipe(
            scope: store.selectedScope,
            diet: store.selectedDiet,
            meal: store.selectedMealType
        ) {
            randomizedRecipe = pick
            showingRandomizerModal = true
        }
    }
}

// MARK: - Diet Pill Button (No Truncation)
struct DietPillButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let dotColor: Color?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dotColor = dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 6, height: 6)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.orange : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aesthetic Recipe Card
struct AestheticRecipeCard: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: FSSAI mark, title, favorite
            HStack(alignment: .top, spacing: 8) {
                FSSAIBadge(diet: recipe.diet, size: 12)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Tags / Meal Types
                    Text(recipe.tags.prefix(2).joined(separator: " • "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        store.toggleFavorite(recipeId: recipe.id)
                    }
                }) {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(recipe.isFavorite ? .red : Color(.systemGray3))
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            
            // Badges row: Prep time, Whistles, Calories, Protein
            HStack(spacing: 8) {
                Label("\(recipe.prepTimeMinutes)m", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let whistles = recipe.whistleCount {
                    Label("\(whistles) whistles", systemImage: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(recipe.calories) kcal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(recipe.proteinGrams)g protein")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.systemGray5), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - AI Import Modal
struct AIImportModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var auth: AuthManager
    
    @State private var urlInput = ""
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("AI Video Recipe Extractor")
                        .font(.title2)
                        .bold()
                    
                    Text("Paste a YouTube Shorts or Instagram Reels link. Google Gemini AI will extract authentic ingredients, whistle counts, and steps.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("https://youtube.com/shorts/...", text: $urlInput)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Label("\(AIService.shared.remainingDailyRequests) free AI extractions left today", systemImage: "bolt.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                if AIService.shared.isExtracting {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text(AIService.shared.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Button(action: runAIExtraction) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(AIService.shared.isExtracting ? "Extracting..." : "Extract & Cook")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || AIService.shared.isExtracting)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
    
    private func runAIExtraction() {
        let clean = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        errorMessage = nil
        
        Task {
            do {
                let apiKey = auth.currentUser?.geminiApiKey
                let recipe = try await AIService.shared.extractRecipe(from: clean, userApiKey: apiKey)
                await MainActor.run {
                    store.addRecipe(recipe)
                    store.selectedScope = .myKitchen
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Extraction failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @State private var showingAddedGroceryAlert = false
    
    private var cleanInstructions: [String] {
        let filtered = recipe.instructions.filter { step in
            let lower = step.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return !lower.starts(with: "extracted from") &&
                   !lower.starts(with: "source:") &&
                   !lower.contains("youtube.com") &&
                   !lower.contains("youtu.be") &&
                   !lower.contains("instagram.com")
        }
        return filtered.isEmpty ? ["Prepare ingredients, cook with spices, and serve hot."] : filtered
    }
    
    private var formattedShareText: String {
        var text = """
🍳 \(recipe.title)
Diet: \(recipe.diet.label)
Prep Time: \(recipe.prepTimeMinutes) mins | Calories: \(recipe.calories) kcal | Protein: \(recipe.proteinGrams)g
"""
        if let whistles = recipe.whistleCount {
            text += " | Cooker: \(whistles) whistles\n\n"
        } else {
            text += "\n\n"
        }
        
        text += "🛒 INGREDIENTS:\n"
        for ing in recipe.ingredients {
            text += "• \(ing.name) - \(String(format: "%.1f", ing.amount)) \(ing.unit)\n"
        }
        
        text += "\n👨‍🍳 INSTRUCTIONS:\n"
        for (i, step) in cleanInstructions.enumerated() {
            text += "\(i + 1). \(step)\n"
        }
        
        if let url = recipe.sourceURL, !url.isEmpty {
            text += "\nOriginal Video: \(url)\n"
        }
        
        text += "\nShared from ChefPocket App 👨‍🍳"
        return text
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header details
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        FSSAIBadge(diet: recipe.diet, size: 14)
                        Text(recipe.diet.label)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(recipe.diet.accentColor)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(recipe.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if recipe.isUserCreated {
                            Text("My Kitchen")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(recipe.title)
                        .font(.title2)
                        .bold()
                }
                .padding(.horizontal)
                
                // Macro bar
                HStack(spacing: 12) {
                    MacroBox(title: "Time", value: "\(recipe.prepTimeMinutes) min", icon: "clock")
                    MacroBox(title: "Calories", value: "\(recipe.calories) kcal", icon: "flame")
                    MacroBox(title: "Protein", value: "\(recipe.proteinGrams)g", icon: "bolt.fill")
                    if let whistles = recipe.whistleCount {
                        MacroBox(title: "Cooker", value: "\(whistles) whistles", icon: "bell.fill")
                    }
                }
                .padding(.horizontal)
                
                // Dedicated Video Link Card (Moved from instructions)
                if let sourceURL = recipe.sourceURL, !sourceURL.isEmpty, let url = URL(string: sourceURL) {
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.12))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "play.rectangle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sourceURL.contains("instagram") ? "Watch on Instagram Reels" : "Watch Original Recipe Video")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(sourceURL)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Ingredients Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Ingredients")
                            .font(.headline)
                        Spacer()
                        Button(action: addAllToGroceries) {
                            HStack(spacing: 4) {
                                Image(systemName: "cart.badge.plus")
                                Text("Add All to List")
                            }
                            .font(.caption)
                            .bold()
                            .foregroundColor(.orange)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(recipe.ingredients) { ing in
                            HStack {
                                Text(ing.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(String(format: "%.1f", ing.amount)) \(ing.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                // Instructions Section (Pure culinary steps)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cooking Instructions")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(cleanInstructions.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(idx + 1)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                
                                Text(step)
                                    .font(.subheadline)
                                    .lineSpacing(3)
                            }
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                // Social Media Share Button
                ShareLink(
                    item: formattedShareText,
                    subject: Text(recipe.title),
                    message: Text("Check out this recipe for \(recipe.title) on ChefPocket!")
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Recipe via WhatsApp, Instagram & More")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    ShareLink(
                        item: formattedShareText,
                        subject: Text(recipe.title),
                        message: Text("Check out this recipe for \(recipe.title) on ChefPocket!")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        store.toggleFavorite(recipeId: recipe.id)
                    }) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Ingredients Added", isPresented: $showingAddedGroceryAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ingredients for \(recipe.title) have been organized into your Sabzi Mandi grocery list.")
        }
    }
    
    private func addAllToGroceries() {
        store.addIngredientsToGroceries(recipe: recipe)
        showingAddedGroceryAlert = true
    }
}

struct MacroBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

// MARK: - Aaj Kya Banau Result Sheet
struct AajKyaBanauResultSheet: View {
    let recipe: Recipe
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Today's Recommendation")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        FSSAIBadge(diet: recipe.diet, size: 14)
                        Text(recipe.title)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 24)
                
                HStack(spacing: 12) {
                    MacroBox(title: "Time", value: "\(recipe.prepTimeMinutes)m", icon: "clock")
                    MacroBox(title: "Calories", value: "\(recipe.calories) kcal", icon: "flame")
                    MacroBox(title: "Protein", value: "\(recipe.proteinGrams)g", icon: "bolt.fill")
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Ingredients")
                        .font(.subheadline)
                        .bold()
                    
                    ForEach(recipe.ingredients.prefix(4)) { ing in
                        HStack {
                            Text("• \(ing.name)")
                                .font(.caption)
                            Spacer()
                            Text("\(String(format: "%.1f", ing.amount)) \(ing.unit)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    Text("Cook This Dish")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
}
