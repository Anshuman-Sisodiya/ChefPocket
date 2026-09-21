<p align="center">
  <img src="ChefPocket/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="120" height="120" alt="ChefPocket Icon" style="border-radius: 26px; box-shadow: 0 8px 28px rgba(0,0,0,0.18);" />
</p>

<h1 align="center">ChefPocket</h1>

<p align="center">
  <strong>The Ultimate Dual-Platform (iOS & Android) Culinary Companion & Smart Desi Cookbook</strong>
</p>

<p align="center">
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases"><img src="https://img.shields.io/github/v/release/Anshuman-Sisodiya/ChefPocket?color=orange&style=flat-square" alt="Latest Release" /></a>
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/actions"><img src="https://img.shields.io/github/actions/workflow/status/Anshuman-Sisodiya/ChefPocket/build-apk.yml?branch=main&label=Android%20Build&style=flat-square" alt="Android Build Status" /></a>
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/actions"><img src="https://img.shields.io/github/actions/workflow/status/Anshuman-Sisodiya/ChefPocket/build-ipa.yml?branch=main&label=iOS%20Build&style=flat-square" alt="iOS Build Status" /></a>
  <img src="https://img.shields.io/badge/Platform-iOS%2016.0+%20%7C%20Android%205.0+-blue?style=flat-square" alt="Platforms" />
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%7C%20Jetpack%20Compose-purple?style=flat-square" alt="UI" />
  <img src="https://img.shields.io/badge/AI-Gemini%203.6%20Flash-4285F4?style=flat-square&logo=google" alt="Google Gemini AI" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Anshuman-Sisodiya/ChefPocket?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.apk"><strong>📲 Download Android APK (v1.4.4)</strong></a> •
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.ipa"><strong>🍏 Download iOS IPA (v1.3.3)</strong></a> •
  <a href="#-quick-installation--sideloading"><strong>🚀 Installation Guide</strong></a> •
  <a href="docs/ARCHITECTURE.md"><strong>🏛️ Architecture</strong></a> •
  <a href="docs/SECURITY_AND_PRIVACY.md"><strong>🔒 Privacy Policy</strong></a>
</p>

---

## 📖 Overview

**ChefPocket** is an authentic, high-aesthetic culinary companion designed for home cooks, food lovers, and fitness enthusiasts. Available natively on both **iOS (SwiftUI)** and **Android (Jetpack Compose & Material 3)**, it solves everyday kitchen challenges — from *"Aaj Kya Banau?"* decision fatigue to tracking pressure cooker whistles, planning balanced Indian Thalis, managing grocery aisles, and converting fast YouTube Shorts & Instagram Reels into structured cooking recipes using **Google Gemini AI**.

All **434 curated recipes** across 8 world cuisines are stored 100% offline on your device, ensuring lightning-fast performance and total privacy without tracking or ads.

---

## 🆕 What's New in v1.4.x
- **🤖 100% Native Android Edition**: Complete Jetpack Compose & Material 3 implementation with identical features, design, and data parity with the iOS version.
- **🛡️ Google Play Protect Hardened**: Strict security posture with `usesCleartextTraffic="false"`, `network_security_config.xml`, `allowBackup="false"`, and removal of automated clipboard inspection.
- **⚡ MIUI & Redmi Compatibility**: Dual V1 (JAR) and V2/V3 signature schemes with multi-density pre-rasterized PNG mipmaps, resolving Xiaomi Package Installer errors.
- **📲 System Share Target**: Share cooking links directly from YouTube Shorts or Instagram Reels into ChefPocket on both Android (`ACTION_SEND`) and iOS (`RecipeShareExtension`).
- **🧠 Google Gemini 3.6 Flash / 1.5 Flash AI Engine**: Fast video recipe extraction with structured ingredients, whistle counts, and nutritional macros.
- **💾 Permanent Custom Recipe Storage & Tombstones**: User recipes and deleted curated items are preserved across app updates via unversioned stores (`chefpocket_user_custom_recipes_permanent` and `chefpocket_deleted_recipe_tombstones_permanent`).
- **🌐 8 Localized Languages**: English, Hindi (हिन्दी), Hinglish, Spanish, French, Tamil, Telugu, and Bengali.

