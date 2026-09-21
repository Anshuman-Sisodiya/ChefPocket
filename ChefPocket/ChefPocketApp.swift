import SwiftUI

@main
struct ChefPocketApp: App {
    @StateObject private var store = RecipeStore()
    @StateObject private var auth = AuthManager()
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    // Sync app icon with active dark/light mode
                    let isDark = UITraitCollection.current.userInterfaceStyle == .dark
                    themeManager.syncAppIcon(systemIsDark: isDark)
                }
                .onOpenURL { incomingURL in
                    handleIncomingURL(incomingURL)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "chefpocket",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItem = components.queryItems?.first(where: { $0.name == "url" }),
              let sharedVideoURL = queryItem.value else { return }
        
        // Deduplication check
        if let existing = store.findRecipe(matchingURL: sharedVideoURL) {
            print("Recipe already exists: \(existing.title)")
            return
        }
        
        Task {
            let apiKey = auth.currentUser?.geminiApiKey ?? AIService.shared.effectiveApiKey
            if let recipe = try? await AIService.shared.extractRecipe(from: sharedVideoURL, userApiKey: apiKey) {
                await MainActor.run {
                    store.addRecipe(recipe)
                }
            }
        }
    }
}
