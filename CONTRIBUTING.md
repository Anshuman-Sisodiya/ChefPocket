# Contributing to ChefPocket

Thank you for your interest in contributing to **ChefPocket**! We warmly welcome bug reports, feature suggestions, authentic recipes, documentation improvements, and pull requests across both our **iOS (SwiftUI)** and **Android (Jetpack Compose)** editions.

---

## 🛠️ Project Structure
- `ChefPocket/` & `RecipeShareExtension/`: iOS Swift codebase (`SwiftUI`, `XcodeGen`).
- `android/`: Android Kotlin codebase (`Jetpack Compose`, `Material 3`, `Gradle`).
- `docs/`: Technical guides, architecture, and security policies.
- `ChefPocket/RecipesData.json` & `android/app/src/main/assets/recipes_data.json`: Shared unified offline recipe database.

---

## 🤝 How to Contribute

### 1. Adding or Refining Authentic Recipes
Recipes must be updated in **both** `ChefPocket/RecipesData.json` and `android/app/src/main/assets/recipes_data.json` to maintain cross-platform parity.
Every recipe must adhere to the standard schema:
- **`name`**: Clear, authentic dish name.
- **`cuisine`**: One of `Indian Regional`, `Continental & Italian`, `Asian & Indo-Chinese`, `Mexican & Tex-Mex`, `Middle Eastern`, `Cafe & Bistro`, `Bakery & Breads`, `Drinks & Brews`.
- **`diet`**: `Veg` or `Non-Veg`.
- **`mealOccasion`**: `Breakfast`, `Lunch`, `Snacks`, or `Dinner`.
- **`category`**: `Bakery`, `Drinks & Shakes`, `Sabzi`, `Dal`, `High-Protein`, `Street Food`, `Rice & Biryani`, `Fusion`.
- **`calories`** and **`protein`**: Realistic nutritional estimates.
- **`cookerWhistles`**: Integer count (0 if not pressure cooked).
- **`ingredients`**: List of ingredient strings with precise quantities.
- **`steps`**: Clear, numbered step-by-step cooking instructions.

### 2. Reporting Bugs
- Check existing issues before opening a new one.
- Use the **Bug Report** template.
- Specify device platform (`iOS` or `Android`), OS version, device model, and reproduction steps.

### 3. Proposing Features
- Open an issue using the **Feature Request** template.
- Describe the use case and expected behavior.

### 4. Pull Requests
- Fork the repository and create a feature branch (`git checkout -b feature/AmazingFeature`).
- For **iOS**: Ensure code follows Swift API Design Guidelines and `xcodegen generate` succeeds.
- For **Android**: Ensure code follows Kotlin conventions and `./gradlew :app:assembleRelease` compiles cleanly.
- Commit with clear semantic commit messages (`feat:`, `fix:`, `docs:`, `perf:`).
- Open a Pull Request targeting the `main` branch.

---

## 📜 Code of Conduct
Please be kind, respectful, and collaborative in all discussions and pull requests.
