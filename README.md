<p align="center">
  <img src="ChefPocket/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="120" height="120" alt="ChefPocket Icon" style="border-radius: 26px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);" />
</p>

<h1 align="center">ChefPocket</h1>

<p align="center">
  <strong>The Ultimate Native iOS Culinary Companion & Smart Desi Cookbook</strong>
</p>

<p align="center">
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/releases"><img src="https://img.shields.io/github/v/release/Anshuman-Sisodiya/ChefPocket?color=orange&style=flat-square" alt="Latest Release" /></a>
  <a href="https://github.com/Anshuman-Sisodiya/ChefPocket/actions"><img src="https://img.shields.io/github/actions/workflow/status/Anshuman-Sisodiya/ChefPocket/build-ipa.yml?branch=main&label=build&style=flat-square" alt="Build Status" /></a>
  <img src="https://img.shields.io/badge/Platform-iOS%2016.0+-blue?style=flat-square&logo=apple" alt="iOS 16+" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift 5.9" />
  <img src="https://img.shields.io/badge/AI-Gemini%201.5%20Flash-4285F4?style=flat-square&logo=google" alt="Google Gemini AI" />
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Anshuman-Sisodiya/ChefPocket?style=flat-square" alt="License" /></a>
</p>

---

## 📖 Overview

**ChefPocket** is an authentic, high-aesthetic native iOS application designed for home cooks, food lovers, and fitness enthusiasts. Built using modern SwiftUI, it solves everyday kitchen challenges — from *"Aaj Kya Banau?"* decision fatigue to tracking pressure cooker whistles, planning balanced Indian Thalis, and converting fast YouTube Shorts & Instagram Reels into structured cooking recipes using Google Gemini AI.

---

## ✨ Features at a Glance

### 🍽️ 125+ Curated Inbuilt Recipes
- **65 Pure Vegetarian Dishes**: Dhaba Paneer Bhurji, Dal Makhani, Dal Tadka, Amritsari Pindi Chole, Moong Dal Chilla, Palak Paneer, Pav Bhaji, Veg Dum Biryani, and more.
- **60 Non-Vegetarian Dishes**: Butter Chicken, Mutton Rogan Josh, Champaran Handi Meat, Goan Fish Curry, Prawn Ghee Roast, Irani Cafe Egg Bhurji, Kolkata Biryani, and more.
- **Nutritional Transparency**: Calories, protein in grams, prep time, and cooker whistle counts for every recipe.

### 🥗 Pure Veg (🟢) & Non-Veg (🔴) Filtering
- Dedicated capsule pills (`All 125`, `Veg 65`, `Non-Veg 60`) that never truncate.
- **Official FSSAI Vector Marks**: Geometric square-and-dot badges representing authentic food packaging standards.
- Diet-aware randomizer: Pure Veg mode will never suggest non-veg dishes.

### 🌅 Meal Occasions
- Instantly filter dishes across **Breakfast (Nashta)**, **Lunch**, **Snacks & Tea-Time**, and **Dinner**.

### 🤖 AI Video Recipe Extractor (Google Gemini 1.5 Flash)
- Paste any cooking link from **YouTube Shorts** or **Instagram Reels**.
- Directly calls the **Google Gemini 1.5 Flash REST API** to extract authentic ingredient measurements, pressure cooker whistle counts, and step-by-step cooking instructions.
- **Resource Safeguards**: Built-in 5s cooldown rate limiter, 25 requests/day quota tracker, and intelligent offline heuristic fallback.

### 🍱 Daily Thali Planner
- Mix and match your meal: **Dal + Sabzi + Roti/Rice + Dahi/Salad**.
- Real-time aggregate calorie and protein calculation.
- 1-tap transfer of all Thali ingredients directly into your grocery list.

### 🛒 Sabzi Mandi Grocery List
- Automatically routes recipe ingredients into Indian shopping aisles:
  - 🌿 **Sabzi Mandi** (Fresh produce)
  - 🫙 **Masala Dabba** (Spices & seeds)
  - 🌾 **Dals & Grains** (Lentils, rice, flours)
  - 🥛 **Dairy & Ghee** (Paneer, curd, butter)
  - 🥩 **Meat, Fish & Eggs**
- **1-Tap WhatsApp Share**: Export your formatted grocery list directly to family or vendors.

### ⏱️ Countertop Cook Mode & Whistle Counter
- **Whistle Counter**: Big, tactile tap target with haptic feedback and target whistle alert.
- **Desi Kitchen Timers**: *Tadka Splutter (45s)*, *Bhunao (7m)*, *Dal Boil (10m)*, *Dum (15m)*.
- **Hands-Free Cooking**: Keeps your iPhone screen awake (`isIdleTimerDisabled = true`) while cooking.

### 📲 Social Media Sharing
- Share formatted recipes with ingredients, steps, and video links to **WhatsApp**, **Instagram Stories**, **iMessage**, **Twitter/X**, and **Telegram**.

### 👤 User Authentication & Profile
- Local account authentication (Sign In / Sign Up) with guest mode support.
- Track culinary statistics: Curated recipes, My Kitchen creations, and Favorites.
- Configure custom Google Gemini API Key for unlimited AI extractions.

---

## 🏗️ Architecture & Tech Stack

- **UI Framework**: SwiftUI (iOS 16.0+)
- **Project Generation**: [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`)
- **CI/CD Pipeline**: GitHub Actions (`macos-14`, Xcode 15/16) automated `.ipa` building & signing injection.
- **AI Integration**: Google Gemini 1.5 Flash REST API (`URLSession`, structured JSON schema output)
- **Data Layer**: `Codable`, `UserDefaults` with App Group fallback, local JSON bundle.
- **Share Extension**: `RecipeShareExtension.appex` (`NSExtension` for sharing links directly from Safari, YouTube, or Instagram).

---

## 📲 Sideloading Installation (iPhone 13 / iOS 16+)

You can install ChefPocket without an active Apple Developer Program membership using **Sideloadly** or **AltStore**:

1. Download the latest compiled **`ChefPocket.ipa`** from the [GitHub Releases](https://github.com/Anshuman-Sisodiya/ChefPocket/releases).
2. Connect your iPhone to your Windows PC or Mac.
3. Open **Sideloadly** (or AltStore).
4. Drag and drop `ChefPocket.ipa` into Sideloadly.
5. Enter your free Apple ID and click **Start**.
6. When installation finishes, on your iPhone go to:
   - **Settings** → **General** → **VPN & Device Management** → Tap your Apple ID → **Trust**.
7. Launch **ChefPocket** and enjoy cooking!

---

## 🛠️ Building from Source

### Prerequisites
- macOS Sonoma or later
- Xcode 15.4 or Xcode 16+
- [Homebrew](https://brew.sh/)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Build Steps
```bash
# 1. Clone the repository
git clone https://github.com/Anshuman-Sisodiya/ChefPocket.git
cd ChefPocket

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open ChefPocket.xcodeproj
```

Select the **ChefPocket** scheme and your target iOS Device / Simulator, then press **Cmd + R** to run.

---

## 🤝 Contributing

Contributions are welcome! Whether it's submitting a new authentic recipe, optimizing AI extraction prompts, or refining the UI:

1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingRecipe`).
3. Commit your Changes (`git commit -m 'Add Goan Prawn Balchão recipe'`).
4. Push to the Branch (`git push origin feature/AmazingRecipe`).
5. Open a Pull Request.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<p align="center">
  Built with ❤️ for culinary enthusiasts by <a href="https://github.com/Anshuman-Sisodiya">Anshuman Sisodiya</a>
</p>
