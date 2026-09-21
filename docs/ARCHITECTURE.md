# 🏛️ ChefPocket Technical Architecture

## 1. Executive Summary
ChefPocket is designed from the ground up as a **dual-platform, offline-first culinary companion** available natively on **iOS (SwiftUI)** and **Android (Jetpack Compose & Material 3)**. Both platforms achieve 100% data, aesthetic, and functional parity while strictly honoring their respective platform idioms and design guidelines.

```
+-----------------------------------------------------------------------------------+
|                                 ChefPocket App                                    |
+-----------------------------------------------------------------------------------+
|               iOS Target (SwiftUI)            |         Android Target (Compose)  |
|   - iOS 16.0+, Swift 5.9                      |   - Android 5.0 - 14 (API 21-34)  |
|   - Glassmorphism & Apple Human Interface     |   - Material Design 3 (M3) Theming|
|   - RecipeShareExtension (NSExtension)        |   - ACTION_SEND Share Sheet Target|
+-----------------------------------------------+-----------------------------------+
|                             Shared Unified Core Models                            |
|             (RecipesData.json / recipes_data.json - 434 Verified Recipes)         |
+-----------------------------------------------------------------------------------+
|                                Offline-First Storage Layer                        |
|   - Default Curated Bundle (434 Recipes)                                          |
|   - Permanent Custom Recipes (chefpocket_user_custom_recipes_permanent)           |
|   - Permanent Deletion Tombstones (chefpocket_deleted_recipe_tombstones_permanent)|
|   - Cross-Platform Cloud Sync Format (chefpocket_sync_payload.json)               |
+-----------------------------------------------------------------------------------+
|                               AI Recipe Ingestion Engine                          |
|   - Google Gemini 3.6 Flash / 1.5 Flash REST API Integration                      |
|   - YouTube Shorts & Instagram Reels Extraction Pipeline                          |
|   - Offline Heuristic Parsing Fallback                                            |
+-----------------------------------------------------------------------------------+
```

---

## 2. Core Architectural Pillars

### 2.1 100% Offline-First
All 434 culinary recipes across 8 world cuisines are completely bundled inside the application binary (`ChefPocket/RecipesData.json` on iOS, `android/app/src/main/assets/recipes_data.json` on Android). 
- The cookbook, thali planner, sabzi mandi grocery list, and countertop cook mode function seamlessly with zero internet connection or cellular coverage.
- Network access is invoked strictly on-demand for AI video recipe extraction from YouTube Shorts / Instagram Reels and optional cloud backup.

### 2.2 Unversioned Permanent Storage & Tombstones
To prevent user data loss during app updates, ChefPocket implements a decoupled, unversioned storage architecture:
1. **Permanent Custom Recipes (`chefpocket_user_custom_recipes_permanent`)**:
   - User-created and AI-extracted recipes are saved independently of the curated bundle.
   - App updates never touch or overwrite this store.
2. **Permanent Deletion Tombstones (`chefpocket_deleted_recipe_tombstones_permanent`)**:
   - Stores the unique IDs of curated recipes deleted by the user.
   - When the app loads or synchronizes, tombstones filter out deleted recipes so they never resurface.
3. **Retroactive Migration Engine**:
   - Automatically scans legacy schema keys (`v1` through `v6`) on startup and consolidates recipes into the permanent unversioned store without duplicate entries.

### 2.3 AI Recipe Extraction Pipeline
```
[User shares/pastes Short/Reel URL]
                │
                ▼
  [URL Canonicalization & Normalization]
  (Deduplicates shorts/, reels/, youtu.be, and tracking query params)
                │
                ▼
  [Metadata Scraping & Heuristics]
  (Extracts video titles, captions, and descriptions via mobile user-agent)
                │
                ▼
  [Google Gemini REST API Request]
  (Model: gemini-1.5-flash / gemini-2.0-flash / gemini-3.6-flash)
  - System Instructions: Authentic culinary structuring
  - Output Schema: JSON format with ingredients, steps, whistles, and macros
                │
                ├───► [Success] ──► Parse JSON ──► Add to My Kitchen ──► Toast / Open
                │
                └───► [Offline / Rate-limited] ──► Intelligent Heuristic Fallback
```