---

## ✨ Features at a Glance

### 🍽️ 434 Curated Inbuilt Recipes (100% Offline)
- **🥖 Artisan Bakery & Breads (65 Recipes)**: Sourdough Country Loafs, French Baguettes, Italian Ciabatta, Shokupan Milk Bread, Brioche, NY Bagels, Pita, 8 Croissant variations, and 10 Cheesecakes (New York Baked, Basque Burnt, Lotus Biscoff, Japanese Cotton Soufflé, Blueberry).
- **☕ Drinks, Brews & Cafe Coolers (60 Recipes - Non-Alcoholic)**: 18-Hour Cold Brews, Affogato, Brass Davarah Filter Kaapi, Tiger Boba Milk Tea, Iced Matcha Latte, Peach Mint Iced Tea, Noon Chai, Virgin Mojitos, Blue Curacao Lemonade, and Healthy Smoothies.
- **🍝 Continental & Italian Bistro (39 Recipes)**: Aglio e Olio, Arrabbiata, Fettuccine Alfredo, Genovese Pesto, Lasagna, Roman Cacio e Pepe, Truffle Tagliatelle, Neapolitan Margherita, Sizzlers, and French Onion Soup.
- **🥟 Asian & Indo-Chinese Bistro (42 Recipes)**: Street Steamed Veg & Chicken Momos, Kurkure Fried Momos, Crystal Dimsums, Prawn Har Gow, Bao Buns, Hakka Chowmein, Schezwan Fried Rice, Pad Thai, Dan Dan Noodles, and Thai Curries.
- **🌮 Mexican & Tex-Mex Classics (30 Recipes)**: Baja Fish Tacos, Paneer Tinga, Chicken Birria with Consomé Dip, Quesadillas, Mission Burritos, Enchiladas Rojas & Verdes, Loaded Nachos, and Churros.
- **🧆 Middle Eastern & Mediterranean Heritage (27 Recipes)**: Crispy Falafel, Silk-Smooth Hummus, Baba Ganoush, Fluffy Pita Pockets, Whipped Toum, Tabbouleh, Shakshuka, Shawarma Wraps, and Pistachio Baklava.
- **🥪 Indian Cafe & Bistro Specials (35 Recipes)**: Bombay Masala Grilled Sandwich, Club Sandwiches, Peri Peri Paninis, Corn & Spinach Melts, Gourmet Burgers, Truffle Parmesan Fries, Loaded Makhani Fries, and Waffles.
- **🍛 Indian Regional Heritage (136 Recipes)**: Hyderabadi Dum Biryani, Awadhi Mutton Biryani, Kolkata Biryani, Chettinad Pepper Chicken, Malabar Fish Curry, Goan Balchão, Bengali Shorshe Maach, Rajasthani Laal Maas, and Kashmiri Rogan Josh.

### 🌐 Multi-Dimensional Culinary Filtering
- **Cuisines**: `Indian Regional`, `Continental & Italian`, `Asian & Indo-Chinese`, `Mexican & Tex-Mex`, `Middle Eastern`, `Cafe & Bistro`, `Bakery & Breads`, and `Drinks & Brews`.
- **Diet Selector**: `All (434)`, `Veg (306)`, `Non-Veg (128)` with geometric vector FSSAI badges.
- **Meal Occasions**: `Breakfast (Nashta)`, `Lunch`, `Snacks & Tea-Time`, and `Dinner`.
- **Courses**: `Bakery`, `Drinks & Shakes`, `Sabzi`, `Dal`, `High-Protein`, `Street Food`, `Rice & Biryani`, and `Fusion`.

### 🤖 AI Video Recipe Extractor (Gemini 3.6 Flash / 1.5 Flash)
- Paste any link or share directly from **YouTube Shorts** or **Instagram Reels**.
- Directly queries the Google Gemini REST API to extract authentic ingredient quantities, pressure cooker whistle counts, and step-by-step instructions.
- Includes rate-limiting protection (5s cooldown) and intelligent offline heuristic fallback.

### 🍱 Daily Thali Planner
- Mix and match balanced Indian meals: **Dal + Sabzi + Roti/Rice + Dahi/Salad**.
- Real-time aggregate calorie and protein calculation.
- 1-tap transfer of all ingredients directly into your grocery list.

