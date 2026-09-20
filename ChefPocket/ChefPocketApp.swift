import SwiftUI

@main
struct ChefPocketApp: App {
    @StateObject private var store = RecipeStore()
    @StateObject private var auth = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(auth)
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
        
        Task {
            let apiKey = auth.currentUser?.geminiApiKey
            if let recipe = try? await AIService.shared.extractRecipe(from: sharedVideoURL, userApiKey: apiKey) {
                await MainActor.run {
                    store.addRecipe(recipe)
                }
            }
        }
    }
}
