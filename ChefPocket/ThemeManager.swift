import Foundation
import SwiftUI
import UIKit

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("chefpocket_app_theme") var appTheme: String = "system" {
        didSet {
            objectWillChange.send()
        }
    }
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    /// Automatically synchronizes the home screen app icon with the dark/light appearance
    func syncAppIcon(systemIsDark: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        let shouldBeDark: Bool
        switch appTheme {
        case "dark":
            shouldBeDark = true
        case "light":
            shouldBeDark = false
        default:
            shouldBeDark = systemIsDark
        }
        
        let currentIcon = UIApplication.shared.alternateIconName
        
        if shouldBeDark && currentIcon != "AppIcon-Dark" {
            UIApplication.shared.setAlternateIconName("AppIcon-Dark") { error in
                if let error = error {
                    print("Failed to set dark mode app icon: \(error.localizedDescription)")
                }
            }
        } else if !shouldBeDark && currentIcon != nil {
            UIApplication.shared.setAlternateIconName(nil) { error in
                if let error = error {
                    print("Failed to restore default app icon: \(error.localizedDescription)")
                }
            }
        }
    }
}