### 🛒 Sabzi Mandi Grocery List
- Automatically categorizes ingredients into authentic Indian shopping aisles:
  - 🌿 **Sabzi Mandi** (Fresh produce)
  - 🫙 **Masala Dabba** (Spices & seeds)
  - 🌾 **Dals & Grains** (Lentils, rice, flours)
  - 🥛 **Dairy & Ghee** (Paneer, curd, butter)
  - 🥩 **Meat, Fish & Eggs**
- **1-Tap WhatsApp Share**: Export formatted grocery checklists directly to family members or local vendors.

### ⏱️ Countertop Cook Mode & Whistle Counter
- **Whistle Counter**: Large tactile button with haptic feedback and target whistle alert.
- **Desi Kitchen Timers**: *Tadka Splutter (45s)*, *Bhunao (7m)*, *Dal Boil (10m)*, *Dum (15m)*.
- **Hands-Free Cooking**: Automatically keeps your device screen awake while cooking.

---

## 📲 Quick Installation & Sideloading

### 🤖 Android (Samsung, Redmi, Pixel, OnePlus, etc.)
1. Download **[`ChefPocket.apk`](https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.apk)**.
2. Tap the APK file to install.
3. If Google Play Protect shows *"Harmful app blocked: This app is fake"*:
   - Tap **"More details" ∨**
   - Tap **"Install anyway"**
   *(This false positive occurs because ChefPocket is sideloaded with an independent key rather than distributed via Play Store. See [Android Guide](docs/ANDROID_GUIDE.md) for verification details).*

### 🍏 iOS (iPhone running iOS 16.0+)
1. Download **[`ChefPocket.ipa`](https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.ipa)**.
2. Connect your iPhone to your PC or Mac.
3. Use **[Sideloadly](https://sideloadly.io/)** or **AltStore** to install `ChefPocket.ipa` with your free Apple ID.
4. On your iPhone: go to **Settings** → **General** → **VPN & Device Management** → Tap your Apple ID → **Trust**.

---

## 🏗️ Architecture & Tech Stack

| Component | iOS Implementation | Android Implementation |
| :--- | :--- | :--- |
| **Language** | Swift 5.9 | Kotlin 1.9.24 |
| **UI Framework** | SwiftUI (iOS 16.0+) | Jetpack Compose & Material 3 |
| **Build Tooling** | XcodeGen (`project.yml`) | Gradle 8.7 + AGP 8.4.1 |
| **AI Integration** | Gemini 3.6 Flash / 1.5 Flash REST API | Gemini 3.6 Flash / 1.5 Flash REST API |
| **Share Ingestion** | `RecipeShareExtension.appex` | `Intent.ACTION_SEND` Activity |
| **Persistence** | `UserDefaults` + App Group | `SharedPreferences` + `Gson` |
| **Security** | Sandboxed Container | Strict TLS / No Cleartext / API 34 |

For detailed technical specifications, read the [Architecture Documentation](docs/ARCHITECTURE.md).

---

## 🛠️ Building from Source

### Building Android App
```bash
cd android
./gradlew :app:assembleRelease
# Output: android/app/build/outputs/apk/release/app-release.apk
```

### Building iOS App
```bash
# 1. Install XcodeGen
brew install xcodegen

# 2. Generate Xcode project
xcodegen generate

# 3. Open and build
open ChefPocket.xcodeproj
```

---

## 📚 Detailed Documentation
- [🏛️ Architecture Overview](docs/ARCHITECTURE.md)
- [🤖 Android Developer & User Guide](docs/ANDROID_GUIDE.md)
- [🍎 iOS Developer & User Guide](docs/IOS_GUIDE.md)
- [🔒 Security & Privacy Policy](docs/SECURITY_AND_PRIVACY.md)
- [🚀 Release Notes v1.4.x](docs/RELEASE_NOTES_v1.4.md)
- [🤝 Contributing Guidelines](CONTRIBUTING.md)

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<p align="center">
  Built with ❤️ for culinary enthusiasts by <a href="https://github.com/Anshuman-Sisodiya">Anshuman Sisodiya</a>
</p>
