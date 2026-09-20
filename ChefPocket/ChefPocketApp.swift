import SwiftUI

@main
struct ChefPocketApp: App {
    @StateObject private var store = RecipeStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onOpenURL { incomingURL in
                    // Handles deep links from the Share Extension: chefpocket://import?url=...
                    handleIncomingURL(incomingURL)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "chefpocket",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItem = components.queryItems?.first(where: { $0.name == "url" }),
              let sharedVideoURL = queryItem.value else { return }
        
        store.addFromURL(sharedVideoURL)
    }
}