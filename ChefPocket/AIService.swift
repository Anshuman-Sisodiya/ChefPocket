import Foundation

struct GeminiGenerationResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String?
            }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isExtracting: Bool = false
    @Published var statusMessage: String = ""
    
    private let cooldownSeconds: TimeInterval = 5.0
    private let dailyLimit = 25
    private let lastRequestTimeKey = "chefpocket_ai_last_req_time"
    private let dailyCountKey = "chefpocket_ai_daily_count"
    private let dailyDateKey = "chefpocket_ai_daily_date"
    
    var dailyUsageCount: Int {
        checkDailyReset()
        return UserDefaults.standard.integer(forKey: dailyCountKey)
    }
    
    var remainingDailyRequests: Int {
        max(0, dailyLimit - dailyUsageCount)
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let savedDate = UserDefaults.standard.object(forKey: dailyDateKey) as? Date {
            if !calendar.isDate(savedDate, inSameDayAs: today) {
                UserDefaults.standard.set(0, forKey: dailyCountKey)
                UserDefaults.standard.set(today, forKey: dailyDateKey)
            }
        } else {
            UserDefaults.standard.set(today, forKey: dailyDateKey)
            UserDefaults.standard.set(0, forKey: dailyCountKey)
        }
    }
    
    private func incrementDailyCount() {
        checkDailyReset()
        let count = UserDefaults.standard.integer(forKey: dailyCountKey)
        UserDefaults.standard.set(count + 1, forKey: dailyCountKey)
    }
    
    // MARK: - Main Extraction Pipeline
    func extractRecipe(from urlString: String, userApiKey: String? = nil) async throws -> Recipe {
        await MainActor.run {
            self.isExtracting = true
            self.statusMessage = "Analyzing video link..."
        }
        
        defer {
            Task { @MainActor in
                self.isExtracting = false
                self.statusMessage = ""
            }
        }
        
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Fetch metadata (Title, Author) via YouTube oEmbed or URL hints
        let (extractedTitle, isShort) = await fetchVideoMetadata(clean)
        
        // 2. Check if we have an API Key & Quota for Gemini
        checkDailyReset()
        let apiKey = (userApiKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? userApiKey! : ""
        
        if !apiKey.isEmpty && dailyUsageCount < dailyLimit {
            // Check cooldown
            if let lastReq = UserDefaults.standard.object(forKey: lastRequestTimeKey) as? Date,
               Date().timeIntervalSince(lastReq) < cooldownSeconds {
                try? await Task.sleep(nanoseconds: UInt64(cooldownSeconds * 1_000_000_000))
            }
            
            await MainActor.run {
                self.statusMessage = "Cooking recipe with Gemini AI... ✨"
            }
            
            do {
                let aiRecipe = try await callGeminiAPI(videoTitle: extractedTitle, videoURL: clean, apiKey: apiKey)
                UserDefaults.standard.set(Date(), forKey: lastRequestTimeKey)
                incrementDailyCount()
                return aiRecipe
            } catch {
                print("Gemini API call failed, falling back to smart heuristic: \(error.localizedDescription)")
            }
        }
        
        // 3. Fallback Heuristic Extractor
        await MainActor.run {
            self.statusMessage = "Structuring recipe ingredients & steps..."
        }
        return smartFallbackExtractor(title: extractedTitle, url: clean, isShort: isShort)
    }
    
    // MARK: - Gemini REST API Caller
    private func callGeminiAPI(videoTitle: String, videoURL: String, apiKey: String) async throws -> Recipe {
        guard let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let promptText = """
        You are a Michelin-grade executive chef assistant. Analyze this recipe video:
        Title: "\(videoTitle)"
        URL: "\(videoURL)"

        Generate a complete, authentic, structured recipe based on the dish name.
        Strictly respond with ONLY valid JSON (no markdown ticks, no commentary) adhering to this schema:
        {
          "title": "Clean, appetizing dish name",
          "category": "Sabzi" or "Dal" or "High-Protein" or "Breakfast" or "Street Food" or "Rice & Biryani" or "Fusion",
          "diet": "Veg" or "Non-Veg",
          "mealTypes": ["Breakfast" or "Lunch" or "Snacks" or "Dinner"],
          "prepTimeMinutes": 25,
          "calories": 420,
          "proteinGrams": 28,
          "whistleCount": 3 (or null if not pressure cooked),
          "tags": ["Quick", "Authentic", "Video Import"],
          "ingredients": [
            {"name": "Ingredient Name", "amount": 200, "unit": "g"},
            {"name": "Spice / Oil", "amount": 1, "unit": "tsp"}
          ],
          "instructions": [
            "Clear step 1 with heat level and visual cue.",
            "Clear step 2...",
            "Final finishing step with garnish."
          ]
        }
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": promptText]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "response_mime_type": "application/json"
            ]
        ]
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let geminiResp = try JSONDecoder().decode(GeminiGenerationResponse.self, from: data)
        guard let rawJSONText = geminiResp.candidates?.first?.content?.parts?.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        // Clean out possible markdown fences
        let cleaned = rawJSONText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleaned.data(using: .utf8),
              let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // Parse fields
        let title = dict["title"] as? String ?? videoTitle
        let catRaw = dict["category"] as? String ?? "Sabzi"
        let category = RecipeCategory(rawValue: catRaw) ?? .sabzi
        let dietRaw = dict["diet"] as? String ?? "Veg"
        let diet = DietType(rawValue: dietRaw) ?? .veg
        
        var mealTypes: [MealType] = []
        if let mealsArr = dict["mealTypes"] as? [String] {
            mealTypes = mealsArr.compactMap { MealType(rawValue: $0) }
        }
        if mealTypes.isEmpty { mealTypes = [.lunch, .dinner] }
        
        let prep = dict["prepTimeMinutes"] as? Int ?? 20
        let cals = dict["calories"] as? Int ?? 380
        let protein = dict["proteinGrams"] as? Int ?? 22
        let whistles = dict["whistleCount"] as? Int
        let tags = dict["tags"] as? [String] ?? ["AI Extracted", "Video Import"]
        
        var ingredients: [Ingredient] = []
        if let ingArr = dict["ingredients"] as? [[String: Any]] {
            for item in ingArr {
                let name = item["name"] as? String ?? "Ingredient"
                let amt = item["amount"] as? Double ?? 1.0
                let unit = item["unit"] as? String ?? "portion"
                ingredients.append(Ingredient(name: name, amount: amt, unit: unit))
            }
        }
        if ingredients.isEmpty {
            ingredients = [Ingredient(name: "Main ingredient", amount: 250, unit: "g")]
        }
        
        var rawInstructions = dict["instructions"] as? [String] ?? [
            "Prepare and chop all ingredients as listed.",
            "Heat pan on medium flame, sauté aromatics and spices.",
            "Add main ingredients and simmer until cooked through.",
            "Finish with fresh garnish and serve hot."
        ]
        let instructions = rawInstructions.filter {
            let l = $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return !l.starts(with: "extracted from") && !l.starts(with: "source:") && !l.contains("http")
        }
        
        return Recipe(
            title: title,
            category: category,
            diet: diet,
            mealTypes: mealTypes,
            isUserCreated: true,
            tags: tags,
            sourceURL: videoURL,
            prepTimeMinutes: prep,
            calories: cals,
            proteinGrams: protein,
            whistleCount: whistles,
            ingredients: ingredients,
            instructions: instructions
        )
    }
    
    // MARK: - Video Metadata (oEmbed)
    private func fetchVideoMetadata(_ urlString: String) async -> (title: String, isShort: Bool) {
        let isShort = urlString.contains("shorts") || urlString.contains("youtube") || urlString.contains("youtu.be")
        var title = isShort ? "Imported YouTube Recipe" : "Imported Video Recipe"
        
        if isShort, let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let oEmbedURL = URL(string: "https://www.youtube.com/oembed?url=\(encoded)&format=json") {
            if let (data, _) = try? await URLSession.shared.data(from: oEmbedURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fetchedTitle = json["title"] as? String, !fetchedTitle.isEmpty {
                title = fetchedTitle
            }
        }
        
        return (title, isShort)
    }
    
    // MARK: - Smart Heuristic Fallback Extractor
    private func smartFallbackExtractor(title: String, url: String, isShort: Bool) -> Recipe {
        let lower = title.lowercased()
        
        // Detect diet
        let isNonVeg = lower.contains("chicken") || lower.contains("mutton") || lower.contains("egg") ||
            lower.contains("fish") || lower.contains("prawn") || lower.contains("keema") || lower.contains("meat")
        let diet: DietType = isNonVeg ? .nonVeg : .veg
        
        // Detect category & whistle count
        var category: RecipeCategory = .sabzi
        var whistles: Int? = nil
        var prepTime = 20
        var calories = 380
        var protein = isNonVeg ? 32 : 18
        var mealTypes: [MealType] = [.lunch, .dinner]
        
        if lower.contains("dal") || lower.contains("lentil") || lower.contains("chana") || lower.contains("rajma") {
            category = .dal
            whistles = 3
            protein = 22
        } else if lower.contains("biryani") || lower.contains("pulao") || lower.contains("rice") {
            category = .rice
            whistles = 2
            calories = 480
        } else if lower.contains("chilla") || lower.contains("dosa") || lower.contains("idli") || lower.contains("poha") || lower.contains("omelette") {
            category = .breakfast
            mealTypes = [.breakfast]
            prepTime = 15
        } else if lower.contains("chaat") || lower.contains("pav bhaji") || lower.contains("samosa") || lower.contains("roll") {
            category = .streetFood
            mealTypes = [.snacks]
            calories = 420
        } else if isNonVeg || lower.contains("paneer") || lower.contains("soya") || lower.contains("tofu") {
            category = .highProtein
            protein = isNonVeg ? 36 : 28
        }
        
        return Recipe(
            title: title,
            category: category,
            diet: diet,
            mealTypes: mealTypes,
            isUserCreated: true,
            tags: ["Video Import", "Trending", diet.rawValue],
            sourceURL: url,
            prepTimeMinutes: prepTime,
            calories: calories,
            proteinGrams: protein,
            whistleCount: whistles,
            ingredients: [
                Ingredient(name: isNonVeg ? "Main Protein (Chicken / Mutton / Egg)" : "Main Ingredient (Paneer / Dal / Veggies)", amount: 250, unit: "g"),
                Ingredient(name: "Finely Chopped Onion", amount: 1, unit: "medium"),
                Ingredient(name: "Tomatoes Pureed", amount: 2, unit: "medium"),
                Ingredient(name: "Ginger Garlic Paste", amount: 1, unit: "tbsp"),
                Ingredient(name: "Desi Ghee / Oil", amount: 1, unit: "tbsp"),
                Ingredient(name: "Garam Masala & Turmeric", amount: 1, unit: "tsp"),
                Ingredient(name: "Fresh Coriander for Garnish", amount: 1, unit: "handful")
            ],
            instructions: [
                "Heat ghee or oil in a heavy-bottomed pan and sauté ginger garlic paste with cumin seeds until fragrant.",
                "Add chopped onions and fry on medium-high heat until golden brown.",
                "Add tomato puree, turmeric, red chilli, and garam masala; bhunao (cook) until the oil releases from the sides.",
                "Add the main protein/vegetables with half a cup of warm water.",
                whistles != nil ? "Pressure cook on medium heat for \(whistles!) whistles. Allow steam to release naturally." : "Cover and simmer on low-medium flame for \(prepTime - 10) minutes until tender.",
                "Finish with a pinch of roasted kasuri methi and fresh coriander. Serve piping hot!"
            ]
        )
    }
}
