import SwiftUI

struct APIConfigView: View {
    @EnvironmentObject var configManager: ConfigManager

    @State private var selectedProviderID: String?
    @State private var editingProvider: APIProvider?
    @State private var showAddCustom = false
    @State private var showResetConfirmation = false
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        HSplitView {
            // Provider List
            VStack(spacing: 0) {
                listHeader
                Divider()
                List(configManager.providers, selection: $selectedProviderID) { provider in
                    ProviderListRow(
                        provider: provider,
                        isActive: configManager.activeAPIName == provider.id
                    )
                    .tag(provider.id)
                }
                .listStyle(.inset)
                listFooter
            }
            .frame(minWidth: 220, maxWidth: 280)

            // Edit Panel
            if let providerID = selectedProviderID,
               let provider = configManager.providers.first(where: { $0.id == providerID }) {
                ProviderEditView(
                    provider: provider,
                    isActive: configManager.activeAPIName == provider.id,
                    isTesting: isTesting,
                    testResult: testResult,
                    onSave: { updated in
                        configManager.updateProvider(updated)
                        testResult = nil
                    },
                    onSetActive: {
                        configManager.setActive(providerID)
                    },
                    onTest: { prov in
                        testProvider(prov)
                    }
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "gear.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("选择一个服务商进行配置")
                        .foregroundColor(.secondary)
                    Text("配置您的 API 密钥后即可开始使用")
                        .font(.callout)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("API 配置")
        .alert("重置配置", isPresented: $showResetConfirmation) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                configManager.resetToDefaults()
                selectedProviderID = nil
            }
        } message: {
            Text("将清除所有已保存的 API 密钥，恢复为默认配置。")
        }
    }

    // MARK: - List Header
    private var listHeader: some View {
        HStack {
            Text("服务商 (\(configManager.providers.count))")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - List Footer
    private var listFooter: some View {
        HStack {
            Button("重置默认") {
                showResetConfirmation = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.red)
            Spacer()
            if let activeID = configManager.providers.first(where: { $0.id == configManager.activeAPIName })?.displayName {
                Label(activeID, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Test Provider
    private func testProvider(_ provider: APIProvider) {
        isTesting = true
        testResult = nil
        Task {
            do {
                let tempConfigManager = ConfigManager()
                tempConfigManager.updateProvider(provider)
                tempConfigManager.setActive(provider.id)
                let tempClient = APIClient()
                tempClient.configure(with: tempConfigManager)

                let result = try await tempClient.call(
                    prompt: "请回答：1+1=?（请只回答数字）",
                    system: "你是一个简单的数学助手，请用最简短的方式回答。",
                    maxTokens: 20
                )
                await MainActor.run {
                    testResult = "✅ 连接成功！回复：\(result.prefix(50))"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ 连接失败：\(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}

// MARK: - Provider List Row
struct ProviderListRow: View {
    let provider: APIProvider
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(provider.isConfigured ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(provider.displayName)
                        .font(.callout)
                        .fontWeight(isActive ? .semibold : .regular)
                    if isActive {
                        Text("使用中")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                Text(provider.model.isEmpty ? provider.apiFormat.displayName : provider.model)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Provider Edit View
struct ProviderEditView: View {
    let provider: APIProvider
    let isActive: Bool
    let isTesting: Bool
    let testResult: String?
    let onSave: (APIProvider) -> Void
    let onSetActive: () -> Void
    let onTest: (APIProvider) -> Void

    @State private var editedProvider: APIProvider

    init(
        provider: APIProvider,
        isActive: Bool,
        isTesting: Bool,
        testResult: String?,
        onSave: @escaping (APIProvider) -> Void,
        onSetActive: @escaping () -> Void,
        onTest: @escaping (APIProvider) -> Void
    ) {
        self.provider = provider
        self.isActive = isActive
        self.isTesting = isTesting
        self.testResult = testResult
        self.onSave = onSave
        self.onSetActive = onSetActive
        self.onTest = onTest
        self._editedProvider = State(initialValue: provider)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(editedProvider.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(editedProvider.apiFormat.displayName)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if isActive {
                        Label("当前使用", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.callout)
                    } else if editedProvider.isConfigured {
                        Button("设为当前") {
                            onSave(editedProvider)
                            onSetActive()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                Divider()

                // Fields
                VStack(alignment: .leading, spacing: 14) {
                    SettingField(label: "显示名称") {
                        TextField("显示名称", text: $editedProvider.displayName)
                            .textFieldStyle(.roundedBorder)
                    }

                    if editedProvider.apiFormat != .baidu && editedProvider.apiFormat != .spark {
                        SettingField(label: "API 地址（Base URL）") {
                            TextField("https://api.openai.com/v1", text: $editedProvider.baseURL)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if editedProvider.apiFormat == .baidu {
                        SettingField(label: "API Key（Client ID）") {
                            SecureField("百度 API Key", text: $editedProvider.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingField(label: "Secret Key（Client Secret）") {
                            SecureField("百度 Secret Key", text: $editedProvider.secretKey)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else if editedProvider.apiFormat == .spark {
                        SettingField(label: "App ID") {
                            TextField("讯飞 App ID", text: $editedProvider.appID)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingField(label: "API Key") {
                            SecureField("讯飞 API Key", text: $editedProvider.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        SettingField(label: "API Secret") {
                            SecureField("讯飞 API Secret", text: $editedProvider.apiSecret)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        SettingField(label: "API Key") {
                            SecureField("sk-...", text: $editedProvider.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    SettingField(label: "模型") {
                        TextField("模型名称", text: $editedProvider.model)
                            .textFieldStyle(.roundedBorder)
                    }

                    SettingField(label: "Temperature（\(String(format: "%.2f", editedProvider.temperature))）") {
                        Slider(value: $editedProvider.temperature, in: 0...1, step: 0.05)
                    }

                    SettingField(label: "最大 Token 数") {
                        HStack {
                            TextField("4096", value: $editedProvider.maxTokens, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Stepper("", value: $editedProvider.maxTokens, in: 512...32768, step: 512)
                                .labelsHidden()
                        }
                    }
                }

                Divider()

                // Actions
                HStack(spacing: 12) {
                    Button(action: { onTest(editedProvider) }) {
                        HStack {
                            if isTesting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "bolt.circle")
                            }
                            Text(isTesting ? "测试中..." : "连接测试")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isTesting || !editedProvider.isConfigured)

                    Spacer()

                    Button("保存配置") {
                        onSave(editedProvider)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let result = testResult {
                    Text(result)
                        .font(.callout)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(result.hasPrefix("✅") ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(24)
        }
        .onChange(of: provider.id) { _ in
            editedProvider = provider
        }
    }
}
