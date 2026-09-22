<p align="center">
  <img src="ChefPocket/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="112" height="112" alt="ChefPocket Icon" style="border-radius: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.12);" />
</p>

<h1 align="center">ChefPocket</h1>

<p align="center">
  <strong>Dual-Platform Offline Culinary Companion and Smart Meal Planner</strong>
</p>

<p align="center">
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases"><img src="https://img.shields.io/github/v/release/Anshuman-Sisodiya/ChefPocket?color=0969da&style=flat-square" alt="Release" /></a>
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/actions"><img src="https://img.shields.io/github/actions/workflow/status/Anshuman-Sisodiya/ChefPocket/build-apk.yml?branch=main&label=Android%20CI&style=flat-square" alt="Android CI" /></a>
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/actions"><img src="https://img.shields.io/github/actions/workflow/status/Anshuman-Sisodiya/ChefPocket/build-ipa.yml?branch=main&label=iOS%20CI&style=flat-square" alt="iOS CI" /></a>
  <img src="https://img.shields.io/badge/Platform-iOS%2016.0+%20%7C%20Android%205.0+-24292f?style=flat-square" alt="Platform Support" />
  <img src="https://img.shields.io/badge/Architecture-SwiftUI%20%7C%20Jetpack%20Compose-58a6ff?style=flat-square" alt="Architecture" />
  <img src="https://img.shields.io/badge/AI%20Engine-Gemini%20Flash-4285F4?style=flat-square&logo=google" alt="Google Gemini" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Anshuman-Sisodiya/ChefPocket?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.apk">Download Android APK</a> &bull;
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.ipa">Download iOS IPA</a> &bull;
  <a href="#installation-and-sideloading">Installation Guide</a> &bull;
  <a href="docs/ARCHITECTURE.md">Architecture</a> &bull;
  <a href="docs/SECURITY_AND_PRIVACY.md">Security & Privacy</a>
</p>

---

## Overview

ChefPocket is a native, offline-first culinary companion engineered for both iOS (SwiftUI) and Android (Jetpack Compose & Material 3). It solves daily kitchen decision fatigue, automates meal planning, tracks pressure cooker cycles, and converts short-form cooking videos (YouTube Shorts and Instagram Reels) into structured recipe cards using Google Gemini AI.

The application bundles 434 verified recipes across eight world cuisines directly within the client binary. Core features function completely offline without tracking, third-party analytics, or advertising networks.

---

## Core Features

### 1. Inbuilt Offline Cookbook (434 Recipes)
- **Artisan Bakery & Breads (65)**: Sourdough loaves, French baguettes, Italian ciabatta, shokupan milk bread, brioche, NY bagels, croissants, tarts, and cheesecakes.
- **Drinks & Brews (60)**: Cold brews, Affogato, filter kaapi, boba milk tea, iced matcha lattes, virgin mojitos, and fruit coolers (100% non-alcoholic).
- **Continental & Italian Bistro (39)**: Pasta classics, Neapolitan pizza, risottos, lasagnas, and continental soups.
- **Asian & Indo-Chinese (42)**: Steamed and fried momos, dim sums, bao buns, chowmein, pad thai, and Thai curries.
- **Mexican & Tex-Mex (30)**: Tacos, birria, burritos, quesadillas, enchiladas, and nachos.
- **Middle Eastern & Mediterranean (27)**: Falafel, hummus, baba ganoush, pita, shawarma, and baklava.
- **Indian Cafe Specials (35)**: Bombay grilled sandwiches, paninis, loaded fries, burgers, and waffles.
- **Indian Regional Heritage (136)**: Biryanis, Malabar curries, Chettinad specialties, Bengali delicacies, and Kashmiri classics.

### 2. Multi-Dimensional Taxonomy
- **Cuisine Filters**: Indian Regional, Continental & Italian, Asian & Indo-Chinese, Mexican & Tex-Mex, Middle Eastern, Cafe & Bistro, Bakery & Breads, Drinks & Brews.
- **Dietary Classification**: Pure Vegetarian and Non-Vegetarian options with official FSSAI geometric markings.
- **Meal Occasions**: Breakfast, Lunch, Snacks, and Dinner.
- **Culinary Courses**: Bakery, Drinks & Shakes, Sabzi, Dal, High-Protein, Street Food, Rice & Biryani, and Fusion.

### 3. Dynamic Serving Size Scaler
- Interactive serving stepper (1 to 12 servings) on recipe detail cards.
- Dynamically recalculates ingredient measurements in real time.
- Automatically exports scaled quantities directly to the grocery list.

### 4. Deterministic Nutritional Precision
- Calculates total and per-serving macronutrients (calories and protein) based on standard ICMR-NIN (National Institute of Nutrition) and USDA FoodData Central values.
- AI recipe extractions calculate caloric and protein totals from ingredient gram weights and serving divisors rather than estimates.