### 2.4 Multi-Dimensional Culinary Taxonomy
Every recipe is mapped across five orthogonal categorization dimensions:
1. **Cuisines (8)**: `Indian Regional`, `Continental & Italian`, `Asian & Indo-Chinese`, `Mexican & Tex-Mex`, `Middle Eastern`, `Cafe & Bistro`, `Bakery & Breads`, `Drinks & Brews`.
2. **Dietary Type**: `Pure Veg (🟢)` and `Non-Veg (🔴)` with official FSSAI geometric markings.
3. **Meal Occasions (4)**: `Breakfast (Nashta)`, `Lunch`, `Snacks & Tea-Time`, `Dinner`.
4. **Culinary Courses (8)**: `Bakery`, `Drinks & Shakes`, `Sabzi`, `Dal`, `High-Protein`, `Street Food`, `Rice & Biryani`, `Fusion`.
5. **Kitchen Attributes**: Cooker whistle counts, prep & cook times, calorie estimates, and protein grams.

### 2.5 Multi-Language Localization
Native translation without external cloud lookups across 8 languages:
- English
- Hindi (हिन्दी)
- Hinglish (Everyday Indian Conversational)
- Spanish (Español)
- French (Français)
- Tamil (தமிழ்)
- Telugu (తెలుగు)
- Bengali (বাংলা)

---

## 3. Unified Data Schema

Both Swift and Kotlin implementations serialize and deserialize against this exact JSON schema:

```json
{
  "id": "biryani_hyd_001",
  "name": "Hyderabadi Dum Biryani",
  "category": "Rice & Biryani",
  "cuisine": "Indian Regional",
  "diet": "Non-Veg",
  "mealOccasion": "Lunch",
  "prepTime": "45 mins",
  "cookTime": "40 mins",
  "calories": 620,
  "protein": 34,
  "cookerWhistles": 0,
  "ingredients": [
    "500g Basmati Rice (aged)",
    "750g Mutton / Chicken (curry cut)",
    "1 cup Fried Onions (Birista)",
    "1 cup Thick Curd / Dahi",
    "2 tbsp Shahi Biryani Masala",
    "1 tsp Saffron strands soaked in 4 tbsp warm milk",
    "3 tbsp Pure Desi Ghee"
  ],
  "steps": [
    "Marinate meat with curd, ginger-garlic paste, spices, and half of fried onions for 2 hours.",
    "Boil water with whole spices, parboil soaked rice to 70% doneness, and drain.",
    "Layer marinated meat at bottom of heavy pot, spread parboiled rice, top with saffron milk, ghee, and remaining fried onions.",
    "Seal edges with dough lid and cook on low heat (Dum) for 35-40 minutes.",
    "Rest for 10 minutes before gently fluffing layers from bottom."
  ],
  "imageName": "hyderabadi_biryani",
  "isFavorite": false,
  "isCustom": false,
  "sourceURL": "https://youtube.com/shorts/..."
}
```

---

## 4. Platform Architectural Implementations

### 4.1 iOS Implementation
- **Language**: Swift 5.9
- **Framework**: SwiftUI (iOS 16.0+)
- **Architecture Pattern**: MVVM with `ObservableObject` and `@Published` properties.
- **Project Generation**: XcodeGen (`project.yml`).
- **Extensions**: `RecipeShareExtension` (`NSExtension` for iOS Share Sheet integration).
- **Storage**: `UserDefaults` with App Group container (`group.com.chefpocket.app`).

### 4.2 Android Implementation
- **Language**: Kotlin 1.9
- **Framework**: Jetpack Compose (1.6+) with Material Design 3 (M3).
- **Architecture Pattern**: MVVM with `AndroidViewModel`, `StateFlow`, and Compose `mutableStateOf`.
- **Target SDK**: Android 14 (API 34), Minimum SDK: Android 5.0 (API 21).
- **Networking**: OkHttp 4.12.0 with Coroutines and strict `network_security_config.xml`.
- **System Integration**: `ACTION_SEND` intent filter in `MainActivity` for system-wide share sheet extraction.
- **Storage**: `SharedPreferences` with atomic JSON serialization via `Gson`.
