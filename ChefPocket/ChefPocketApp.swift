import SwiftUI

@main
struct ChefPocketApp: App {
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.scenePhase) private var scenePhase
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
                .onChange(of: systemColorScheme) { scheme in
                    themeManager.syncAppIcon(systemIsDark: scheme == .dark)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active { themeManager.syncAppIcon(systemIsDark: systemColorScheme == .dark) }
                }
                .onChange(of: themeManager.appTheme) { _ in
                    themeManager.syncAppIcon(systemIsDark: systemColorScheme == .dark)
                }
                .onAppear {
                    // Sync app icon with active dark/light mode
                    let isDark = UITraitCollection.current.userInterfaceStyle == .dark
                    themeManager.syncAppIcon(systemIsDark: isDark)
                    // Check for updates in background
                    UpdateManager.shared.checkForUpdates(silent: true)
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
        
        AIService.shared.pendingImportURL = sharedVideoURL
    }
}
