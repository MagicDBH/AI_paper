import Foundation
import Combine

// MARK: - History Manager
final class HistoryManager: ObservableObject {
    @Published var records: [HistoryRecord] = []

    private let storageKey = "ai_paper_history"
    private let maxRecords = 500

    init() {
        loadHistory()
    }

    // MARK: - CRUD
    func addRecord(_ record: HistoryRecord) {
        records.insert(record, at: 0)
        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }
        saveHistory()
    }

    func deleteRecord(id: UUID) {
        records.removeAll { $0.id == id }
        saveHistory()
    }

    func deleteRecords(ids: Set<UUID>) {
        records.removeAll { ids.contains($0.id) }
        saveHistory()
    }

    func toggleFavorite(id: UUID) {
        if let index = records.firstIndex(where: { $0.id == id }) {
            records[index].isFavorite.toggle()
            saveHistory()
        }
    }

    func clearAll() {
        records = []
        saveHistory()
    }

    // MARK: - Query
    func filtered(by filter: HistoryFilter, searchText: String = "") -> [HistoryRecord] {
        var result = records

        switch filter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        default:
            if let pageID = filter.pageID {
                result = result.filter { $0.pageID == pageID }
            }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.inputText.localizedCaseInsensitiveContains(searchText) ||
                $0.outputText.localizedCaseInsensitiveContains(searchText) ||
                $0.action.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    // MARK: - Persistence
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryRecord].self, from: data) else {
            return
        }
        records = decoded
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
