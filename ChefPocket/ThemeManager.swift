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
    
    @Published var iconStatusMessage: String? = nil
    
    var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
    var currentIconName: String {
        return UIApplication.shared.alternateIconName ?? "AppIcon"
    }
    
    /// Automatically synchronizes the home screen app icon with the dark/light appearance
    func syncAppIcon(systemIsDark: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else {
            iconStatusMessage = "Alternate icons not supported in this environment."
            return
        }
        
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
            UIApplication.shared.setAlternateIconName("AppIcon-Dark") { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.iconStatusMessage = "Could not set dark icon: \(error.localizedDescription)"
                    } else {
                        self?.iconStatusMessage = "Dark obsidian icon applied."
                    }
                }
            }
        } else if !shouldBeDark && currentIcon != nil {
            UIApplication.shared.setAlternateIconName(nil) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.iconStatusMessage = "Could not restore default icon: \(error.localizedDescription)"
                    } else {
                        self?.iconStatusMessage = "Classic amber icon applied."
                    }
                }
            }
        }
    }
    
    /// Explicit manual icon switcher
    func setIconManually(useDark: Bool) {
        guard UIApplication.shared.supportsAlternateIcons else {
            iconStatusMessage = "Alternate icons not supported."
            return
        }
        let target = useDark ? "AppIcon-Dark" : nil
        UIApplication.shared.setAlternateIconName(target) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.iconStatusMessage = "Error switching icon: \(error.localizedDescription)"
                } else {
                    self?.iconStatusMessage = useDark ? "Dark icon active" : "Default icon active"
                    self?.objectWillChange.send()
                }
            }
        }
    }
}