### 5. AI Video Recipe Extraction
- Ingests cooking video links from YouTube Shorts and Instagram Reels.
- Calls the Google Gemini Flash REST API to parse ingredients, instructions, cooker whistle counts, and dietary tags.
- Includes automated clipboard detection, a 1-tap quick action bar, rate-limit cooldowns, and offline heuristic fallbacks.

### 6. Daily Thali Planner
- Modular meal builder: Dal + Sabzi + Bread/Rice + Dahi/Accompaniment.
- Real-time aggregate calorie and protein calculation.
- 1-tap transfer of all selected course ingredients into your grocery checklist.

### 7. Sabzi Mandi Grocery List
- Organizes ingredients into authentic shopping aisles:
  - Fresh Produce (Sabzi Mandi)
  - Spices & Seeds (Masala Dabba)
  - Dals & Grains
  - Dairy & Ghee
  - Meat, Fish & Eggs
- Share formatted checklists directly via WhatsApp or system share sheet.

### 8. Countertop Cook Mode
- Large tactile whistle counter with haptic feedback.
- Kitchen timers for standard techniques: Tadka (45s), Bhunao (7m), Dal Boil (10m), and Dum (15m).
- Automatic screen wake-lock prevents the device from sleeping during preparation.

### 9. Multi-Language Localization
Native localization support across eight languages:
- English
- Hindi (हिन्दी)
- Hinglish (Everyday Conversational)
- Spanish (Español)
- French (Français)
- Tamil (தமிழ்)
- Telugu (తెలుగు)
- Bengali (বাংলা)

### 10. Industry-Standard Authentication & Cloud Sync
- Native Sign in with Apple (iOS FaceID/TouchID).
- Secure Google OAuth 2.0 via `ASWebAuthenticationSession`.
- Optional cloud sync across devices using your private Google Drive or manual backup exports (`.chefpocket`).

---

## Architecture & Technology Stack

| Layer | iOS Target | Android Target |
| :--- | :--- | :--- |
| **Language** | Swift 5.9 | Kotlin 1.9.24 |
| **UI Framework** | SwiftUI (iOS 16.0+) | Jetpack Compose with Material 3 |
| **Project Build Tool** | XcodeGen (`project.yml`) | Gradle 8.7 with AGP 8.4.1 |
| **AI Integration** | Gemini Flash REST API | Gemini Flash REST API |
| **Share Ingestion** | `RecipeShareExtension.appex` | `Intent.ACTION_SEND` Activity |
| **Persistence** | Unversioned `UserDefaults` | Unversioned `SharedPreferences` |
| **Update Engine** | GitHub Releases API Checker | Direct APK / Play Protect Compliant |
| **Network Security** | Sandboxed App Container | Strict TLS 1.3, `usesCleartextTraffic=false` |

For in-depth architectural specifications, refer to the [Technical Architecture Document](docs/ARCHITECTURE.md).

---

## Installation and Sideloading

### Android (Samsung, Xiaomi/Redmi, Pixel, OnePlus)
1. Download [`ChefPocket.apk`](https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.apk).
2. Open the file on your device and proceed with the installation prompt.
3. If Google Play Protect shows a verification note for sideloaded apps:
   - Tap **More details**
   - Select **Install anyway**
   *(ChefPocket contains zero trackers or ads and is signed with an independent developer key. See the [Android Guide](docs/ANDROID_GUIDE.md) for full compliance details).*

### iOS (iPhone running iOS 16.0 or later)
1. Download [`ChefPocket.ipa`](https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.ipa).
2. Connect your iPhone to your computer.
3. Install the IPA via [Sideloadly](https://sideloadly.io/) or [AltStore](https://altstore.io/) using your Apple ID.
4. On your iPhone, navigate to **Settings** &rarr; **General** &rarr; **VPN & Device Management** &rarr; Tap your Apple ID &rarr; Select **Trust**.
5. Future updates can be checked directly within the app via **Settings** &rarr; **Check for Updates**.

---

## Building from Source

### Android Build
```bash
cd android
./gradlew :app:assembleRelease
# Output artifact: android/app/build/outputs/apk/release/app-release.apk
```

### iOS Build
```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate Xcode project
xcodegen generate

# 3. Compile project
xcodebuild clean build -project ChefPocket.xcodeproj -scheme ChefPocket -destination "generic/platform=iOS"
```

---

## Documentation

- [Architecture Specification](docs/ARCHITECTURE.md)
- [Android Developer & User Guide](docs/ANDROID_GUIDE.md)
- [iOS Developer & User Guide](docs/IOS_GUIDE.md)
- [Security & Privacy Policy](docs/SECURITY_AND_PRIVACY.md)
- [Release Notes](docs/RELEASE_NOTES_v1.4.md)
- [Contribution Guidelines](CONTRIBUTING.md)

---

## License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for terms.

---

<p align="center">
  Maintained by <a href="https://github.com/Anshuman-Sisodiya">Anshuman Sisodiya</a>
</p>
