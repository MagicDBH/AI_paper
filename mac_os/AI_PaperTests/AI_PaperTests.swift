import XCTest

final class AI_PaperTests: XCTestCase {

    // MARK: - ConfigManager Tests
    func testConfigManagerDefaults() {
        let config = ConfigManager()
        XCTAssertFalse(config.providers.isEmpty, "Should have preset providers")
        XCTAssertGreaterThanOrEqual(config.providers.count, 10, "Should have at least 10 presets")
    }

    func testConfigManagerActiveAPI() {
        let config = ConfigManager()
        XCTAssertFalse(config.hasActiveAPI, "No active API when no API key is set")
    }

    func testConfigManagerUpdateProvider() {
        let config = ConfigManager()
        var provider = config.providers.first { $0.id == "openai" }!
        provider.apiKey = "test-key-123"
        config.updateProvider(provider)

        let updated = config.providers.first { $0.id == "openai" }!
        XCTAssertEqual(updated.apiKey, "test-key-123")
        XCTAssertTrue(updated.isConfigured)
    }

    func testConfigManagerSetActive() {
        let config = ConfigManager()
        var provider = config.providers.first { $0.id == "openai" }!
        provider.apiKey = "test-key"
        config.updateProvider(provider)
        config.setActive("openai")

        XCTAssertEqual(config.activeAPIName, "openai")
        XCTAssertTrue(config.hasActiveAPI)
    }

    func testConfigManagerResetToDefaults() {
        let config = ConfigManager()
        config.setActive("openai")
        config.resetToDefaults()

        XCTAssertEqual(config.activeAPIName, "")
        XCTAssertFalse(config.hasActiveAPI)
    }

    // MARK: - HistoryManager Tests
    func testHistoryManagerAddRecord() {
        let manager = HistoryManager()
        manager.clearAll()

        let record = HistoryRecord(
            pageID: "test_page",
            pageLabel: "测试",
            action: "测试操作",
            inputText: "输入文本",
            outputText: "输出文本"
        )
        manager.addRecord(record)

        XCTAssertEqual(manager.records.count, 1)
        XCTAssertEqual(manager.records.first?.action, "测试操作")
    }

    func testHistoryManagerFilter() {
        let manager = HistoryManager()
        manager.clearAll()

        manager.addRecord(HistoryRecord(pageID: "paper_write", pageLabel: "论文写作", action: "生成大纲"))
        manager.addRecord(HistoryRecord(pageID: "ai_reduce", pageLabel: "降AI检测", action: "轻度去痕"))
        manager.addRecord(HistoryRecord(pageID: "paper_write", pageLabel: "论文写作", action: "写作章节"))

        let paperRecords = manager.filtered(by: .paperWrite)
        XCTAssertEqual(paperRecords.count, 2)

        let aiReduceRecords = manager.filtered(by: .aiReduce)
        XCTAssertEqual(aiReduceRecords.count, 1)

        let allRecords = manager.filtered(by: .all)
        XCTAssertEqual(allRecords.count, 3)
    }

    func testHistoryManagerToggleFavorite() {
        let manager = HistoryManager()
        manager.clearAll()

        let record = HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作")
        manager.addRecord(record)

        let id = manager.records.first!.id
        XCTAssertFalse(manager.records.first!.isFavorite)

        manager.toggleFavorite(id: id)
        XCTAssertTrue(manager.records.first!.isFavorite)

        manager.toggleFavorite(id: id)
        XCTAssertFalse(manager.records.first!.isFavorite)
    }

