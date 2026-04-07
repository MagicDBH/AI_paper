import Foundation

// MARK: - Usage Event
struct UsageEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date
    var pageID: String
    var sceneID: String
    var action: String
    var apiName: String
    var model: String
    var promptTokens: Int
    var completionTokens: Int
    var totalTokens: Int
    var estimatedCost: Double
    var currency: String
    var durationSeconds: Double

    init(
        pageID: String = "",
        sceneID: String = "",
        action: String = "",
        apiName: String = "",
        model: String = "",
        promptTokens: Int = 0,
        completionTokens: Int = 0,
        totalTokens: Int = 0,
        estimatedCost: Double = 0,
        currency: String = "USD",
        durationSeconds: Double = 0
    ) {
        self.timestamp = Date()
        self.pageID = pageID
        self.sceneID = sceneID
        self.action = action
        self.apiName = apiName
        self.model = model
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.estimatedCost = estimatedCost
        self.currency = currency
        self.durationSeconds = durationSeconds
    }
}

// MARK: - Usage Summary
struct UsageSummary {
    var totalCalls: Int
    var totalTokens: Int
    var totalCostUSD: Double
    var byPage: [String: PageUsage]

    struct PageUsage {
        var calls: Int
        var tokens: Int
        var cost: Double
    }

    static let empty = UsageSummary(totalCalls: 0, totalTokens: 0, totalCostUSD: 0, byPage: [:])
}
