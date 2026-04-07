import Foundation

// MARK: - History Record
struct HistoryRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var pageID: String
    var pageLabel: String
    var action: String
    var inputText: String
    var outputText: String
    var metadata: [String: String]
    var createdAt: Date
    var isFavorite: Bool

    init(
        pageID: String,
        pageLabel: String,
        action: String,
        inputText: String = "",
        outputText: String = "",
        metadata: [String: String] = [:],
        isFavorite: Bool = false
    ) {
        self.pageID = pageID
        self.pageLabel = pageLabel
        self.action = action
        self.inputText = inputText
        self.outputText = outputText
        self.metadata = metadata
        self.isFavorite = isFavorite
        self.createdAt = Date()
    }

    var summary: String {
        let maxLen = 80
        let text = outputText.isEmpty ? inputText : outputText
        if text.count > maxLen {
            return String(text.prefix(maxLen)) + "..."
        }
        return text
    }

    var inputWordCount: Int { inputText.count }
    var outputWordCount: Int { outputText.count }
}

// MARK: - History Filter
enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case paperWrite = "论文写作"
    case aiReduce = "降AI检测"
    case plagiarism = "降查重率"
    case polish = "学术润色"
    case correction = "智能纠错"
    case favorites = "收藏"

    var id: String { rawValue }

    var pageID: String? {
        switch self {
        case .all, .favorites: return nil
        case .paperWrite: return "paper_write"
        case .aiReduce: return "ai_reduce"
        case .plagiarism: return "plagiarism"
        case .polish: return "polish"
        case .correction: return "correction"
        }
    }
}
