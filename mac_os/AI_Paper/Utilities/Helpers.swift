import Foundation
import SwiftUI

// MARK: - Prompt Builder
enum PromptBuilder {

    // MARK: - Paper Writing Prompts
    static func outlinePrompt(topic: String, style: String, referenceStyle: String, subject: String) -> (system: String, prompt: String) {
        let system = "你是一位专业的学术论文写作助手，精通学术写作规范和结构。请使用规范的中文学术语言。"
        let subjectClause = subject.isEmpty ? "" : "，学科领域为\(subject)"
        let prompt = """
        请为以下主题生成一份详细的\(style)大纲：

        论文主题：\(topic)\(subjectClause)
        参考文献格式：\(referenceStyle)

        要求：
        1. 大纲结构清晰，层次分明（分章节和子节）
        2. 符合学术论文写作规范
        3. 包含摘要、引言、主体章节、结论、参考文献等部分
        4. 每个章节有简要说明写作要点
        5. 字数在800-1200字之间

        请直接输出大纲内容，不要额外解释。
        """
        return (system, prompt)
    }

    static func sectionPrompt(outline: String, sectionTitle: String, context: String, wordCount: Int, referenceStyle: String) -> (system: String, prompt: String) {
        let system = "你是一位专业的学术论文写作助手，擅长撰写高质量的学术论文章节内容。"
        let contextClause = context.isEmpty ? "" : "\n\n已写部分摘要：\n\(String(context.prefix(500)))"
        let prompt = """
        请根据以下论文大纲，撰写"**\(sectionTitle)**"这一章节的详细内容。

        论文大纲：
        \(outline)
        \(contextClause)

        章节写作要求：
        1. 字数约\(wordCount)字
        2. 语言学术规范，逻辑清晰
        3. 适当使用专业术语
        4. 如需引用，请按\(referenceStyle)格式标注
        5. 段落结构完整，论证有据

        请直接输出章节内容，使用"## \(sectionTitle)"作为标题开头。
        """
        return (system, prompt)
    }

    static func abstractPrompt(fullText: String, language: String) -> (system: String, prompt: String) {
        let system = "你是一位专业的学术论文摘要写作专家。"
        let textPreview = String(fullText.prefix(12000))
        let prompt = """
        请根据以下论文内容，撰写一份专业的\(language)摘要：

        论文内容：
        \(textPreview)

        摘要要求：
        1. 简明扼要，200-400字
        2. 包含研究背景、目的、方法、结果和结论
        3. 语言精炼，学术规范
        4. 突出创新点和研究价值
        5. 同时生成5-8个关键词

        格式：
        【摘要】
        [摘要内容]

        【关键词】
        [关键词1]；[关键词2]；...
        """
        return (system, prompt)
    }

    // MARK: - AI Reduce Prompts
    static func aiReducePrompt(text: String, mode: Constants.AIReduceMode) -> (system: String, prompt: String) {
        let system = "你是一位专业的中文学术写作专家，擅长将AI生成文本改写为更自然的人类写作风格。"
        let modeInstruction: String
        switch mode {
        case .light:
            modeInstruction = """
            改写要求（轻度去痕）：
            1. 轻微调整句式结构和用词，保留80%以上原文内容
            2. 替换"综上所述"、"首先...其次...最后"等AI常用套话
            3. 增加句子长度的自然变化
            4. 保留原文的核心信息和论证逻辑
            """
        case .deep:
            modeInstruction = """
            改写要求（深度重构）：
            1. 大幅重构句式，改变段落组织方式
            2. 用不同角度重新表达相同含义
            3. 增加个性化表达，模拟人工写作特征
            4. 保留原文核心论点，但表达方式完全不同
            """
        case .academic:
            modeInstruction = """
            改写要求（学术拟合）：
            1. 转化为专业学术文体
            2. 使用领域专业术语和表达方式
            3. 增加学术引用风格的表达（如"研究表明"、"数据显示"）
            4. 增强逻辑论证的严密性
            5. 使文本风格贴近真实学术论文
            """
        }
        let prompt = """
        请对以下文本进行改写，降低AI检测率：

        原文：
        \(text)

        \(modeInstruction)

        重要说明：
        - 保留文中所有引用标注如[1][2]等
        - 输出改写后的文本，不需要解释说明
        - 直接输出改写结果
        """
        return (system, prompt)
    }

    // MARK: - Plagiarism Reduction Prompts
    static func plagiarismReducePrompt(text: String) -> (system: String, prompt: String) {
        let system = "你是一位专业的学术写作专家，擅长在保持学术严谨性的同时对文本进行改写以降低查重率。"
        let prompt = """
        请对以下学术文本进行改写，以降低查重率：

        原文：
        \(text)

        改写要求：
        1. 保持原文核心观点和学术内容不变
        2. 改变句子结构和表达方式，避免与原文过于相似
        3. 替换同义词，使用不同的学术表达方式
        4. 调整段落顺序或结构（在不影响逻辑的前提下）
        5. 保留专业术语和必要的技术表达
        6. 保留文中所有引用标注如[1][2]等
        7. 改写后文本长度应与原文相近

        请直接输出改写后的文本，不需要解释。
        """
        return (system, prompt)
    }

