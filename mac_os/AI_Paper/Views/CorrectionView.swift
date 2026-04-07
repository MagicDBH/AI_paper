import SwiftUI

struct CorrectionView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var historyManager: HistoryManager

    @State private var inputText: String = ""
    @State private var issuesList: String = ""
    @State private var correctedText: String = ""
    @State private var selectedCategory: Constants.CorrectionCategory = .all
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        HSplitView {
            // Input Panel
            VStack(spacing: 0) {
                HStack {
                    Text("待纠错文本")
                        .font(.headline)
                    Spacer()
                    Button("导入文件") {
                        StorageManager.shared.importTextFile { text in
                            if let text { inputText = text }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Button("清空") {
                        inputText = ""
                        issuesList = ""
                        correctedText = ""
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
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
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // Right: Category + Output
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("纠错类型")
                        .font(.headline)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 8
                    ) {
                        ForEach(Constants.CorrectionCategory.allCases) { category in
                            CorrectionCategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                onSelect: { selectedCategory = category }
                            )
                        }
                    }

                    Button(action: performCorrection) {
                        HStack {
                            if isProcessing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                            }
                            Text(isProcessing ? "纠错中..." : "开始纠错")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.trimmed.isEmpty || isProcessing)
                }
                .padding()

                Divider()

                // Output section with tabs
                VStack(spacing: 0) {
                    if !issuesList.isEmpty || !correctedText.isEmpty {
                        CorrectionResultView(
                            issuesList: issuesList,
                            correctedText: correctedText
                        )
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("纠错结果将显示在这里")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .navigationTitle("智能纠错")
        .alert("错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func performCorrection() {
        let (system, prompt) = PromptBuilder.correctionPrompt(text: inputText, category: selectedCategory)
        isProcessing = true
        issuesList = ""
        correctedText = ""

        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    temperature: 0.3,
                    maxTokens: 4096
                )
                await MainActor.run {
                    parseResult(result)
                    isProcessing = false
                    historyManager.addRecord(HistoryRecord(
                        pageID: "correction",
                        pageLabel: "智能纠错",
                        action: selectedCategory.rawValue,
                        inputText: inputText,
                        outputText: result,
                        metadata: ["category": selectedCategory.rawValue]
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

    private func parseResult(_ result: String) {
        // Parse the structured output from AI
        if result.contains("【问题列表】") && result.contains("【纠正后文本】") {
            let parts = result.components(separatedBy: "【纠正后文本】")
            if let issuePart = parts.first {
                issuesList = issuePart
                    .replacingOccurrences(of: "【问题列表】", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if parts.count > 1 {
                correctedText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            correctedText = result
        }
    }
}

// MARK: - Correction Category Button
struct CorrectionCategoryButton: View {
    let category: Constants.CorrectionCategory
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(category.rawValue)
                .font(.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Correction Result View
struct CorrectionResultView: View {
    let issuesList: String
    let correctedText: String

    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("结果", selection: $selectedTab) {
                Text("纠正后文本").tag(0)
                Text("问题列表").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            HStack {
                Spacer()
                let textToCopy = selectedTab == 0 ? correctedText : issuesList
                if !textToCopy.isEmpty {
                    Button("复制") { StorageManager.shared.copyToClipboard(textToCopy) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("导出") {
                        StorageManager.shared.exportText(textToCopy, defaultName: "corrected")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            if selectedTab == 0 {
                ScrollView {
                    Text(correctedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ScrollView {
                    Text(issuesList)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