    func testHistoryManagerDelete() {
        let manager = HistoryManager()
        manager.clearAll()

        manager.addRecord(HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作1"))
        manager.addRecord(HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作2"))

        XCTAssertEqual(manager.records.count, 2)

        let id = manager.records.first!.id
        manager.deleteRecord(id: id)

        XCTAssertEqual(manager.records.count, 1)
    }

    func testHistoryManagerSearch() {
        let manager = HistoryManager()
        manager.clearAll()

        manager.addRecord(HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作", inputText: "Hello World", outputText: "你好世界"))
        manager.addRecord(HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作", inputText: "机器学习", outputText: "深度学习"))

        let results1 = manager.filtered(by: .all, searchText: "Hello")
        XCTAssertEqual(results1.count, 1)

        let results2 = manager.filtered(by: .all, searchText: "学习")
        XCTAssertEqual(results2.count, 1)

        let results3 = manager.filtered(by: .all, searchText: "不存在的内容xyz")
        XCTAssertEqual(results3.count, 0)
    }

    // MARK: - APIProvider Tests
    func testAPIProviderIsConfigured() {
        var provider = APIProvider(id: "test", name: "Test", apiKey: "", apiFormat: .openAI)
        XCTAssertFalse(provider.isConfigured, "Empty API key should not be configured")

        provider.apiKey = "test-key"
        XCTAssertTrue(provider.isConfigured, "Non-empty API key should be configured")
    }

    func testBaiduProviderConfiguration() {
        var provider = APIProvider(id: "baidu", name: "百度", apiFormat: .baidu)
        XCTAssertFalse(provider.isConfigured)

        provider.apiKey = "api-key"
        XCTAssertFalse(provider.isConfigured, "Baidu needs both apiKey and secretKey")

        provider.secretKey = "secret-key"
        XCTAssertTrue(provider.isConfigured)
    }

    func testSparkProviderConfiguration() {
        var provider = APIProvider(id: "spark", name: "星火", apiFormat: .spark)
        XCTAssertFalse(provider.isConfigured)

        provider.appID = "app-id"
        provider.apiKey = "api-key"
        provider.apiSecret = "api-secret"
        XCTAssertTrue(provider.isConfigured)
    }

    // MARK: - HistoryRecord Tests
    func testHistoryRecordSummary() {
        let shortRecord = HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作", outputText: "短文本")
        XCTAssertEqual(shortRecord.summary, "短文本")

        let longText = String(repeating: "A", count: 100)
        let longRecord = HistoryRecord(pageID: "test", pageLabel: "测试", action: "操作", outputText: longText)
        XCTAssertTrue(longRecord.summary.count <= 83) // 80 + "..."
        XCTAssertTrue(longRecord.summary.hasSuffix("..."))
    }

    // MARK: - TextAnalyzer Tests
    func testTextAnalyzerDetectAIFeatures() {
        let aiText = "首先，综上所述，不可否认，显而易见，众所周知，毋庸置疑，值得注意的是，总而言之，由此可见。"
        let result = TextAnalyzer.detectAIFeatures(text: aiText)

        XCTAssertGreaterThan(result.score, 0)
        XCTAssertFalse(result.features.isEmpty)
        XCTAssertFalse(result.riskLevel.isEmpty)
    }

    func testTextAnalyzerCleanText() {
        let cleanText = "这是一段自然的文字，没有明显的AI写作痕迹，语言风格比较自然。"
        let result = TextAnalyzer.detectAIFeatures(text: cleanText)

        XCTAssertEqual(result.riskLevel, "低风险")
    }

    // MARK: - PromptBuilder Tests
    func testOutlinePromptNotEmpty() {
        let (system, prompt) = PromptBuilder.outlinePrompt(
            topic: "人工智能在医疗领域的应用",
            style: "学术论文",
            referenceStyle: "GB/T 7714",
            subject: "医学"
        )
        XCTAssertFalse(system.isEmpty)
        XCTAssertFalse(prompt.isEmpty)
        XCTAssertTrue(prompt.contains("人工智能在医疗领域的应用"))
    }

    func testSectionPromptContainsTopic() {
        let (_, prompt) = PromptBuilder.sectionPrompt(
            outline: "大纲内容",
            sectionTitle: "第一章 引言",
            context: "",
            wordCount: 1000,
            referenceStyle: "GB/T 7714"
        )
        XCTAssertTrue(prompt.contains("第一章 引言"))
        XCTAssertTrue(prompt.contains("1000"))
    }

    func testAIReducePromptModes() {
        for mode in Constants.AIReduceMode.allCases {
            let (system, prompt) = PromptBuilder.aiReducePrompt(text: "测试文本", mode: mode)
            XCTAssertFalse(system.isEmpty, "System prompt should not be empty for \(mode.rawValue)")
            XCTAssertFalse(prompt.isEmpty, "Prompt should not be empty for \(mode.rawValue)")
            XCTAssertTrue(prompt.contains("测试文本"), "Prompt should contain the input text")
        }
    }

    // MARK: - StorageManager Tests
    func testLaTeXConversion() {
        let text = """
        # 第一章 引言

        ## 1.1 研究背景

        这是正文内容。

        ### 1.1.1 子节
        """
        let latex = StorageManager.shared.convertToLaTeX(text)

        XCTAssertTrue(latex.contains("\\documentclass"))
        XCTAssertTrue(latex.contains("\\section{第一章 引言}"))
        XCTAssertTrue(latex.contains("\\subsection{1.1 研究背景}"))
        XCTAssertTrue(latex.contains("\\subsubsection{1.1.1 子节}"))
        XCTAssertTrue(latex.contains("\\end{document}"))
    }

    // MARK: - String Extension Tests
    func testStringTrimmed() {
        XCTAssertEqual("  hello  ".trimmed, "hello")
        XCTAssertEqual("no spaces".trimmed, "no spaces")
    }

    func testStringTruncated() {
        let str = "Hello, World!"
        XCTAssertEqual(str.truncated(to: 5), "Hello...")
        XCTAssertEqual(str.truncated(to: 100), "Hello, World!")
    }

    func testStringIsNotEmpty() {
        XCTAssertTrue("hello".isNotEmpty)
        XCTAssertFalse("".isNotEmpty)
    }

    // MARK: - Paper Model Tests
    func testPaperFullText() {
        var paper = Paper(topic: "测试主题")
        paper.abstract = "测试摘要"
        paper.sections = [
            PaperSection(title: "引言", content: "引言内容", level: 1, order: 0),
            PaperSection(title: "主体", content: "主体内容", level: 1, order: 1),
        ]

        XCTAssertTrue(paper.fullText.contains("测试摘要"))
        XCTAssertTrue(paper.fullText.contains("引言内容"))
        XCTAssertTrue(paper.fullText.contains("主体内容"))
    }

    func testPaperSectionFullContent() {
        let section = PaperSection(title: "第一章", content: "内容", level: 1, order: 0)
        XCTAssertTrue(section.fullContent.contains("# 第一章"))
        XCTAssertTrue(section.fullContent.contains("内容"))

        let subsection = PaperSection(title: "1.1 小节", content: "子节内容", level: 2, order: 0)
        XCTAssertTrue(subsection.fullContent.contains("## 1.1 小节"))
    }
}
