import SwiftUI

@main
struct AI_PaperApp: App {
    @StateObject private var configManager = ConfigManager()
    @StateObject private var historyManager = HistoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
                .environmentObject(historyManager)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("功能") {
                Button("论文写作") {}
                    .keyboardShortcut("1", modifiers: .command)
                Button("降AI检测") {}
                    .keyboardShortcut("2", modifiers: .command)
                Button("降查重率") {}
                    .keyboardShortcut("3", modifiers: .command)
                Button("学术润色") {}
                    .keyboardShortcut("4", modifiers: .command)
                Button("智能纠错") {}
                    .keyboardShortcut("5", modifiers: .command)
            }
        }
    }
}
