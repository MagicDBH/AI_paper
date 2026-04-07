import SwiftUI

struct HomePageView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var apiClient: APIClient

    var onNavigate: (AppPage) -> Void

    private let features: [(page: AppPage, icon: String, color: Color, description: String)] = [
        (.paperWrite, "doc.text.fill", .blue, "AI智能大纲生成、章节撰写、摘要生成"),
        (.aiReduce, "wand.and.stars", .purple, "三种改写力度，有效降低AI检测率"),
        (.plagiarism, "checkmark.shield.fill", .green, "智能改写，降低文本重复率"),
        (.polish, "paintbrush.fill", .orange, "多种润色模式，提升学术表达质量"),
        (.correction, "exclamationmark.triangle.fill", .red, "8大纠错类别，全面提升文本质量"),
        (.history, "clock.fill", .gray, "查看历史记录，随时找回处理结果"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                if !configManager.hasActiveAPI {
                    apiWarningBanner
                }
                featuresGrid
                statsSection
            }
            .padding(24)
        }
        .navigationTitle("首页")
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("欢迎使用 纸研社")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("您的 AI 学术写作助手 · macOS 版")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - API Warning
    private var apiWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text("尚未配置 API")
                    .fontWeight(.semibold)
                Text("请先前往「API配置」页面设置您的 AI 服务商和密钥，才能使用各项功能。")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("立即配置") {
                onNavigate(.apiConfig)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Features Grid
    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("功能模块")
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(features, id: \.page) { feature in
                    FeatureCard(
                        page: feature.page,
                        icon: feature.icon,
                        color: feature.color,
                        description: feature.description,
                        onTap: { onNavigate(feature.page) }
                    )
                }
            }
        }
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(.headline)
                .foregroundColor(.secondary)
            HStack(spacing: 16) {
                StatCard(
                    title: "当前API",
                    value: configManager.activeProvider?.displayName ?? "未配置",
                    icon: "antenna.radiowaves.left.and.right",
                    color: configManager.hasActiveAPI ? .green : .gray
                )
                StatCard(
                    title: "可用服务商",
                    value: "\(configManager.configuredProviders.count)",
                    icon: "server.rack",
                    color: .blue
                )
                StatCard(
                    title: "模型",
                    value: configManager.activeProvider?.model ?? "-",
                    icon: "cpu",
                    color: .purple
                )
            }
        }
    }
}

// MARK: - Feature Card
struct FeatureCard: View {
    let page: AppPage
    let icon: String
    let color: Color
    let description: String
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 36, height: 36)
                        .background(color.opacity(0.15))
                        .cornerRadius(8)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(isHovering ? Color(NSColor.controlBackgroundColor).opacity(0.8) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHovering ? Color.accentColor.opacity(0.5) : Color(NSColor.separatorColor), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isHovering ? 0.08 : 0.03), radius: isHovering ? 8 : 4, x: 0, y: 2)
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovering = hovering }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}
