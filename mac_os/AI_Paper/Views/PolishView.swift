import SwiftUI

struct PolishView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var historyManager: HistoryManager

    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var selectedMode: Constants.PolishMode = .academic
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

            // Right: Mode + Output
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("润色模式")
                        .font(.headline)

                    ForEach(Constants.PolishMode.allCases) { mode in
                        PolishModeRow(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            onSelect: { selectedMode = mode }
                        )
                    }

                    Button(action: performPolish) {
                        HStack {
                            if isProcessing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "paintbrush.fill")
                            }
                            Text(isProcessing ? "润色中..." : "开始润色")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputText.trimmed.isEmpty || isProcessing)
                }
                .padding()

                Divider()

                VStack(spacing: 0) {
                    HStack {
                        Text("润色结果")
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
                                StorageManager.shared.exportText(outputText, defaultName: "polished")
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
                            Image(systemName: "paintbrush")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("润色结果将显示在这里")
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
        .navigationTitle("学术润色")
        .alert("错误", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func performPolish() {
        let (system, prompt) = PromptBuilder.polishPrompt(text: inputText, mode: selectedMode)
        isProcessing = true
        outputText = ""

        Task {
            do {
                let result = try await apiClient.call(
                    prompt: prompt,
                    system: system,
                    temperature: 0.7,
                    maxTokens: 4096
                )
                await MainActor.run {
                    outputText = result
                    isProcessing = false
                    historyManager.addRecord(HistoryRecord(
                        pageID: "polish",
                        pageLabel: "学术润色",
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

// MARK: - Polish Mode Row
struct PolishModeRow: View {
    let mode: Constants.PolishMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
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
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
