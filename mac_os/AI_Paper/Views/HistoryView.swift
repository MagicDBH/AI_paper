import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyManager: HistoryManager

    @State private var selectedFilter: HistoryFilter = .all
    @State private var searchText: String = ""
    @State private var selectedRecord: HistoryRecord?
    @State private var showDeleteConfirmation = false
    @State private var selectionSet: Set<UUID> = []

    var filteredRecords: [HistoryRecord] {
        historyManager.filtered(by: selectedFilter, searchText: searchText)
    }

    var body: some View {
        HSplitView {
            // List Panel
            VStack(spacing: 0) {
                listToolbar
                Divider()
                filterBar
                Divider()

                if filteredRecords.isEmpty {
                    emptyState
                } else {
                    List(filteredRecords, selection: $selectedRecord) { record in
                        HistoryRowView(record: record) {
                            historyManager.toggleFavorite(id: record.id)
                        }
                        .tag(record)
                        .contextMenu {
                            Button("收藏/取消收藏") { historyManager.toggleFavorite(id: record.id) }
                            Button("复制输出内容") { StorageManager.shared.copyToClipboard(record.outputText) }
                            Divider()
                            Button("删除", role: .destructive) {
                                historyManager.deleteRecord(id: record.id)
                                if selectedRecord?.id == record.id { selectedRecord = nil }
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 280, maxWidth: 380)

            // Detail Panel
            if let record = selectedRecord {
                HistoryDetailView(record: record) {
                    historyManager.toggleFavorite(id: record.id)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("选择一条记录查看详情")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("历史记录")
        .searchable(text: $searchText, prompt: "搜索历史记录")
        .alert("确认清空", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清空全部", role: .destructive) {
                historyManager.clearAll()
                selectedRecord = nil
            }
        } message: {
            Text("此操作将删除所有历史记录，无法恢复。")
        }
    }

    // MARK: - List Toolbar
    private var listToolbar: some View {
        HStack {
            Text("共 \(filteredRecords.count) 条")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Button(action: { showDeleteConfirmation = true }) {
                Label("清空全部", systemImage: "trash")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.red)
            .disabled(historyManager.records.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryFilter.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        onTap: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text(searchText.isEmpty ? "暂无历史记录" : "没有符合条件的记录")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - History Row View
struct HistoryRowView: View {
    let record: HistoryRecord
    let onFavoriteToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(record.pageLabel, systemImage: iconForPage(record.pageID))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(colorForPage(record.pageID).opacity(0.12))
                    .cornerRadius(4)

                Spacer()

                if record.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }

                Text(record.createdAt.displayString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(record.action)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(record.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private func iconForPage(_ pageID: String) -> String {
        switch pageID {
        case "paper_write": return "doc.text.fill"
        case "ai_reduce": return "wand.and.stars"
        case "plagiarism": return "checkmark.shield.fill"
        case "polish": return "paintbrush.fill"
        case "correction": return "exclamationmark.triangle.fill"
        default: return "clock.fill"
        }
    }

    private func colorForPage(_ pageID: String) -> Color {
        switch pageID {
        case "paper_write": return .blue
        case "ai_reduce": return .purple
        case "plagiarism": return .green
        case "polish": return .orange
        case "correction": return .red
        default: return .gray
        }
    }
}

// MARK: - History Detail View
struct HistoryDetailView: View {
    let record: HistoryRecord
    let onFavoriteToggle: () -> Void

    @State private var selectedTab: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.action)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("\(record.pageLabel) · \(record.createdAt.shortFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: onFavoriteToggle) {
                        Image(systemName: record.isFavorite ? "star.fill" : "star")
                            .foregroundColor(record.isFavorite ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                    .font(.title3)
                }

                HStack(spacing: 16) {
                    Label("输入 \(record.inputWordCount) 字", systemImage: "arrow.right.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("输出 \(record.outputWordCount) 字", systemImage: "arrow.left.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Tab Selector
            Picker("内容", selection: $selectedTab) {
                Text("输出内容").tag(1)
                Text("输入内容").tag(0)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Content + Toolbar
            HStack {
                Spacer()
                let currentText = selectedTab == 1 ? record.outputText : record.inputText
                Button("复制") { StorageManager.shared.copyToClipboard(currentText) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("导出") {
                    StorageManager.shared.exportText(currentText, defaultName: "history_export")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            ScrollView {
                let text = selectedTab == 1 ? record.outputText : record.inputText
                Text(text.isEmpty ? "（无内容）" : text)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(text.isEmpty ? .secondary : .primary)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
