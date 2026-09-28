import Foundation
import SwiftUI

private final class ImportRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

class AIService: ObservableObject {
    static let shared = AIService()
    @Published var isExtracting = false
    @Published var statusMessage = ""
    @Published var pendingImportURL: String?
    private let session = URLSession(configuration: .ephemeral, delegate: ImportRedirectPolicy(), delegateQueue: nil)
    // Retain legacy profile values for migration; imports never send provider keys.
    @AppStorage("chefpocket_gemini_api_key") var storedApiKey = ""
    var effectiveApiKey: String { storedApiKey.trimmingCharacters(in: .whitespacesAndNewlines) }
    func setApiKey(_ key: String) { storedApiKey = key.trimmingCharacters(in: .whitespacesAndNewlines) }

    @MainActor
    func extractRecipe(from urlString: String, userApiKey: String? = nil, sourceText: String = "") async throws -> Recipe {
        func failure(_ message: String, _ code: Int = 400) -> NSError {
            NSError(domain: "ChefPocket", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }
        guard !isExtracting else { throw failure("An import is already in progress.", 409) }
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let source = URL(string: clean), source.scheme == "https", let host = source.host,
              ["youtube.com", "www.youtube.com", "m.youtube.com", "youtu.be", "instagram.com", "www.instagram.com"].contains(host),
              source.user == nil, source.password == nil, source.port == nil else {
            throw failure("Enter an HTTPS YouTube or Instagram link.")
        }
        guard let endpoint = URL(string: ImportSettings.endpoint), endpoint.scheme == "https", endpoint.host != nil,
              endpoint.user == nil, endpoint.password == nil, !ImportSettings.token.isEmpty else {
            throw failure("Configure your import service and access token in the import settings.")
        }
        guard sourceText.count <= 30_000 else { throw failure("Paste up to 30,000 characters of recipe text.") }
        isExtracting = true
        statusMessage = "Reading recipe source…"
        defer { isExtracting = false; statusMessage = "" }
        var request = URLRequest(url: endpoint, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(ImportSettings.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["url": clean, "sourceText": sourceText])
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw failure("No response from import service.", 503) }
        guard (200...299).contains(http.statusCode) else {
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let message = (object?["error"] as? [String: Any])?["message"] as? String
            throw failure(message ?? "Import service returned an error. Try again later.", http.statusCode)
        }
        struct Envelope: Decodable { let recipe: Recipe }
        let recipe = try JSONDecoder().decode(Envelope.self, from: data).recipe
        guard !recipe.title.isEmpty, !recipe.ingredients.isEmpty, !recipe.instructions.isEmpty,
              recipe.servings > 0, recipe.ingredients.allSatisfy({ $0.amount.isFinite && $0.amount > 0 && !$0.name.isEmpty }) else {
            throw failure("The service returned an incomplete recipe.", 422)
        }
        return recipe
    }
}
