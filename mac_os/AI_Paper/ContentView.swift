import SwiftUI

enum AppPage: String, CaseIterable, Identifiable {
    case home = "首页"
    case paperWrite = "论文写作"
    case aiReduce = "降AI检测"
    case plagiarism = "降查重率"
    case polish = "学术润色"
    case correction = "智能纠错"
    case history = "历史记录"
    case apiConfig = "API配置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .paperWrite: return "doc.text.fill"
        case .aiReduce: return "wand.and.stars"
        case .plagiarism: return "checkmark.shield.fill"
        case .polish: return "paintbrush.fill"
        case .correction: return "exclamationmark.triangle.fill"
        case .history: return "clock.fill"
        case .apiConfig: return "gear"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var configManager: ConfigManager
    @EnvironmentObject var historyManager: HistoryManager
    @StateObject private var apiClient: APIClient = APIClient()
    @State private var selectedPage: AppPage = .home
    @State private var isConfigured: Bool = false

    var body: some View {
        NavigationSplitView {
            sidebarView
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            apiClient.configure(with: configManager)
            isConfigured = configManager.hasActiveAPI
        }
        .onChange(of: configManager.activeAPIName) { _ in
            isConfigured = configManager.hasActiveAPI
            apiClient.configure(with: configManager)
        }
    }

    // MARK: - Sidebar
    private var sidebarView: some View {
        List(AppPage.allCases, selection: $selectedPage) { page in
            Label(page.rawValue, systemImage: page.icon)
                .tag(page)
        }
        .listStyle(.sidebar)
        .navigationTitle("纸研社")
        .frame(minWidth: 180)
    }

    // MARK: - Detail
    @ViewBuilder
    private var detailView: some View {
        switch selectedPage {
        case .home:
            HomePageView(onNavigate: { page in selectedPage = page })
                .environmentObject(apiClient)
        case .paperWrite:
            PaperWriteView()
                .environmentObject(apiClient)
                .environmentObject(historyManager)
        case .aiReduce:
            AIReduceView()
                .environmentObject(apiClient)
                .environmentObject(historyManager)
        case .plagiarism:
            PlagiarismView()
                .environmentObject(apiClient)
                .environmentObject(historyManager)
        case .polish:
            PolishView()
                .environmentObject(apiClient)
                .environmentObject(historyManager)
        case .correction:
            CorrectionView()
                .environmentObject(apiClient)
                .environmentObject(historyManager)
        case .history:
            HistoryView()
                .environmentObject(historyManager)
        case .apiConfig:
            APIConfigView()
                .environmentObject(configManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConfigManager())
        .environmentObject(HistoryManager())
}
