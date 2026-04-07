import Foundation
import Combine

// MARK: - Config Manager
final class ConfigManager: ObservableObject {
    @Published var providers: [APIProvider] = []
    @Published var activeAPIName: String = ""

    private let storageKey = "ai_paper_providers"
    private let activeKey = "ai_paper_active_api"

    var activeProvider: APIProvider? {
        providers.first { $0.id == activeAPIName && $0.isConfigured }
    }

    var hasActiveAPI: Bool {
        activeProvider != nil
    }

    var configuredProviders: [APIProvider] {
        providers.filter { $0.isConfigured }
    }

    init() {
        loadProviders()
    }

    // MARK: - Persistence
    func loadProviders() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([APIProvider].self, from: data) {
            providers = mergeWithPresets(saved)
        } else {
            providers = APIProvider.presets
        }
        activeAPIName = UserDefaults.standard.string(forKey: activeKey) ?? ""
    }

    func saveProviders() {
        if let data = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        UserDefaults.standard.set(activeAPIName, forKey: activeKey)
    }

    func setActive(_ providerID: String) {
        activeAPIName = providerID
        saveProviders()
    }

    func updateProvider(_ provider: APIProvider) {
        if let index = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[index] = provider
        } else {
            providers.append(provider)
        }
        saveProviders()
    }

    func resetToDefaults() {
        providers = APIProvider.presets
        activeAPIName = ""
        saveProviders()
    }

    // MARK: - Merge presets with saved
    private func mergeWithPresets(_ saved: [APIProvider]) -> [APIProvider] {
        var result = APIProvider.presets
        for savedProvider in saved {
            if let index = result.firstIndex(where: { $0.id == savedProvider.id }) {
                result[index] = savedProvider
            } else {
                result.append(savedProvider)
            }
        }
        return result
    }
}
