import Foundation
import SwiftUI
import Combine

struct KitchenSyncPayload: Codable {
    var version: Int = 1
    var userEmail: String
    var exportedDate: Date
    var customRecipes: [Recipe]
    var favoriteRecipeIds: [String]
    var groceries: [GroceryItem]
    var thali: ThaliPlan
}

class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: String = "Up to date"
    @Published var syncSummary: String = ""
    
    private let lastSyncKey = "chefpocket_last_cloud_sync_time"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        if let storedTime = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            self.lastSyncDate = storedTime
        }
    }
    
    /// Syncs local kitchen state to cloud store and merges remote updates
    func syncKitchenData(store: RecipeStore, auth: AuthManager) {
        guard let user = auth.currentUser, !user.email.isEmpty else {
            self.syncStatus = "Please log in to sync"
            return
        }
        
        self.isSyncing = true
        self.syncStatus = "Syncing with Google Account..."
        
        let accountEmail = user.email.lowercased()
        let cloudKey = "chefpocket_cloud_vault_\(accountEmail.hashValue)"
        
        // 1. Gather local data
        let localCustom = store.myRecipes
        let localFavorites = store.recipes.filter { $0.isFavorite }.map { $0.id.uuidString }
        let localGroceries = store.groceries
        let localThali = store.thali
        
        // 2. Load any existing remote data for this Google account from Ubiquitous / Suite store
        var remotePayload: KitchenSyncPayload? = nil
        let defaults = UserDefaults(suiteName: "group.com.chefpocket.recipes") ?? UserDefaults.standard
        if let remoteData = NSUbiquitousKeyValueStore.default.data(forKey: cloudKey) ?? defaults.data(forKey: cloudKey),
           let decoded = try? JSONDecoder().decode(KitchenSyncPayload.self, from: remoteData) {
            remotePayload = decoded
        }
        
        // 3. Merge recipes: remote + local deduplicated
        var mergedCustom = localCustom
        if let remote = remotePayload {
            for r in remote.customRecipes {
                if !mergedCustom.contains(where: { $0.id == r.id || $0.title.lowercased() == r.title.lowercased() }) {
                    mergedCustom.append(r)
                }
            }
        }
        
        // 4. Merge favorites
        var mergedFavorites = Set(localFavorites)
        if let remote = remotePayload {
            mergedFavorites.formUnion(remote.favoriteRecipeIds)
        }
        
        // 5. Merge groceries
        var mergedGroceries = localGroceries
        if let remote = remotePayload {
            for g in remote.groceries {
                if !mergedGroceries.contains(where: { $0.id == g.id || ($0.name.lowercased() == g.name.lowercased() && $0.category == g.category) }) {
                    mergedGroceries.append(g)
                }
            }
        }
        
        // 6. Create updated cloud payload
        let newPayload = KitchenSyncPayload(
            version: 1,
            userEmail: accountEmail,
            exportedDate: Date(),
            customRecipes: mergedCustom,
            favoriteRecipeIds: Array(mergedFavorites),
            groceries: mergedGroceries,
            thali: localThali
        )
        
        if let encoded = try? JSONEncoder().encode(newPayload) {
            // Save to both iCloud KVS (automatic cross-iOS-device sync) and local Suite defaults
            NSUbiquitousKeyValueStore.default.set(encoded, forKey: cloudKey)
            NSUbiquitousKeyValueStore.default.synchronize()
            defaults.set(encoded, forKey: cloudKey)
            UserDefaults.standard.set(encoded, forKey: cloudKey)
        }
        
        // 7. Update store with merged results
        DispatchQueue.main.async {
            // Update custom recipes
            for newR in mergedCustom {
                if !store.recipes.contains(where: { $0.id == newR.id }) {
                    store.recipes.insert(newR, at: 0)
                }
            }
            
            // Update favorites
            for i in 0..<store.recipes.count {
                if mergedFavorites.contains(store.recipes[i].id.uuidString) {
                    store.recipes[i].isFavorite = true
                }
            }
            
            store.groceries = mergedGroceries
            store.saveData()
            
            self.lastSyncDate = Date()
            UserDefaults.standard.set(self.lastSyncDate, forKey: self.lastSyncKey)
            self.isSyncing = false
            self.syncStatus = "Synced with Google Account"
            self.syncSummary = "\(mergedCustom.count) custom dishes • \(mergedFavorites.count) favorites • \(mergedGroceries.count) groceries"
        }
    }
    
    /// Export kitchen as a .chefpocket JSON backup file for AirDrop or local saving
    func exportBackup(store: RecipeStore, email: String) -> URL? {
        let payload = KitchenSyncPayload(
            version: 1,
            userEmail: email,
            exportedDate: Date(),
            customRecipes: store.myRecipes,
            favoriteRecipeIds: store.recipes.filter { $0.isFavorite }.map { $0.id.uuidString },
            groceries: store.groceries,
            thali: store.thali
        )
        
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("ChefPocket-Backup-\(Date().timeIntervalSince1970).chefpocket")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write backup: \(error)")
            return nil
        }
    }
    
    /// Import kitchen from a .chefpocket JSON backup file
    func importBackup(from url: URL, store: RecipeStore) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(KitchenSyncPayload.self, from: data) else {
            return false
        }
        
        for r in payload.customRecipes {
            store.addRecipe(r)
        }
        for favId in payload.favoriteRecipeIds {
            if let idx = store.recipes.firstIndex(where: { $0.id.uuidString == favId }) {
                store.recipes[idx].isFavorite = true
            }
        }
        for g in payload.groceries {
            if !store.groceries.contains(where: { $0.name.lowercased() == g.name.lowercased() }) {
                store.groceries.append(g)
            }
        }
        store.saveData()
        return true
    }
}
