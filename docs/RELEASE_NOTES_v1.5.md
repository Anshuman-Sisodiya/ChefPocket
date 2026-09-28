# 🚀 Release Notes - v1.5.0 Universal Release

## ChefPocket v1.5.0 (Android & iOS Dual-Platform)

### 🌟 Highlights
ChefPocket v1.5.0 is a comprehensive architectural and feature upgrade across both iOS and Android. This release introduces a dedicated secure backend import service, full hardware-backed token encryption, manual recipe creation on Android, robust Android backup export & restore, accurate ingredient scaling & per-serving nutrition, a wall-clock cooking timer, dynamic dark app icon synchronization, and extensive bug fixes and audit hardening.

---

### 🛡️ Shared Backend Import Service (`server/`)
- **Secure Video Recipe Extraction Proxy**: Replaced fragile, direct in-app scraping and client-side Gemini calls with an isolated Node.js proxy server.
- **SSRF & Privacy Protection**: Blocks loopback, internal networks, private IP spaces, credentials, and non-canonical ports. Enforces redirect revalidation.
- **Audio/Video Multimodal AI & Fallback**: Sends native media inputs rather than bare URL prompts; parses captions and descriptions with multi-provider retry and cascade fallback.
- **Access Control & Rate Limiting**: Token-authenticated HTTP endpoints with configurable rate limits. 100% automated test coverage (9/9 unit tests passing).

---

### 🍏 iOS Enhancements & Fixes
- **Dark Mode App Icon**: Added dark artwork variant asset (`AppIcon-Dark-1024.png`) and updated `project.yml` for Xcode 16+ asset catalog compilation (`ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS: YES`).
- **Dynamic Appearance Sync**: Real-time icon switching responding to scene phases and system light/dark mode changes.
- **Secure Token Storage**: Bearer access tokens stored inside the iOS Keychain (`kSecClassGenericPassword`).
- **Share Extension Hardening**: Main-thread UI dispatch and URL query-item parameter encoding so complex URLs retain nested parameters. Incoming shared links safely trigger the import interface.
- **Accurate Nutrition & Scaling**: Detail view begins with actual recipe serving counts; ingredient quantities scale fractionally while nutrition remains accurately labeled per serving.
- **Wall-Clock Cooking Timer**: Uses `timerDeadline` and wall-clock offsets (`timeIntervalSinceNow`) to eliminate background drift and freezing.
- **Deterministic Storage & Tombstones**: Replaced randomized Swift `hashValue` with deterministic SHA-256 for cloud vault keys; enforced deleted recipe tombstones to prevent resurrection. Preserved case sensitivity in video IDs.

---

### 🤖 Android Enhancements & Fixes
- **Manual Recipe Creation**: Full manual recipe creation modal (`ManualRecipeDialog`) with custom ingredients, steps, category, and cuisine tags.
- **Native Backup & Restore (v1)**: Export and merge-import kitchen data (recipes, favorites, Mandi groceries, and Thali plans) with integrity verification.
- **6-Slot Thali Planner**: Complete support for Grain, Sabzi, Dal, Accompaniment, Salad, and Sweet with dietary preference auto-balancing and grocery export.
- **Cook Mode & Timer**: Step-by-step guidance, quick timer presets (1, 3, 5, 10, 15 min), pause/resume/reset, a resettable pressure cooker whistle counter, and screen keep-awake flag (`FLAG_KEEP_SCREEN_ON`). Timer state persists across screen rotation via `RecipeViewModel`.
- **Hardware-Backed Keystore Encryption**: Enforced `minSdk = 23` for Android Keystore AES/GCM/NoPadding token storage.
- **Data Integrity & Bug Fixes**:
  - `RecipeJson.kt` prevents Gson from bypassing Kotlin default values.
  - `RecipeLinks.kt` preserves case-sensitive video IDs.
  - Grocery items with matching names and units merge quantities instead of duplicating rows.
  - Tombstones prevent deleted bundled recipes from reappearing.
- **Build Isolation**: Debug builds use `.debug` package suffix and standard debug signing.

---

### 📦 Download Assets
- **Android APK**: `ChefPocket.apk` - Sideload-ready for Android 6.0+ (API 23+).
- **iOS IPA**: `ChefPocket.ipa` - Sideload-ready for iOS 16.0+ (AltStore, Sideloadly, TrollStore).