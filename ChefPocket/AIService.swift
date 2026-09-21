import Foundation
import SwiftUI

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
    
    // Persistent API Key storage across app
    @AppStorage("chefpocket_gemini_api_key") var storedApiKey: String = ""
    
    var effectiveApiKey: String {
        storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func setApiKey(_ key: String) {
        let clean = key.trimmingCharacters(in: .whitespacesAndNewlines)
        storedApiKey = clean
        UserDefaults.standard.set(clean, forKey: "chefpocket_gemini_api_key")
    }
    
    private let cooldownSeconds: TimeInterval = 2.0
    private let dailyLimit = 50
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
    
    var hasValidApiKey: Bool {
        !storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            self.statusMessage = "Analyzing video link & captions..."
        }
        
        defer {
            Task { @MainActor in
                self.isExtracting = false
                self.statusMessage = ""
            }
        }
        
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty else {
            throw NSError(domain: "ChefPocket", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid video link."])
        }
        
        // 1. Resolve API key
        var activeApiKey = (userApiKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? userApiKey!.trimmingCharacters(in: .whitespacesAndNewlines) : storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if API key is present
        guard !activeApiKey.isEmpty else {
            throw NSError(domain: "ChefPocket", code: 401, userInfo: [NSLocalizedDescriptionKey: "Gemini API Key missing. Please configure your free API Key from aistudio.google.com to extract precise recipes."])
        }
        
        // 2. Fetch video metadata (Title + Description/Caption)
        let (extractedTitle, extractedDescription, isShort) = await fetchVideoMetadataAndCaption(cleanURL)
        
        // 3. Check cooldown
        if let lastReq = UserDefaults.standard.object(forKey: lastRequestTimeKey) as? Date,
           Date().timeIntervalSince(lastReq) < cooldownSeconds {
            try? await Task.sleep(nanoseconds: UInt64(cooldownSeconds * 1_000_000_000))
        }
        
        await MainActor.run {
            self.statusMessage = "Extracting ingredients & whistle count with Gemini AI... ✨"
        }
        
        // 4. Call Gemini REST API
        let aiRecipe = try await callGeminiAPI(
            videoTitle: extractedTitle,
            videoDescription: extractedDescription,
            videoURL: cleanURL,
            apiKey: activeApiKey
        )
        
        UserDefaults.standard.set(Date(), forKey: lastRequestTimeKey)
        incrementDailyCount()
        return aiRecipe
    }
    
    // MARK: - Gemini REST API Caller with Multi-Model Fallback & Auto-Discovery
    private func callGeminiAPI(videoTitle: String, videoDescription: String, videoURL: String, apiKey: String) async throws -> Recipe {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Priority order of modern Gemini models
        let candidateModels = [
            "gemini-2.0-flash",
            "gemini-2.5-flash",
            "gemini-1.5-flash-latest",
            "gemini-1.5-flash",
            "gemini-2.0-flash-lite",
            "gemini-1.5-pro",
            "gemini-pro"
        ]
        
        var lastError: Error? = nil
        
        // 1. Try prioritized list of known models
        for model in candidateModels {
            do {
                return try await executeGeminiRequest(
                    model: model,
                    videoTitle: videoTitle,
                    videoDescription: videoDescription,
                    videoURL: videoURL,
                    apiKey: cleanKey
                )
            } catch let err as NSError where err.code == 404 {
                print("Gemini model \(model) returned 404. Trying next model...")
                lastError = err
                continue
            } catch {
                // If error is 400 (bad key), 429 (quota), etc., do not retry other models, return clear error
                throw error
            }
        }
        
        // 2. If all preconfigured models returned 404, query available models dynamically
        if let dynamicModel = await fetchFirstAvailableGenerateContentModel(apiKey: cleanKey) {
            print("Found dynamic model from Google: \(dynamicModel)")
            return try await executeGeminiRequest(
                model: dynamicModel,
                videoTitle: videoTitle,
                videoDescription: videoDescription,
                videoURL: videoURL,
                apiKey: cleanKey
            )
        }
        
        throw lastError ?? NSError(domain: "ChefPocket", code: 404, userInfo: [NSLocalizedDescriptionKey: "No compatible Gemini model found for this key. Please verify model permissions in Google AI Studio."])
    }
    
    private func fetchFirstAvailableGenerateContentModel(apiKey: String) async -> String? {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else { return nil }
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return nil }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else { return nil }
        
        for m in models {
            if let name = m["name"] as? String,
               let methods = m["supportedGenerationMethods"] as? [String],
               methods.contains("generateContent") {
                let clean = name.replacingOccurrences(of: "models/", with: "")
                if clean.contains("flash") || clean.contains("gemini") {
                    return clean
                }
            }
        }
        return nil
    }
    
    private func executeGeminiRequest(model: String, videoTitle: String, videoDescription: String, videoURL: String, apiKey: String) async throws -> Recipe {
        guard let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw NSError(domain: "ChefPocket", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini endpoint configuration."])
        }
        
        let promptText = """
        You are an elite Michelin-trained executive chef assistant. Analyze this video metadata and extract the exact culinary recipe.
        
        Video Title: "\(videoTitle)"
        Video Caption / Description: "\(videoDescription)"
        Video URL: "\(videoURL)"
        
        CRITICAL RULES:
        1. Identify the exact dish name from the title/caption.
        2. Extract authentic ingredients with precise metric amounts (grams, ml, tbsp, tsp, piece).
        3. If it is an Indian pressure cooker dish (dal, rajma, chana, biryani, mutton, etc.), determine the exact cooker whistle count (e.g. 2, 3, 4 whistles). If not a pressure cooker recipe, set whistleCount to null.
        4. Accurately calculate calories and protein grams per serving.
        5. Provide numbered, professional cooking instructions with specific heat levels and cooking cues. Never include YouTube URLs or 'extracted from' lines in instructions.
        6. Determine Diet ("Veg" or "Non-Veg").
        7. Determine Cuisine ("Indian Regional", "Continental & Italian", "Asian & Indo-Chinese", "Mexican & Tex-Mex", "Middle Eastern", "Cafe & Bistro", "Bakery & Breads", or "Drinks & Brews").
        8. Determine Category ("Sabzi", "Dal", "High-Protein", "Breakfast", "Street Food", "Rice & Biryani", "Bakery", "Drinks & Shakes", or "Fusion").
        
        STRICT REQUIREMENT: Respond ONLY with a valid JSON object (no markdown quotes, no explanation, no text before or after):
        {
          "title": "Dish Name",
          "category": "Sabzi",
          "cuisine": "Indian Regional",
          "diet": "Veg",
          "mealTypes": ["Lunch", "Dinner"],
          "prepTimeMinutes": 25,
          "calories": 380,
          "proteinGrams": 24,
          "whistleCount": 3,
          "tags": ["Authentic", "Video Import", "High-Protein"],
          "ingredients": [
            {"name": "Paneer / Chicken", "amount": 250, "unit": "g"},
            {"name": "Desi Ghee", "amount": 2, "unit": "tbsp"},
            {"name": "Cumin Seeds", "amount": 1, "unit": "tsp"}
          ],
          "instructions": [
            "Heat ghee in a pan on medium heat and splutter cumin seeds.",
            "Add aromatics, sauté until golden brown, and add spices.",
            "Cover and cook until tender. Serve hot."
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
                "temperature": 0.2
            ]
        ]
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResp = response as? HTTPURLResponse else {
            throw NSError(domain: "ChefPocket", code: 500, userInfo: [NSLocalizedDescriptionKey: "No response received from Gemini server."])
        }
        
        // Handle API errors gracefully with user-friendly messages
        if !(200...299).contains(httpResp.statusCode) {
            var errMsg = "Gemini API Error (\(httpResp.statusCode))"
            if let errJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errObj = errJSON["error"] as? [String: Any],
               let msg = errObj["message"] as? String {
                if msg.contains("API_KEY_INVALID") || msg.contains("API key not valid") {
                    errMsg = "Invalid Gemini API Key. Please verify your key at aistudio.google.com."
                } else if msg.contains("RESOURCE_EXHAUSTED") || httpResp.statusCode == 429 {
                    errMsg = "Gemini quota exceeded. Please wait a moment or use a different key."
                } else {
                    errMsg = "\(msg) (Status: \(httpResp.statusCode))"
                }
            }
            throw NSError(domain: "GeminiAPI", code: httpResp.statusCode, userInfo: [NSLocalizedDescriptionKey: errMsg])
        }
        
        let geminiResp = try JSONDecoder().decode(GeminiGenerationResponse.self, from: data)
        guard let rawJSONText = geminiResp.candidates?.first?.content?.parts?.first?.text else {
            throw NSError(domain: "ChefPocket", code: 422, userInfo: [NSLocalizedDescriptionKey: "Could not read recipe structure from AI response."])
        }
        
        // Extract substring between first '{' and last '}'
        var cleaned = rawJSONText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }
        
        guard let jsonData = cleaned.data(using: .utf8),
              let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "ChefPocket", code: 422, userInfo: [NSLocalizedDescriptionKey: "Failed to parse structured recipe JSON from AI."])
        }
        
        // Parse fields
        let title = dict["title"] as? String ?? (videoTitle.isEmpty ? "AI Extracted Dish" : videoTitle)
        
        let catRaw = dict["category"] as? String ?? "Sabzi"
        let category = RecipeCategory(rawValue: catRaw) ?? .sabzi
        
        let cuRaw = dict["cuisine"] as? String ?? "Indian Regional"
        let cuisine = Cuisine(rawValue: cuRaw) ?? .indian
        
        let dietRaw = dict["diet"] as? String ?? "Veg"
        let diet = DietType(rawValue: dietRaw) ?? .veg
        
        var mealTypes: [MealType] = []
        if let mealsArr = dict["mealTypes"] as? [String] {
            mealTypes = mealsArr.compactMap { MealType(rawValue: $0) }
        }
        if mealTypes.isEmpty { mealTypes = [.lunch, .dinner] }
        
        let prep = dict["prepTimeMinutes"] as? Int ?? 25
        let cals = dict["calories"] as? Int ?? 380
        let protein = dict["proteinGrams"] as? Int ?? 22
        let whistles = dict["whistleCount"] as? Int
        let tags = dict["tags"] as? [String] ?? ["AI Extracted", "Chef Verified"]
        
        var ingredients: [Ingredient] = []
        if let ingArr = dict["ingredients"] as? [[String: Any]] {
            for item in ingArr {
                let name = item["name"] as? String ?? "Ingredient"
                let amt = (item["amount"] as? NSNumber)?.doubleValue ?? 1.0
                let unit = item["unit"] as? String ?? "portion"
                ingredients.append(Ingredient(name: name, amount: amt, unit: unit))
            }
        }
        if ingredients.isEmpty {
            ingredients = [Ingredient(name: "Main ingredient", amount: 250, unit: "g")]
        }
        
        var rawInstructions = dict["instructions"] as? [String] ?? [
            "Prepare and chop all fresh ingredients as listed.",
            "Heat pan or pressure cooker on medium heat, sauté aromatics and spices.",
            "Add main ingredients and simmer until cooked thoroughly.",
            "Finish with fresh garnish and serve hot."
        ]
        let instructions = rawInstructions.filter {
            let l = $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return !l.starts(with: "extracted from") && !l.starts(with: "source:") && !l.contains("http")
        }
        
        return Recipe(
            title: title,
            category: category,
            cuisine: cuisine,
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
    
    // MARK: - Video Metadata & Caption Scraper
    private func fetchVideoMetadataAndCaption(_ urlString: String) async -> (title: String, description: String, isShort: Bool) {
        let isShort = urlString.contains("shorts") || urlString.contains("youtube") || urlString.contains("youtu.be")
        var title = ""
        var description = ""
        
        // 1. Normalize YouTube URL to canonical watch link for metadata fetching
        var targetURL = urlString
        if urlString.contains("shorts/") {
            let parts = urlString.components(separatedBy: "shorts/")
            if let id = parts.last?.split(separator: "?").first?.split(separator: "/").first {
                targetURL = "https://www.youtube.com/watch?v=\(id)"
            }
        } else if urlString.contains("youtu.be/") {
            let parts = urlString.components(separatedBy: "youtu.be/")
            if let id = parts.last?.split(separator: "?").first?.split(separator: "/").first {
                targetURL = "https://www.youtube.com/watch?v=\(id)"
            }
        }
        
        // 2. Query oEmbed with iOS Safari User-Agent
        if let encoded = targetURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let oEmbedURL = URL(string: "https://www.youtube.com/oembed?url=\(encoded)&format=json") {
            var req = URLRequest(url: oEmbedURL)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            if let (data, _) = try? await URLSession.shared.data(for: req),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fetchedTitle = json["title"] as? String, !fetchedTitle.isEmpty {
                title = fetchedTitle
            }
        }
        
        // 3. Query Webpage OpenGraph tags (og:title, og:description) to extract creator caption
        if let pageURL = URL(string: targetURL) {
            var req = URLRequest(url: pageURL)
            req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            if let (data, _) = try? await URLSession.shared.data(for: req),
               let html = String(data: data, encoding: .utf8) {
                // Extract og:title if empty
                if title.isEmpty {
                    if let range = html.range(of: "<meta property=\"og:title\" content=\"") {
                        let after = html[range.upperBound...]
                        if let end = after.firstIndex(of: "\"") {
                            title = String(after[..<end])
                        }
                    }
                }
                // Extract og:description (often has ingredients & recipe steps!)
                if let range = html.range(of: "<meta property=\"og:description\" content=\"") {
                    let after = html[range.upperBound...]
                    if let end = after.firstIndex(of: "\"") {
                        description = String(after[..<end])
                    }
                } else if let range = html.range(of: "<meta name=\"description\" content=\"") {
                    let after = html[range.upperBound...]
                    if let end = after.firstIndex(of: "\"") {
                        description = String(after[..<end])
                    }
                }
            }
        }
        
        if title.isEmpty {
            title = isShort ? "Chef Special YouTube Dish" : "Trending Video Dish"
        }
        
        return (title, description, isShort)
    }
}
