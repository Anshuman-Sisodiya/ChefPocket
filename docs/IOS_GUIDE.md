# 🍎 ChefPocket iOS Developer & User Guide

## 1. Technical Overview
ChefPocket for iOS is a native **SwiftUI** application designed for iOS 16.0 and above. It features modern glassmorphic aesthetics, fluid animations, custom haptic feedback, and an integrated **Share Extension** for Safari, YouTube, and Instagram.

- **Bundle Identifier**: `com.chefpocket.app`
- **Deployment Target**: iOS 16.0+
- **Language**: Swift 5.9
- **Project Generator**: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`)
- **App Extension**: `RecipeShareExtension.appex` (`com.chefpocket.app.share`)
- **App Group**: `group.com.chefpocket.app`

---

## 2. Share Extension Architecture
ChefPocket bundles an official `NSExtension` (`RecipeShareExtension`) configured in `project.yml`:

```yaml
RecipeShareExtension:
  type: app-extension
  platform: iOS
  deploymentTarget: "16.0"
  info:
    properties:
      NSExtension:
        NSExtensionPointIdentifier: "com.apple.share-services"
        NSExtensionPrincipalClass: "$(PRODUCT_MODULE_NAME).ShareViewController"
        NSExtensionAttributes:
          NSExtensionActivationRule: >-
            SUBQUERY (
                extensionItems,
                $extensionItem,
                SUBQUERY (
                    $extensionItem.attachments,
                    $attachment,
                    ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url"
                    OR ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.plain-text"
                ).@count >= 1
            ).@count >= 1
```

When a user shares a YouTube Short or Instagram Reel:
1. The Share Extension extracts the shared URL.
2. Writes the URL to the shared App Group container (`group.com.chefpocket.app`).
3. Triggers `chefpocket://import?url=...` to launch the main app directly into the AI Import Flow.

---

## 3. Sideloading Instructions (No Developer Account Required)

You can sideload ChefPocket onto any iPhone running iOS 16.0+ using **Sideloadly** or **AltStore** with a standard, free Apple ID:

### 3.1 Sideloading via Sideloadly (Windows & macOS)
1. Download **`ChefPocket.ipa`** from [GitHub Releases](https://github.com/Anshuman-Sisodiya/ChefPocket/releases).
2. Download and install [Sideloadly](https://sideloadly.io/).
3. Connect your iPhone to your computer via USB cable.
4. Launch Sideloadly and drag `ChefPocket.ipa` into the application window.
5. Enter your Apple ID and password (used strictly to generate a personal developer certificate from Apple).
6. Click **Start**.
7. Once finished, on your iPhone:
   - Go to **Settings** → **General** → **VPN & Device Management**.
   - Tap your Apple ID under *Developer App*.
   - Tap **Trust "[Your Apple ID]"**.
8. Open **ChefPocket** on your home screen.

### 3.2 Sideloading via AltStore
1. Install AltServer on your Mac or PC and install AltStore on your iPhone.
2. Download `ChefPocket.ipa` directly in Safari on your iPhone.
3. Open AltStore, go to **My Apps**, tap **+**, and select `ChefPocket.ipa`.
4. AltStore signs and installs the app wirelessly.

---

## 4. Building from Source

### Prerequisites
- macOS 14 Sonoma or macOS 15 Sequoia
- Xcode 15.4 or Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Build Steps
```bash
# 1. Clone repo
git clone https://github.com/Anshuman-Sisodiya/ChefPocket.git
cd ChefPocket

# 2. Generate Xcode project
xcodegen generate

# 3. Open in Xcode
open ChefPocket.xcodeproj
```

Select the **ChefPocket** scheme and target device/simulator, then press **Cmd + R**.
