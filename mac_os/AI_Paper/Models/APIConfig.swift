import Foundation

// MARK: - API Provider
struct APIProvider: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var displayName: String
    var baseURL: String
    var apiKey: String
    var secretKey: String
    var model: String
    var apiFormat: APIFormat
    var providerType: String
    var isEnabled: Bool
    var temperature: Double
    var maxTokens: Int

    // Spark specific fields
    var appID: String
    var apiSecret: String

    init(
        id: String,
        name: String,
        displayName: String = "",
        baseURL: String = "",
        apiKey: String = "",
        secretKey: String = "",
        model: String = "",
        apiFormat: APIFormat = .openAI,
        providerType: String = "",
        isEnabled: Bool = true,
        temperature: Double = 0.7,
        maxTokens: Int = 4096,
        appID: String = "",
        apiSecret: String = ""
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName.isEmpty ? name : displayName
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.model = model
        self.apiFormat = apiFormat
        self.providerType = providerType
        self.isEnabled = isEnabled
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.appID = appID
        self.apiSecret = apiSecret
    }

    var isConfigured: Bool {
        switch apiFormat {
        case .baidu:
            return !apiKey.isEmpty && !secretKey.isEmpty
        case .spark:
            return !appID.isEmpty && !apiKey.isEmpty && !apiSecret.isEmpty
        default:
            return !apiKey.isEmpty
        }
    }
}

// MARK: - API Format
enum APIFormat: String, CaseIterable, Codable {
    case openAI = "openai"
    case claude = "claude"
    case baidu = "baidu"
    case spark = "spark"
    case tongyi = "tongyi"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI 兼容"
        case .claude: return "Claude (Anthropic)"
        case .baidu: return "百度文心"
        case .spark: return "讯飞星火"
        case .tongyi: return "通义千问"
        case .custom: return "自定义"
        }
    }
}

// MARK: - Preset Providers
extension APIProvider {
    static let presets: [APIProvider] = [
        APIProvider(
            id: "openai",
            name: "OpenAI",
            displayName: "OpenAI",
            baseURL: "https://api.openai.com/v1",
            model: "gpt-4o",
            apiFormat: .openAI,
            providerType: "openai"
        ),
        APIProvider(
            id: "deepseek",
            name: "DeepSeek",
            displayName: "DeepSeek",
            baseURL: "https://api.deepseek.com/v1",
            model: "deepseek-chat",
            apiFormat: .openAI,
            providerType: "deepseek"
        ),
        APIProvider(
            id: "claude",
            name: "Claude",
            displayName: "Claude (Anthropic)",
            baseURL: "https://api.anthropic.com",
            model: "claude-3-5-sonnet-20241022",
            apiFormat: .claude,
            providerType: "claude"
        ),
        APIProvider(
            id: "zhipu",
            name: "智谱AI",
            displayName: "智谱 GLM",
            baseURL: "https://open.bigmodel.cn/api/paas/v4",
            model: "glm-4-flash",
            apiFormat: .openAI,
            providerType: "zhipu"
        ),
        APIProvider(
            id: "tongyi",
            name: "通义千问",
            displayName: "通义千问",
            baseURL: "https://dashscope.aliyuncs.com/compatible-mode/v1",
            model: "qwen-plus",
            apiFormat: .openAI,
            providerType: "tongyi"
        ),
        APIProvider(
            id: "doubao",
            name: "豆包",
            displayName: "字节豆包",
            baseURL: "https://ark.cn-beijing.volces.com/api/v3",
            model: "doubao-pro-32k",
            apiFormat: .openAI,
            providerType: "doubao"
        ),
        APIProvider(
            id: "moonshot",
            name: "Moonshot",
            displayName: "月之暗面",
            baseURL: "https://api.moonshot.cn/v1",
            model: "moonshot-v1-32k",
            apiFormat: .openAI,
            providerType: "moonshot"
        ),
        APIProvider(
            id: "minimax",
            name: "MiniMax",
            displayName: "MiniMax",
            baseURL: "https://api.minimax.chat/v1",
            model: "abab6.5s-chat",
            apiFormat: .openAI,
            providerType: "minimax"
        ),
        APIProvider(
            id: "yi",
            name: "零一万物",
            displayName: "零一万物",
            baseURL: "https://api.lingyiwanwu.com/v1",
            model: "yi-large",
            apiFormat: .openAI,
            providerType: "yi"
        ),
        APIProvider(
            id: "siliconflow",
            name: "SiliconFlow",
            displayName: "硅基流动",
            baseURL: "https://api.siliconflow.cn/v1",
            model: "Qwen/Qwen2.5-72B-Instruct",
            apiFormat: .openAI,
            providerType: "siliconflow"
        ),
        APIProvider(
            id: "baichuan",
            name: "百川",
            displayName: "百川智能",
            baseURL: "https://api.baichuan-ai.com/v1",
            model: "Baichuan4",
            apiFormat: .openAI,
            providerType: "baichuan"
        ),
        APIProvider(
            id: "hunyuan",
            name: "腾讯混元",
            displayName: "腾讯混元",
            baseURL: "https://api.hunyuan.cloud.tencent.com/v1",
            model: "hunyuan-pro",
            apiFormat: .openAI,
            providerType: "hunyuan"
        ),
        APIProvider(
            id: "sensenova",
            name: "商汤",
            displayName: "商汤日日新",
            baseURL: "https://api.sensenova.cn/compatible-mode/v1",
            model: "SenseChat-5",
            apiFormat: .openAI,
            providerType: "sensenova"
        ),
        APIProvider(
            id: "stepfun",
            name: "阶跃星辰",
            displayName: "阶跃星辰",
            baseURL: "https://api.stepfun.com/v1",
            model: "step-2-16k",
            apiFormat: .openAI,
            providerType: "stepfun"
        ),
        APIProvider(
            id: "lingyi",
            name: "灵犀",
            displayName: "灵犀一诺",
            baseURL: "https://api.lingyiwanwu.com/v1",
            model: "yi-lightning",
            apiFormat: .openAI,
            providerType: "lingyi"
        ),
        APIProvider(
            id: "360ai",
            name: "360AI",
            displayName: "360 智脑",
            baseURL: "https://ai.360.cn/v1",
            model: "360gpt2-pro",
            apiFormat: .openAI,
            providerType: "360ai"
        ),
        APIProvider(
            id: "tiangong",
            name: "天工",
            displayName: "昆仑天工",
            baseURL: "https://sky-api.singularity-ai.com/saas/api/v4",
            model: "SkyChat-MegaVerse",
            apiFormat: .openAI,
            providerType: "tiangong"
        ),
        APIProvider(
            id: "baidu",
            name: "百度文心",
            displayName: "百度文心一言",
            baseURL: "",
            model: "ernie-4.0-8k",
            apiFormat: .baidu,
            providerType: "baidu"
        ),
        APIProvider(
            id: "spark",
            name: "讯飞星火",
            displayName: "科大讯飞",
            baseURL: "",
            model: "spark-4.0-ultra",
            apiFormat: .spark,
            providerType: "spark"
        ),
        APIProvider(
            id: "custom",
            name: "自定义",
            displayName: "自定义API",
            baseURL: "",
            model: "",
            apiFormat: .custom,
            providerType: "custom"
        ),
    ]
}