    // MARK: - Polish Prompts
    static func polishPrompt(text: String, mode: Constants.PolishMode) -> (system: String, prompt: String) {
        let system = "你是一位专业的学术论文编辑和语言润色专家。"
        let modeInstruction: String
        switch mode {
        case .academic:
            modeInstruction = "提升学术性：使用专业学术术语，增强逻辑严密性，符合学术写作规范"
        case .fluency:
            modeInstruction = "提升流畅度：改善语言表达的流畅性和自然感，使阅读更顺畅"
        case .professional:
            modeInstruction = "专业化表达：采用更专业的行业术语和表达方式，提升专业水准"
        case .concise:
            modeInstruction = "简洁精炼：删除冗余表达，使语言更简洁有力，保留核心信息"
        case .comprehensive:
            modeInstruction = "全面润色：综合提升准确性、流畅性、学术性和专业性"
        }

        let prompt = """
        请对以下文本进行学术润色：

        原文：
        \(text)

        润色要求（\(mode.rawValue)）：
        \(modeInstruction)

        通用要求：
        1. 保持原文的核心内容和观点
        2. 保留文中的引用标注
        3. 改善表达质量和学术规范性
        4. 输出润色后的完整文本

        请直接输出润色后的文本。
        """
        return (system, prompt)
    }

    // MARK: - Correction Prompts
    static func correctionPrompt(text: String, category: Constants.CorrectionCategory) -> (system: String, prompt: String) {
        let system = category.systemPrompt
        let categoryInstruction: String
        switch category {
        case .all:
            categoryInstruction = "对文本进行全面纠错，包括错别字、语法、标点、逻辑、学术规范等"
        case .typo:
            categoryInstruction = "识别并纠正错别字，保持其他内容不变"
        case .grammar:
            categoryInstruction = "识别并纠正语法错误，包括主谓不一致、成分残缺等"
        case .punctuation:
            categoryInstruction = "识别并纠正标点符号错误，遵循中文标点使用规范"
        case .logic:
            categoryInstruction = "识别并改正逻辑表达问题，使论证更加严密"
        case .academic:
            categoryInstruction = "按照学术写作规范，纠正不规范的学术表达"
        case .citation:
            categoryInstruction = "检查并规范引用格式，确保符合学术引用规范"
        case .numbers:
            categoryInstruction = "规范数字的使用，按照学术规范正确使用阿拉伯数字和汉字数字"
        case .structure:
            categoryInstruction = "分析并优化文本结构，改善段落组织和逻辑层次"
        }

        let prompt = """
        请对以下文本进行纠错：

        原文：
        \(text)

        纠错类型：\(category.rawValue)
        具体要求：\(categoryInstruction)

        输出格式：
        1. 首先列出发现的问题（每行一条）
        2. 然后输出完整的纠正后文本

        格式：
        【问题列表】
        - 问题1
        - 问题2
        ...

        【纠正后文本】
        [完整的纠正后文本]
        """
        return (system, prompt)
    }
}

// MARK: - Text Analysis Helper
enum TextAnalyzer {
    static func detectAIFeatures(text: String) -> (score: Int, features: [String], riskLevel: String) {
        var score = 0
        var features: [String] = []

        for pattern in Constants.aiPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                features.append("发现高频模板表达：\(String(pattern.prefix(20)))")
                score += 5
            }
        }

        let sentences = text.components(separatedBy: CharacterSet(charactersIn: "。！？?!"))
            .filter { $0.trimmingCharacters(in: .whitespaces).count > 5 }

        if sentences.count > 5 {
            let lengths = sentences.map { $0.count }
            let avg = Double(lengths.reduce(0, +)) / Double(lengths.count)
            let variance = lengths.map { pow(Double($0) - avg, 2) }.reduce(0, +) / Double(lengths.count)
            if variance < 100 {
                features.append("句子长度分布过于均匀，存在模板化生成倾向")
                score += 10
            }
        }

        let connectorCount = Constants.flowConnectors.reduce(0) { $0 + (text.components(separatedBy: $1).count - 1) }
        if !sentences.isEmpty && Double(connectorCount) > Double(sentences.count) * 0.4 {
            features.append("连接词使用偏密集，共出现 \(connectorCount) 次")
            score += 8
        }

        let clampedScore = min(100, score)
        let riskLevel: String
        if clampedScore >= 30 { riskLevel = "高风险" }
        else if clampedScore >= 15 { riskLevel = "中风险" }
        else { riskLevel = "低风险" }

        return (clampedScore, features, riskLevel)
    }
}
