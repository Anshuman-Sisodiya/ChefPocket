import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var auth: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CookbookHomeView()
                .tabItem {
                    Label(LanguageManager.shared.t("tab_cookbook"), systemImage: "book.closed.fill")
                }
                .tag(0)
            
            ThaliPlannerView()
                .tabItem {
                    Label(LanguageManager.shared.t("tab_thali"), systemImage: "circle.grid.cross.fill")
                }
                .tag(1)
            
            GroceryListView()
                .tabItem {
                    Label(LanguageManager.shared.t("tab_groceries"), systemImage: "basket.fill")
                }
                .tag(2)
            
            CookModeView()
                .tabItem {
                    Label(LanguageManager.shared.t("tab_cookmode"), systemImage: "timer")
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
    @ObservedObject var languageManager = LanguageManager.shared
    
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
        switch store.selectedScope {
        case .myKitchen:
            return store.myRecipes
        case .favorites:
            return store.favoriteRecipes
        default:
            return store.curatedRecipes
        }
    }
    
    private var vegCount: Int { scopeRecipes.filter { $0.diet == .veg }.count }
    private var nonVegCount: Int { scopeRecipes.filter { $0.diet == .nonVeg }.count }
    
    private var sectionHeaderTitle: String {
        var parts: [String] = [store.selectedDiet.label]
        if store.selectedCuisine != .all {
            parts.append(store.selectedCuisine.rawValue)
        }
        if store.selectedCategory != .all {
            parts.append(store.selectedCategory.rawValue)
        } else if store.selectedMealType != .all {
            parts.append(store.selectedMealType.rawValue)
        }
        return parts.joined(separator: " • ")
    }
    
    private var filteredRecipes: [Recipe] {
        scopeRecipes.filter { recipe in
            let matchesCuisine = store.selectedCuisine == .all || recipe.cuisine == store.selectedCuisine
            let matchesDiet = store.selectedDiet == .all || recipe.diet == store.selectedDiet
            let matchesMeal = store.selectedMealType == .all || recipe.mealTypes.contains(store.selectedMealType)
            let matchesCategory = store.selectedCategory == .all || recipe.category == store.selectedCategory
            let matchesSearch = searchText.isEmpty ||
                recipe.title.localizedCaseInsensitiveContains(searchText) ||
                recipe.ingredients.contains(where: { $0.name.localizedCaseInsensitiveContains(searchText) }) ||
                recipe.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) }) ||
                recipe.cuisine.rawValue.localizedCaseInsensitiveContains(searchText)
            return matchesCuisine && matchesDiet && matchesMeal && matchesCategory && matchesSearch
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
                        
                        // Quick Favorites Button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.selectedScope = (store.selectedScope == .favorites) ? .curated : .favorites
                            }
                        }) {
                            Image(systemName: store.selectedScope == .favorites ? "heart.fill" : "heart")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(store.selectedScope == .favorites ? .red : .secondary)
                                .padding(8)
                                .background(store.selectedScope == .favorites ? Color.red.opacity(0.15) : Color(.systemGray5))
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
                    
                    // 3. Three-way Scope Selector: Curated | My Kitchen | Favorites
                    HStack(spacing: 0) {
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { store.selectedScope = .curated } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "book.closed.fill")
                                    .font(.caption2)
                                Text("Curated")
                                    .font(.caption)
                                    .fontWeight(store.selectedScope == .curated ? .bold : .medium)
                                Text("(\(store.curatedRecipes.count))")
                                    .font(.caption2)
                                    .foregroundColor(store.selectedScope == .curated ? .white.opacity(0.85) : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(store.selectedScope == .curated ? Color.orange : Color.clear)
                            .foregroundColor(store.selectedScope == .curated ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { store.selectedScope = .myKitchen } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "fork.knife")
                                    .font(.caption2)
                                Text("Kitchen")
                                    .font(.caption)
                                    .fontWeight(store.selectedScope == .myKitchen ? .bold : .medium)
                                Text("(\(store.myRecipes.count))")
                                    .font(.caption2)
                                    .foregroundColor(store.selectedScope == .myKitchen ? .white.opacity(0.85) : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(store.selectedScope == .myKitchen ? Color.orange : Color.clear)
                            .foregroundColor(store.selectedScope == .myKitchen ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { store.selectedScope = .favorites } }) {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundColor(store.selectedScope == .favorites ? .white : .red)
                                Text("Favorites")
                                    .font(.caption)
                                    .fontWeight(store.selectedScope == .favorites ? .bold : .medium)
                                Text("(\(store.favoriteRecipes.count))")
                                    .font(.caption2)
                                    .foregroundColor(store.selectedScope == .favorites ? .white.opacity(0.85) : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(store.selectedScope == .favorites ? Color.orange : Color.clear)
                            .foregroundColor(store.selectedScope == .favorites ? .white : .primary)
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
                            title: languageManager.t("diet_all"),
                            count: scopeRecipes.count,
                            isSelected: store.selectedDiet == .all,
                            dotColor: nil
                        ) {
                            withAnimation { store.selectedDiet = .all }
                        }
                        
                        DietPillButton(
                            title: languageManager.t("diet_veg"),
                            count: vegCount,
                            isSelected: store.selectedDiet == .veg,
                            dotColor: .green
                        ) {
                            withAnimation { store.selectedDiet = .veg }
                        }
                        
                        DietPillButton(
                            title: languageManager.t("diet_non_veg"),
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
                        TextField(languageManager.t("search_placeholder"), text: $searchText)
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
                    
                    // 6. Compact Dropdown Filter Bar (Cuisine, Meal, Category, Reset)
                    HStack(spacing: 8) {
                        // Cuisine Dropdown Menu
                        Menu {
                            ForEach(Cuisine.allCases) { cuisine in
                                Button(action: {
                                    withAnimation { store.selectedCuisine = cuisine }
                                }) {
                                    HStack {
                                        Image(systemName: cuisine.iconName)
                                        Text(cuisine.rawValue)
                                        if store.selectedCuisine == cuisine {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: store.selectedCuisine == .all ? "globe" : store.selectedCuisine.iconName)
                                    .font(.caption2)
                                Text(store.selectedCuisine == .all ? languageManager.t("filter_cuisine") : store.selectedCuisine.rawValue)
                                    .font(.caption)
                                    .fontWeight(store.selectedCuisine != .all ? .bold : .medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(store.selectedCuisine != .all ? Color.orange : Color(.systemGray6))
                            .foregroundColor(store.selectedCuisine != .all ? .white : .primary)
                            .clipShape(Capsule())
                        }

                        // Meal Occasion Dropdown Menu
                        Menu {
                            ForEach(MealType.allCases) { meal in
                                Button(action: {
                                    withAnimation { store.selectedMealType = meal }
                                }) {
                                    HStack {
                                        Image(systemName: meal.sfSymbol)
                                        Text(meal.rawValue)
                                        if store.selectedMealType == meal {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: store.selectedMealType.sfSymbol)
                                    .font(.caption2)
                                Text(store.selectedMealType == .all ? languageManager.t("filter_meal") : store.selectedMealType.rawValue)
                                    .font(.caption)
                                    .fontWeight(store.selectedMealType != .all ? .bold : .medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(store.selectedMealType != .all ? Color.primary : Color(.systemGray6))
                            .foregroundColor(store.selectedMealType != .all ? Color(.systemBackground) : .primary)
                            .clipShape(Capsule())
                        }

                        // Culinary Category Dropdown Menu
                        Menu {
                            ForEach(RecipeCategory.allCases) { cat in
                                Button(action: {
                                    withAnimation { store.selectedCategory = cat }
                                }) {
                                    HStack {
                                        Image(systemName: cat.iconName)
                                        Text(cat.rawValue)
                                        if store.selectedCategory == cat {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: store.selectedCategory == .all ? "sparkles" : store.selectedCategory.iconName)
                                    .font(.caption2)
                                Text(store.selectedCategory == .all ? languageManager.t("filter_category") : store.selectedCategory.rawValue)
                                    .font(.caption)
                                    .fontWeight(store.selectedCategory != .all ? .bold : .medium)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(store.selectedCategory != .all ? Color.orange : Color(.systemGray6))
                            .foregroundColor(store.selectedCategory != .all ? .white : .primary)
                            .clipShape(Capsule())
                        }

                        // Quick Reset Button
                        if store.selectedCuisine != .all || store.selectedMealType != .all || store.selectedCategory != .all {
                            Button(action: {
                                withAnimation {
                                    store.selectedCuisine = .all
                                    store.selectedMealType = .all
                                    store.selectedCategory = .all
                                }
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                    Text(languageManager.t("filter_reset"))
                                        .font(.caption2)
                                        .bold()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .clipShape(Capsule())
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal)

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
                            Text(sectionHeaderTitle)
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Spacer()
                            Text("\(filteredRecipes.count) \(filteredRecipes.count == 1 ? "dish" : "dishes")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if filteredRecipes.isEmpty {
                            if store.selectedScope == .favorites && store.favoriteRecipes.isEmpty {
                                // Favorites Empty State
                                VStack(spacing: 14) {
                                    Image(systemName: "heart.slash")
                                        .font(.system(size: 48))
                                        .foregroundColor(.red.opacity(0.7))
                                    
                                    VStack(spacing: 4) {
                                        Text("No Favorites Saved Yet")
                                            .font(.headline)
                                        Text("Tap the heart ❤️ on any dish to save it to your personal favorites collection.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            store.selectedScope = .curated
                                        }
                                    }) {
                                        Label("Browse Curated Dishes", systemImage: "sparkles")
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
                            } else if store.selectedScope == .myKitchen && store.myRecipes.isEmpty {
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
                UserProfileView()
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
            .alert("Reload All 430+ Inbuilt Recipes?", isPresented: $showingResetAlert) {
                Button("Reload", role: .destructive) {
                    store.resetToInbuiltRecipes()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will refresh all 430+ curated recipes without affecting your custom recipes in My Kitchen.")
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
            if store.findRecipe(matchingURL: clip) == nil {
                detectedClipboardURL = clip
            }
        }
    }
    
    private func extractClipboardURL(_ urlString: String) {
        Task {
            let apiKey = auth.currentUser?.geminiApiKey ?? AIService.shared.effectiveApiKey
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
            cuisine: store.selectedCuisine,
            diet: store.selectedDiet,
            meal: store.selectedMealType,
            category: store.selectedCategory
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
                    
                    // Cuisine Chip & Tags
                    HStack(spacing: 6) {
                        Text(recipe.cuisine.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                        
                        Text(recipe.tags.prefix(2).joined(separator: " • "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
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
    @ObservedObject var languageManager = LanguageManager.shared
    
    @State private var urlInput = ""
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var showingAlreadyExistsAlert = false
    @State private var existingRecipeTitle = ""
    @State private var showingApiKeyEditor = false
    @State private var inlineApiKey = ""
    @State private var apiKeySavedBanner = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 38))
                            .foregroundColor(.orange)
                        
                        Text("AI Video Recipe Extractor")
                            .font(.title2)
                            .bold()
                        
                        Text("Paste a YouTube Shorts or Instagram Reels link. Google Gemini AI will extract authentic ingredients, whistle counts, and cooking steps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // URL Input Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Video Link")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextField("https://youtube.com/shorts/...", text: $urlInput)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        if let err = errorMessage {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text(err)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Gemini API Key Inline Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(
                                AIService.shared.hasValidApiKey ? "Gemini API Key Active" : "Gemini API Key Setup",
                                systemImage: AIService.shared.hasValidApiKey ? "checkmark.seal.fill" : "key.fill"
                            )
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AIService.shared.hasValidApiKey ? .green : .orange)
                            
                            Spacer()
                            
                            Button(showingApiKeyEditor ? "Done" : (AIService.shared.hasValidApiKey ? "Change" : "Add Key")) {
                                withAnimation {
                                    showingApiKeyEditor.toggle()
                                }
                            }
                            .font(.caption)
                            .bold()
                            .foregroundColor(.orange)
                        }
                        
                        if showingApiKeyEditor {
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Paste Google AI Studio API Key", text: $inlineApiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                
                                HStack {
                                    Button("Save Key") {
                                        let clean = inlineApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !clean.isEmpty {
                                            AIService.shared.setApiKey(clean)
                                            if auth.isAuthenticated {
                                                auth.updateProfile(name: auth.currentUser?.name ?? "Chef", diet: auth.currentUser?.dietaryPreference ?? .all, apiKey: clean)
                                            }
                                            withAnimation {
                                                apiKeySavedBanner = true
                                                showingApiKeyEditor = false
                                                errorMessage = nil
                                            }
                                        }
                                    }
                                    .font(.caption)
                                    .bold()
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .disabled(inlineApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    
                                    Link("Get Free Key ↗", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        } else if apiKeySavedBanner {
                            Text("✓ API Key successfully saved and active for unlimited precise extractions.")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else if !AIService.shared.hasValidApiKey {
                            Text("Add your free Gemini API key from Google AI Studio to unlock automatic recipe parsing.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Extraction Progress indicator
                    if AIService.shared.isExtracting {
                        VStack(spacing: 8) {
                            ProgressView()
                            Text(AIService.shared.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Action button
                    Button(action: runAIExtraction) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(AIService.shared.isExtracting ? "Extracting Recipe..." : "Extract & Add to Kitchen")
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
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .onAppear {
                inlineApiKey = AIService.shared.effectiveApiKey
                if inlineApiKey.isEmpty, let userKey = auth.currentUser?.geminiApiKey, !userKey.isEmpty {
                    inlineApiKey = userKey
                }
            }
            .alert(languageManager.t("already_in_kitchen"), isPresented: $showingAlreadyExistsAlert) {
                Button("OK", role: .cancel) {
                    store.selectedScope = .myKitchen
                    isPresented = false
                }
            } message: {
                Text("\(languageManager.t("already_in_kitchen_msg")) '\(existingRecipeTitle)'.")
            }
        }
    }
    
    private func runAIExtraction() {
        let clean = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        errorMessage = nil
        
        // Prevent adding duplicate recipe
        if let existing = store.findRecipe(matchingURL: clean) {
            existingRecipeTitle = existing.title
            showingAlreadyExistsAlert = true
            return
        }
        
        Task {
            do {
                let apiKey = auth.currentUser?.geminiApiKey.isEmpty == false ? auth.currentUser?.geminiApiKey : AIService.shared.effectiveApiKey
                let recipe = try await AIService.shared.extractRecipe(from: clean, userApiKey: apiKey)
                await MainActor.run {
                    _ = store.addRecipe(recipe)
                    store.selectedScope = .myKitchen
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Recipe Detail View
struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingAddedGroceryAlert = false
    @State private var showingDeleteConfirm = false
    
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
                        
                        Text(recipe.cuisine.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
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
                        Text(languageManager.t("share_recipe"))
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

                // Delete Custom Recipe Button
                if recipe.isUserCreated {
                    Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                            Text(languageManager.t("delete_recipe"))
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if recipe.isUserCreated {
                        Button(role: .destructive, action: { showingDeleteConfirm = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    
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
        .confirmationDialog(languageManager.t("confirm_delete_title"), isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button(languageManager.t("delete"), role: .destructive) {
                store.deleteRecipe(id: recipe.id)
                dismiss()
            }
            Button(languageManager.t("cancel"), role: .cancel) { }
        } message: {
            Text(languageManager.t("confirm_delete_msg"))
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
