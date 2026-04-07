import SwiftUI

struct PlagiarismView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var historyManager: HistoryManager

    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        HSplitView {
            // Input Panel
            VStack(spacing: 0) {
                HStack {
                    Text("原文输入")
                        .font(.headline)
                    Spacer()
                    Button("导入文件") {
                        StorageManager.shared.importTextFile { text in
                            if let text { inputText = text }
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

            // Right Panel
            VStack(spacing: 0) {
                // Info + Button
                VStack(alignment: .leading, spacing: 12) {
                    Text("降查重设置")
                        .font(.headline)

                    infoCard(
                        icon: "info.circle",
                        text: "通过语义改写、同义词替换和句式重构，在保持原文核心内容的前提下有效降低文本重复率。"
                    )

                    infoCard(
                        icon: "checkmark.shield",
                        text: "适用场景：学术论文、毕业设计、研究报告等需要通过查重检测的学术文本。"
                    )

                    Button(action: performPlagiarismReduction) {
                        HStack {
                            if isProcessing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                            }
                            Text(isProcessing ? "处理中..." : "开始降查重")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.trimmed.isEmpty || isProcessing)
                }
                .padding()

                Divider()

                // Output
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
                                StorageManager.shared.exportText(outputText, defaultName: "plagiarism_reduced")
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
                            Image(systemName: "checkmark.shield")
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
        }
        .navigationTitle("降查重率")
        .alert("错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func infoCard(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.callout)
                .frame(width: 20)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.05))
        .cornerRadius(8)
    }

    private func performPlagiarismReduction() {
        let (system, prompt) = PromptBuilder.plagiarismReducePrompt(text: inputText)
        isProcessing = true
        outputText = ""

        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    temperature: 0.8,
                    maxTokens: 4096
                )
                await MainActor.run {
                    outputText = result
                    isProcessing = false
                    historyManager.addRecord(HistoryRecord(
                        pageID: "plagiarism",
                        pageLabel: "降查重率",
                        action: "降查重改写",
                        inputText: inputText,
                        outputText: result
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
