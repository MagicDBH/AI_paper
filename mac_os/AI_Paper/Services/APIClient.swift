import Foundation
import Combine

// MARK: - API Response Error
enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case apiError(Int, String)
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "未配置API，请先在「API配置」中设置服务商和密钥"
        case .invalidURL: return "无效的API地址"
        case .networkError(let msg): return "网络错误：\(msg)"
        case .decodingError(let msg): return "响应解析失败：\(msg)"
        case .apiError(let code, let msg): return "API错误(\(code))：\(msg)"
        case .timeout: return "请求超时，请重试"
        case .cancelled: return "请求已取消"
        }
    }
}

// MARK: - API Client
@MainActor
final class APIClient: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var lastError: String?

    private var configManager: ConfigManager?
    private var currentTask: Task<Void, Never>?

    func configure(with configManager: ConfigManager) {
        self.configManager = configManager
    }

    // MARK: - Async Call
    func call(
        prompt: String,
        system: String = "",
        temperature: Double = 0.7,
        maxTokens: Int = 4096,
        usageContext: [String: String] = [:]
    ) async throws -> String {
        guard let configManager, let provider = configManager.activeProvider else {
            throw APIError.notConfigured
        }
        guard provider.isConfigured else {
            throw APIError.notConfigured
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        return try await performRequest(
            prompt: prompt,
            system: system,
            provider: provider,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }

    func cancelCurrent() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
    }

    // MARK: - Provider Dispatch
    private func performRequest(
        prompt: String,
        system: String,
        provider: APIProvider,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        switch provider.apiFormat {
        case .claude:
            return try await callClaudeAPI(
                prompt: prompt, system: system,
                provider: provider, temperature: temperature, maxTokens: maxTokens
            )
        case .baidu:
            return try await callBaiduAPI(
                prompt: prompt, system: system,
                provider: provider, temperature: temperature, maxTokens: maxTokens
            )
        default:
            return try await callOpenAICompatibleAPI(
                prompt: prompt, system: system,
                provider: provider, temperature: temperature, maxTokens: maxTokens
            )
        }
    }

    // MARK: - OpenAI Compatible
    private func callOpenAICompatibleAPI(
        prompt: String,
        system: String,
        provider: APIProvider,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        let baseURL = provider.baseURL.isEmpty
            ? "https://api.openai.com/v1"
            : provider.baseURL.trimmingCharacters(in: .init(charactersIn: "/"))

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw APIError.invalidURL
        }

        var messages: [[String: String]] = []
        if !system.isEmpty {
            messages.append(["role": "system", "content": system])
        }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = [
            "model": provider.model,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("无效的响应")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errMsg = extractErrorMessage(from: data) ?? "未知错误"
            throw APIError.apiError(httpResponse.statusCode, errMsg)
        }

        return try extractOpenAIContent(from: data)
    }

    // MARK: - Claude API
    private func callClaudeAPI(
        prompt: String,
        system: String,
        provider: APIProvider,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        let baseURL = provider.baseURL.isEmpty
            ? "https://api.anthropic.com"
            : provider.baseURL.trimmingCharacters(in: .init(charactersIn: "/"))

        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw APIError.invalidURL
        }

        var body: [String: Any] = [
            "model": provider.model,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "messages": [["role": "user", "content": prompt]]
        ]
        if !system.isEmpty {
            body["system"] = system
        }

        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue(provider.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("无效的响应")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errMsg = extractErrorMessage(from: data) ?? "未知错误"
            throw APIError.apiError(httpResponse.statusCode, errMsg)
        }

        return try extractClaudeContent(from: data)
    }

    // MARK: - Baidu API (simplified - uses ERNIE via compatible endpoint)
    private func callBaiduAPI(
        prompt: String,
        system: String,
        provider: APIProvider,
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        // Obtain access token first
        let tokenURL = "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=\(provider.apiKey)&client_secret=\(provider.secretKey)"
        guard let tokenEndpoint = URL(string: tokenURL) else {
            throw APIError.invalidURL
        }

        var tokenRequest = URLRequest(url: tokenEndpoint, timeoutInterval: 30)
        tokenRequest.httpMethod = "POST"

        let (tokenData, _) = try await URLSession.shared.data(for: tokenRequest)
        guard let tokenJSON = try? JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
              let accessToken = tokenJSON["access_token"] as? String else {
            throw APIError.decodingError("无法获取百度访问令牌")
        }

        let model = provider.model.isEmpty ? "ernie-4.0-8k" : provider.model
        let endpoint = "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/\(model)?access_token=\(accessToken)"

        guard let chatURL = URL(string: endpoint) else {
            throw APIError.invalidURL
        }

        var messages: [[String: String]] = []
        if !system.isEmpty {
            messages.append(["role": "system", "content": system])
        }
        messages.append(["role": "user", "content": prompt])

        let body: [String: Any] = ["messages": messages, "temperature": temperature]

        var chatRequest = URLRequest(url: chatURL, timeoutInterval: 120)
        chatRequest.httpMethod = "POST"
        chatRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        chatRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: chatRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.networkError("百度API请求失败")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String else {
            throw APIError.decodingError("无法解析百度API响应")
        }

        return result
    }

    // MARK: - Response Extraction Helpers
    private func extractOpenAIContent(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError("无法解析API响应内容")
        }
        return content
    }

    private func extractClaudeContent(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let first = contentArray.first,
              let text = first["text"] as? String else {
            throw APIError.decodingError("无法解析Claude响应内容")
        }
        return text
    }

    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? [String: Any] {
                return error["message"] as? String
            }
            return json["message"] as? String
        }
        return String(data: data, encoding: .utf8)
    }
}
