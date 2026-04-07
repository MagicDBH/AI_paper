import SwiftUI

struct AIReduceView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var historyManager: HistoryManager

    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var selectedMode: Constants.AIReduceMode = .light
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showAnalysis = false
    @State private var analysisResult: (score: Int, features: [String], riskLevel: String)?

    var body: some View {
        HSplitView {
            // Left: Input
            VStack(spacing: 0) {
                inputToolbar
                Divider()
                TextEditor(text: $inputText)
                    .font(.body)
                    .padding(8)

                Divider()
                HStack {
                    Text("字数：\(inputText.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("导入文件") {
                        StorageManager.shared.importTextFile { text in
                            if let text { inputText = text }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // Right: Output + Controls
            VStack(spacing: 0) {
                controlPanel
                Divider()
                outputArea
            }
        }
        .navigationTitle("降AI检测")
        .alert("错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Input Toolbar
    private var inputToolbar: some View {
        HStack {
            Text("原文输入")
                .font(.headline)
            Spacer()
            Button("粘贴") {
                if let str = NSPasteboard.general.string(forType: .string) {
                    inputText = str
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("清空") { inputText = ""; outputText = "" }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Control Panel
    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("改写设置")
                    .font(.headline)
                Spacer()
                Button("AI检测分析") {
                    analyzeText()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(inputText.trimmed.isEmpty)
            }

            // Mode Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("改写力度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)

                ForEach(Constants.AIReduceMode.allCases, id: \.self) { mode in
                    ModeSelectionRow(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onSelect: { selectedMode = mode }
                    )
                }
            }

            // Analysis Results
            if showAnalysis, let analysis = analysisResult {
                Divider()
                AIAnalysisCard(analysis: analysis)
            }

            Button(action: performRewrite) {
                HStack {
                    if isProcessing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isProcessing ? "改写中..." : "开始改写")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.trimmed.isEmpty || isProcessing)
        }
        .padding()
    }

    // MARK: - Output Area
    private var outputArea: some View {
        VStack(spacing: 0) {
            HStack {
                Text("改写结果")
                    .font(.headline)
                Text(outputText.isEmpty ? "" : "共 \(outputText.count) 字")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if !outputText.isEmpty {
                    Button("复制") { StorageManager.shared.copyToClipboard(outputText) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("导出") {
                        StorageManager.shared.exportText(outputText, defaultName: "ai_reduced")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            Divider()

            if outputText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("改写结果将显示在这里")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextEditor(text: $outputText)
                    .font(.body)
                    .padding(8)
            }
        }
    }

    // MARK: - Actions
    private func analyzeText() {
        let result = TextAnalyzer.detectAIFeatures(text: inputText)
        analysisResult = result
        showAnalysis = true
    }

    private func performRewrite() {
        let (system, prompt) = PromptBuilder.aiReducePrompt(text: inputText, mode: selectedMode)
        isProcessing = true
        outputText = ""

        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    temperature: selectedMode.temperature,
                    maxTokens: 4096
                )
                await MainActor.run {
                    outputText = result
                    isProcessing = false
                    historyManager.addRecord(HistoryRecord(
                        pageID: "ai_reduce",
                        pageLabel: "降AI检测",
                        action: selectedMode.rawValue,
                        inputText: inputText,
                        outputText: result,
                        metadata: ["mode": selectedMode.rawValue]
                    ))
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Mode Selection Row
struct ModeSelectionRow: View {
    let mode: Constants.AIReduceMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.body)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .font(.callout)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Analysis Card
struct AIAnalysisCard: View {
    let analysis: (score: Int, features: [String], riskLevel: String)

    var riskColor: Color {
        switch analysis.riskLevel {
        case "高风险": return .red
        case "中风险": return .orange
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("AI痕迹检测")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text(analysis.riskLevel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(riskColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(riskColor.opacity(0.12))
                    .cornerRadius(6)
            }

            ProgressView(value: Double(analysis.score), total: 100)
                .tint(riskColor)

            if !analysis.features.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(analysis.features.prefix(3), id: \.self) { feature in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
