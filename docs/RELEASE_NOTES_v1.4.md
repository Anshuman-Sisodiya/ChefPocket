# 🚀 Release Notes - v1.4.x Series

## ChefPocket v1.4.4 (Android) & v1.3.3 (iOS)

### 🌟 Highlights
The v1.4 release represents the most significant milestone in ChefPocket's development: **the launch of the 100% native Android edition with complete feature, data, and design parity with iOS**, accompanied by critical security and installation hardening.

---

### 🤖 Android Native Edition (New)
- **100% Native Jetpack Compose & Material 3**: Complete visual and tactile parity with iOS SwiftUI design.
- **All 434 Bundled Recipes**: Complete offline cookbook across 8 cuisines bundled in local assets.
- **4 Main Tabs**:
  - **Cookbook**: Multi-dimensional filtering across Cuisines, Meals, Courses, and Pure Veg / Non-Veg FSSAI badges.
  - **Thali Planner**: Macro rings, royal platter visualization, aggregate calorie/protein calculation, and 1-tap grocery export.
  - **Sabzi Mandi**: Card-segmented grocery checklist with 1-tap WhatsApp sharing.
  - **Cook Mode**: Circular whistle counter with tactile haptics, desi kitchen timers, and countertop screen wake lock.
- **System Share Sheet Integration**: Share links directly from YouTube or Instagram app into ChefPocket.
- **Multi-Language Support**: 8 fully localized languages.

---

### 🛡️ Android Compatibility & Security Hardening
- **MIUI / Xiaomi Package Installer Fix**:
  - Replaced vector adaptive icons with multi-density pre-rasterized PNG bitmaps to eliminate `android.view.InflateException`.
  - Added dual V1 (JAR) and V2/V3 signature scheme verification with `minSdk = 21`.
- **Google Play Protect False-Positive Clearing**:
  - Removed automated startup clipboard inspection in `onCreate()`.
  - Enforced `usesCleartextTraffic="false"` and `network_security_config.xml`.
  - Targeted Android 14 (`targetSdk = 34`).
  - Standardized Android User-Agent header.

---

### 🧠 AI Video Recipe Extraction
- Integrated **Google Gemini 3.6 Flash / 1.5 Flash** REST API.
- Converts fast YouTube Shorts and Instagram Reels into structured recipes with whistle counts, ingredients, and nutritional macros.
- Added 5s rate-limit cooldown and intelligent offline heuristic fallback.

---

### 💾 Data Persistence & Tombstones
- Decoupled user custom recipes into `chefpocket_user_custom_recipes_permanent`.
- Added permanent deletion tombstones (`chefpocket_deleted_recipe_tombstones_permanent`) to ensure deleted curated recipes stay deleted across app updates.
