import Foundation

// MARK: - App Constants
enum Constants {
    static let appName = "纸研社"
    static let appVersion = "1.0.0"

    // MARK: - AI Reducer Modes
    enum AIReduceMode: String, CaseIterable {
        case light = "轻度去痕"
        case deep = "深度重构"
        case academic = "学术拟合"

        var description: String {
            switch self {
            case .light: return "保留原文结构，轻微调整用词，保留80%原文"
            case .deep: return "大幅重构句式和段落，保留核心含义"
            case .academic: return "转化为学术文体，使用专业术语，风格贴近学术论文"
            }
        }

        var temperature: Double {
            switch self {
            case .light: return 0.75
            case .deep: return 0.85
            case .academic: return 0.80
            }
        }
    }

    // MARK: - Correction Categories
    enum CorrectionCategory: String, CaseIterable, Identifiable {
        case all = "全部纠错"
        case typo = "错别字"
        case grammar = "语法错误"
        case punctuation = "标点符号"
        case logic = "逻辑错误"
        case academic = "学术规范"
        case citation = "引用格式"
        case numbers = "数字规范"
        case structure = "结构问题"

        var id: String { rawValue }

        var systemPrompt: String {
            switch self {
            case .all:
                return "你是一位专业的中文学术论文编辑，精通学术写作规范。"
            case .typo:
                return "你是一位专业的中文编辑，专门识别和纠正错别字。"
            case .grammar:
                return "你是一位专业的中文语法专家，专门识别和纠正语法错误。"
            case .punctuation:
                return "你是一位专业的中文编辑，精通标点符号使用规范。"
            case .logic:
                return "你是一位专业的逻辑分析专家，专门识别和修正逻辑表达问题。"
            case .academic:
                return "你是一位专业的学术规范专家，精通学术写作规范和要求。"
            case .citation:
                return "你是一位专业的学术编辑，精通各类文献引用格式规范。"
            case .numbers:
                return "你是一位专业的编辑，精通学术论文中的数字使用规范。"
            case .structure:
                return "你是一位专业的学术论文结构专家，专门分析和优化论文结构。"
            }
        }
    }

    // MARK: - Polish Modes
    enum PolishMode: String, CaseIterable, Identifiable {
        case academic = "学术润色"
        case fluency = "流畅度提升"
        case professional = "专业表达"
        case concise = "简洁精炼"
        case comprehensive = "全面提升"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .academic: return "提升学术性，使用专业术语，增强逻辑性"
            case .fluency: return "改善语言流畅度，使表达更自然通顺"
            case .professional: return "使用更专业的行业术语和表达方式"
            case .concise: return "删除冗余，使表达更简洁有力"
            case .comprehensive: return "全面提升文本质量，兼顾准确性和可读性"
            }
        }
    }

    // MARK: - Defaults
    static let defaultMaxTokens = 4096
    static let defaultTemperature = 0.7
    static let sectionMaxTokens = 3000
    static let abstractMaxTokens = 1200
    static let outlineMaxTokens = 2000

    // MARK: - AI Pattern Detection
    static let aiPatterns: [String] = [
        "首先.*其次.*最后",
        "综上所述",
        "值得注意的是",
        "不可否认",
        "毋庸置疑",
        "总而言之",
        "由此可见",
        "显而易见",
        "众所周知",
        "不言而喻",
    ]

    static let flowConnectors: [String] = [
        "因此", "然而", "同时", "此外", "另外",
        "由此可见", "综上", "进一步说", "相较之下", "具体而言",
    ]

    static let conclusionMarkers: [String] = [
        "综上", "总体来看", "由此可见", "总之", "可以看出", "从上述分析可知",
    ]
}
