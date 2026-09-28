import Foundation
import Security
import SwiftUI

enum ImportSettings {
    static var endpoint: String {
        get { UserDefaults.standard.string(forKey: "chefpocket_import_endpoint") ?? "" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "chefpocket_import_endpoint") }
    }
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.chefpocket.import", kSecAttrAccount as String: "access-token"]
    }
    static var token: String {
        var q = query
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func saveToken(_ token: String) throws {
        let value = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { SecItemDelete(query as CFDictionary); return }
        let attributes: [String: Any] = [kSecValueData as String: Data(value.utf8), kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound { status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil) }
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Could not save import access securely."]) }
    }
}

struct ImportSettingsView: View {
    @State private var endpoint = ImportSettings.endpoint
    @State private var token = ImportSettings.token
    @State private var message = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Import service").font(.headline)
            TextField("https://your-service.example/v1/import", text: $endpoint)
                .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
            SecureField("Import access token", text: $token)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
            Button("Save import settings") {
                guard let url = URL(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines)), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil else {
                    message = "Enter an HTTPS import endpoint."; return
                }
                do { try ImportSettings.saveToken(token); ImportSettings.endpoint = endpoint; message = "Import settings saved." }
                catch { message = error.localizedDescription }
            }
            Text(message.isEmpty ? "Your app administrator supplies these settings. AI provider keys stay on the server." : message)
                .font(.caption).foregroundColor(.secondary)
        }.textFieldStyle(.roundedBorder).padding().background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
}
