import Foundation
import SwiftUI
import UIKit

// MARK: - GitHub Release Models
struct GitHubRelease: Codable {
    let tagName: String
    let name: String?
    let body: String?
    let publishedAt: String?
    let htmlUrl: String?
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
        case assets
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
    let size: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

// MARK: - Update Manager
class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    @Published var isChecking: Bool = false
    @Published var isUpdateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var currentVersion: String = ""
    @Published var releaseTitle: String = ""
    @Published var releaseNotes: String = ""
    @Published var ipaDownloadURL: URL? = nil
    @Published var htmlReleaseURL: URL? = nil
    @Published var errorMessage: String? = nil
    @Published var lastCheckedDate: Date? = nil
    @Published var showingUpdateModal: Bool = false
    
    private let repoAPIURL = "https://api.github.com/repos/Anshuman-Sisodiya/ChefPocket/releases/latest"
    private let lastCheckedKey = "chefpocket_last_update_check_timestamp"
    
    init() {
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.3.3"
        if let timestamp = UserDefaults.standard.object(forKey: lastCheckedKey) as? Date {
            self.lastCheckedDate = timestamp
        }
    }
    
    /// Checks GitHub Releases API for new builds
    func checkForUpdates(silent: Bool = false) {
        guard !isChecking else { return }
        
        isChecking = true
        errorMessage = nil
        
        guard let url = URL(string: repoAPIURL) else {
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("ChefPocket-iOS/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isChecking = false
                self.lastCheckedDate = Date()
                UserDefaults.standard.set(self.lastCheckedDate, forKey: self.lastCheckedKey)
                
                if let error = error {
                    if !silent {
                        self.errorMessage = "Could not reach update server: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let data = data else {
                    if !silent {
                        self.errorMessage = "No response from update server."
                    }
                    return
                }
                
                do {
                    let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                    self.processRelease(release, silent: silent)
                } catch {
                    if !silent {
                        self.errorMessage = "Unable to parse update details."
                    }
                }
            }
        }.resume()
    }
    
    private func processRelease(_ release: GitHubRelease, silent: Bool) {
        let tag = release.tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.latestVersion = tag
        self.releaseTitle = release.name ?? "ChefPocket v\(tag)"
        self.releaseNotes = release.body ?? "General improvements and fixes."
        
        if let html = release.htmlUrl, let u = URL(string: html) {
            self.htmlReleaseURL = u
        }
        
        // Find IPA asset
        if let ipaAsset = release.assets.first(where: { $0.name.hasSuffix(".ipa") }) {
            self.ipaDownloadURL = URL(string: ipaAsset.browserDownloadUrl)
        } else if let firstAsset = release.assets.first {
            self.ipaDownloadURL = URL(string: firstAsset.browserDownloadUrl)
        }
        
        let hasNewerVersion = isVersionNewer(tag, than: currentVersion)
        self.isUpdateAvailable = hasNewerVersion
        
        if hasNewerVersion {
            self.showingUpdateModal = true
        } else if !silent {
            self.errorMessage = "You are already on the latest build (v\(currentVersion))."
        }
    }
    
    /// Semantic version comparator
    private func isVersionNewer(_ remote: String, than current: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(remoteParts.count, currentParts.count)
        for i in 0..<maxLength {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }
    
    /// 1-Tap AltStore Install scheme
    func installWithAltStore() {
        guard let downloadURL = ipaDownloadURL?.absoluteString,
              let encoded = downloadURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let altStoreURL = URL(string: "altstore://install?url=\(encoded)") else {
            openDirectDownload()
            return
        }
        
        if UIApplication.shared.canOpenURL(altStoreURL) {
            UIApplication.shared.open(altStoreURL, options: [:], completionHandler: nil)
        } else {
            openDirectDownload()
        }
    }
    
    /// Opens direct GitHub IPA asset download in Safari
    func openDirectDownload() {
        if let url = ipaDownloadURL {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else if let html = htmlReleaseURL {
            UIApplication.shared.open(html, options: [:], completionHandler: nil)
        }
    }
}
