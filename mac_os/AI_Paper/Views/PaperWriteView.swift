import SwiftUI

struct PaperWriteView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var historyManager: HistoryManager

    // Topic & Settings
    @State private var topic: String = ""
    @State private var subject: String = ""
    @State private var selectedStyle: PaperStyle = .academic
    @State private var selectedRefStyle: ReferenceStyle = .gbt7714
    @State private var wordCountPerSection: Int = 1000

    // Content
    @State private var outline: String = ""
    @State private var sections: [PaperSection] = []
    @State private var abstract: String = ""
    @State private var currentSectionTitle: String = ""

    // UI State
    @State private var isGeneratingOutline = false
    @State private var isGeneratingSection = false
    @State private var isGeneratingAbstract = false
    @State private var errorMessage: String?
    @State private var selectedTab: PaperWriteTab = .outline
    @State private var showExportOptions = false

    enum PaperWriteTab: String, CaseIterable {
        case outline = "大纲"
        case write = "章节写作"
        case abstract = "摘要"
        case preview = "全文预览"
    }

    var fullText: String {
        var parts: [String] = []
        if !abstract.isEmpty { parts.append("摘要\n\n\(abstract)") }
        for section in sections.sorted(by: { $0.order < $1.order }) {
            parts.append(section.fullContent)
        }
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        HSplitView {
            settingsPanel
                .frame(minWidth: 260, maxWidth: 320)
            mainContent
        }
        .navigationTitle("论文写作")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                exportButton
            }
        }
        .alert("错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Settings Panel
    private var settingsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("写作设置")
                    .font(.headline)
                    .padding(.bottom, 4)

                Group {
                    SettingField(label: "论文主题") {
                        TextEditor(text: $topic)
                            .frame(height: 80)
                            .font(.body)
                            .padding(6)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                    }

                    SettingField(label: "学科领域") {
                        TextField("如：计算机科学、医学、经济学", text: $subject)
                            .textFieldStyle(.roundedBorder)
                    }

                    SettingField(label: "论文类型") {
                        Picker("论文类型", selection: $selectedStyle) {
                            ForEach(PaperStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    SettingField(label: "参考文献格式") {
                        Picker("参考文献格式", selection: $selectedRefStyle) {
                            ForEach(ReferenceStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    SettingField(label: "每节字数") {
                        HStack {
                            Slider(value: Binding(
                                get: { Double(wordCountPerSection) },
                                set: { wordCountPerSection = Int($0) }
                            ), in: 500...3000, step: 100)
                            Text("\(wordCountPerSection)字")
                                .monospacedDigit()
                                .frame(width: 55)
                        }
                    }
                }

                Divider()

                VStack(spacing: 10) {
                    Button(action: generateOutline) {
                        HStack {
                            if isGeneratingOutline {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "list.bullet.rectangle.portrait")
                            }
                            Text("生成大纲")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(topic.trimmed.isEmpty || isGeneratingOutline)

                    if !outline.isEmpty {
                        Button(action: generateAbstract) {
                            HStack {
                                if isGeneratingAbstract {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "text.alignleft")
                                }
                                Text("生成摘要")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isGeneratingAbstract)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            Picker("标签", selection: $selectedTab) {
                ForEach(PaperWriteTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            switch selectedTab {
            case .outline:
                outlineTab
            case .write:
                writingTab
            case .abstract:
                abstractTab
            case .preview:
                previewTab
            }
        }
    }

    // MARK: - Outline Tab
    private var outlineTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("论文大纲")
                    .font(.headline)
                Spacer()
                if !outline.isEmpty {
                    Button("复制") { StorageManager.shared.copyToClipboard(outline) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding()

            if outline.isEmpty {
                emptyStateView(
                    icon: "list.bullet.rectangle.portrait",
                    title: "暂无大纲",
                    subtitle: "在左侧输入论文主题后点击「生成大纲」"
                )
            } else {
                TextEditor(text: $outline)
                    .font(.body)
                    .padding(8)
            }
        }
    }

    // MARK: - Writing Tab
    private var writingTab: some View {
        HSplitView {
            // Section list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("章节列表")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                Divider()

                if sections.isEmpty {
                    Text("暂无章节，请先生成大纲")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .font(.callout)
                } else {
                    List(sections.sorted(by: { $0.order < $1.order })) { section in
                        HStack {
                            Text(section.title)
                                .lineLimit(2)
                            Spacer()
                            if !section.content.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { currentSectionTitle = section.title }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Section editor
            VStack(spacing: 0) {
                HStack {
                    TextField("章节标题", text: $currentSectionTitle)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)

                    Button(action: writeSection) {
                        HStack {
                            if isGeneratingSection {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "pencil.and.sparkles")
                            }
                            Text("AI写作")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentSectionTitle.trimmed.isEmpty || outline.isEmpty || isGeneratingSection)

                    Spacer()
                }
                .padding()

                Divider()

                if let sectionIndex = sections.firstIndex(where: { $0.title == currentSectionTitle }) {
                    TextEditor(text: $sections[sectionIndex].content)
                        .font(.body)
                        .padding(8)
                } else {
                    emptyStateView(
                        icon: "pencil.and.sparkles",
                        title: "选择或输入章节标题",
                        subtitle: "点击左侧章节或输入新章节标题后点击「AI写作」"
                    )
                }
            }
        }
    }

    // MARK: - Abstract Tab
    private var abstractTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("摘要")
                    .font(.headline)
                Spacer()
                if !abstract.isEmpty {
                    Button("复制") { StorageManager.shared.copyToClipboard(abstract) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding()
            Divider()

            if abstract.isEmpty {
                emptyStateView(
                    icon: "text.alignleft",
                    title: "暂无摘要",
                    subtitle: "在左侧点击「生成摘要」（需要先有章节内容）"
                )
            } else {
                TextEditor(text: $abstract)
                    .font(.body)
                    .padding(8)
            }
        }
    }

    // MARK: - Preview Tab
    private var previewTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("全文预览")
                    .font(.headline)
                Text("共 \(fullText.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("复制全文") { StorageManager.shared.copyToClipboard(fullText) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding()
            Divider()

            if fullText.isEmpty {
                emptyStateView(
                    icon: "doc.text",
                    title: "暂无内容",
                    subtitle: "请先生成大纲并撰写各章节内容"
                )
            } else {
                ScrollView {
                    Text(fullText)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Export Button
    private var exportButton: some View {
        Menu {
            Button("导出为 TXT") {
                StorageManager.shared.exportText(fullText, defaultName: topic.isEmpty ? "paper" : topic)
            }
            Button("导出为 RTF") {
                StorageManager.shared.exportRTF(fullText, defaultName: topic.isEmpty ? "paper" : topic)
            }
            Button("导出为 LaTeX") {
                StorageManager.shared.exportLaTeX(fullText, defaultName: topic.isEmpty ? "paper" : topic)
            }
            Divider()
            Button("复制全文到剪贴板") {
                StorageManager.shared.copyToClipboard(fullText)
            }
        } label: {
            Label("导出", systemImage: "square.and.arrow.up")
        }
        .disabled(fullText.isEmpty)
    }

    // MARK: - Actions
    private func generateOutline() {
        let (system, prompt) = PromptBuilder.outlinePrompt(
            topic: topic,
            style: selectedStyle.rawValue,
            referenceStyle: selectedRefStyle.rawValue,
            subject: subject
        )
        isGeneratingOutline = true
        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    maxTokens: Constants.outlineMaxTokens
                )
                await MainActor.run {
                    outline = result
                    isGeneratingOutline = false
                    sections = parseOutlineSections(outline)
                    selectedTab = .outline
                    historyManager.addRecord(HistoryRecord(
                        pageID: "paper_write",
                        pageLabel: "论文写作",
                        action: "生成大纲",
                        inputText: topic,
                        outputText: result
                    ))
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGeneratingOutline = false
                }
            }
        }
    }

    private func writeSection() {
        let title = currentSectionTitle.trimmed
        guard !title.isEmpty else { return }

        let context = sections.sorted(by: { $0.order < $1.order })
            .compactMap { $0.content.isEmpty ? nil : $0.content }
            .joined(separator: "\n")

        let (system, prompt) = PromptBuilder.sectionPrompt(
            outline: outline,
            sectionTitle: title,
            context: context,
            wordCount: wordCountPerSection,
            referenceStyle: selectedRefStyle.rawValue
        )

        isGeneratingSection = true
        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    maxTokens: Constants.sectionMaxTokens
                )
                await MainActor.run {
                    if let idx = sections.firstIndex(where: { $0.title == title }) {
                        sections[idx].content = result
                    } else {
                        let newSection = PaperSection(
                            title: title,
                            content: result,
                            level: 2,
                            order: sections.count
                        )
                        sections.append(newSection)
                    }
                    isGeneratingSection = false
                    historyManager.addRecord(HistoryRecord(
                        pageID: "paper_write",
                        pageLabel: "论文写作",
                        action: "写作章节：\(title)",
                        inputText: "\(topic) - \(title)",
                        outputText: result
                    ))
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGeneratingSection = false
                }
            }
        }
    }

    private func generateAbstract() {
        guard !fullText.isEmpty else { return }
        let (system, prompt) = PromptBuilder.abstractPrompt(fullText: fullText, language: "中文")
        isGeneratingAbstract = true
        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    maxTokens: Constants.abstractMaxTokens
                )
                await MainActor.run {
                    abstract = result
                    isGeneratingAbstract = false
                    selectedTab = .abstract
                    historyManager.addRecord(HistoryRecord(
                        pageID: "paper_write",
                        pageLabel: "论文写作",
                        action: "生成摘要",
                        inputText: topic,
                        outputText: result
                    ))
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGeneratingAbstract = false
                }
            }
        }
    }

    // MARK: - Outline Parsing
    private func parseOutlineSections(_ outline: String) -> [PaperSection] {
        var result: [PaperSection] = []
        var order = 0
        let lines = outline.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("## ") {
                let title = String(trimmed.dropFirst(3))
                result.append(PaperSection(title: title, content: "", level: 2, order: order))
                order += 1
            } else if trimmed.hasPrefix("# ") {
                let title = String(trimmed.dropFirst(2))
                result.append(PaperSection(title: title, content: "", level: 1, order: order))
                order += 1
            } else if trimmed.hasPrefix("### ") {
                let title = String(trimmed.dropFirst(4))
                result.append(PaperSection(title: title, content: "", level: 3, order: order))
                order += 1
            }
        }
        return result
    }

    // MARK: - Empty State
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.callout)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Setting Field Helper
struct SettingField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            content()
        }
    }
}
