# 纸研社 - macOS Swift 版本

基于 SwiftUI 实现的 macOS 原生论文写作助手应用，对应 Windows Python 版本功能。

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

## 功能特性

| 功能 | 描述 |
|------|------|
| 📄 论文写作 | AI 智能大纲生成、章节撰写、摘要生成 |
| 🪄 降 AI 检测 | 三种改写力度（轻度去痕、深度重构、学术拟合） |
| 🛡️ 降查重率 | 语义改写，保持学术严谨性 |
| 🖌️ 学术润色 | 5 种润色模式，全面提升文本质量 |
| ⚠️ 智能纠错 | 8 大纠错类别，全面检查文本问题 |
| 📚 历史记录 | 查看、搜索、收藏历史处理结果 |
| ⚙️ API 配置 | 支持 20+ AI 服务商配置 |

## 支持的 AI 服务商

- OpenAI (GPT-4o 等)
- DeepSeek
- Claude (Anthropic)
- 智谱 GLM
- 通义千问
- 字节豆包
- 月之暗面 (Moonshot)
- MiniMax
- 零一万物
- 硅基流动 (SiliconFlow)
- 百川智能
- 腾讯混元
- 商汤日日新
- 阶跃星辰
- 百度文心一言
- 科大讯飞星火
- 360 智脑
- 昆仑天工
- 自定义 API（兼容 OpenAI 格式）

## 项目结构

```
mac_os/
├── Package.swift                 # Swift Package Manager 配置
├── AI_Paper.xcodeproj/           # Xcode 项目文件
├── AI_Paper/
│   ├── AI_PaperApp.swift         # 应用程序入口
│   ├── ContentView.swift         # 主导航界面
│   ├── Views/
│   │   ├── HomePageView.swift    # 首页
│   │   ├── PaperWriteView.swift  # 论文写作
│   │   ├── AIReduceView.swift    # 降 AI 检测
│   │   ├── PlagiarismView.swift  # 降查重率
│   │   ├── PolishView.swift      # 学术润色
│   │   ├── CorrectionView.swift  # 智能纠错
│   │   ├── HistoryView.swift     # 历史记录
│   │   └── APIConfigView.swift   # API 配置
│   ├── Models/
│   │   ├── Paper.swift           # 论文数据模型
│   │   ├── HistoryRecord.swift   # 历史记录模型
│   │   ├── APIConfig.swift       # API 配置模型（含 20+ 服务商预设）
│   │   └── UsageStats.swift      # 使用统计模型
│   ├── Services/
│   │   ├── APIClient.swift       # AI API 客户端（支持 OpenAI/Claude/百度/星火）
│   │   ├── ConfigManager.swift   # 配置管理（UserDefaults 持久化）
│   │   ├── HistoryManager.swift  # 历史记录管理
│   │   └── StorageManager.swift  # 文件导入/导出（TXT/RTF/LaTeX）
│   └── Utilities/
│       ├── Constants.swift       # 全局常量（改写模式、纠错类别等）
│       ├── Extensions.swift      # Swift 扩展（Date、String、View）
│       └── Helpers.swift         # 提示词构建器、文本分析器
└── AI_PaperTests/
    └── AI_PaperTests.swift       # 单元测试
```

## 快速开始

### 方式一：使用 Xcode

1. 在 Xcode 中打开 `AI_Paper.xcodeproj`
2. 选择 macOS 目标
3. 点击运行（⌘R）

### 方式二：使用 Swift Package Manager

```bash
cd mac_os
swift build
swift run AI_Paper
```

### 运行测试

```bash
cd mac_os
swift test
```

## 架构说明

### 核心架构

```
UI Layer (SwiftUI Views)
        ↓
Services Layer (ConfigManager, HistoryManager, APIClient)
        ↓
Models Layer (Paper, HistoryRecord, APIConfig)
```

### 数据持久化

- **API 配置**：通过 `UserDefaults` 安全存储（API Key 存储在本地）
- **历史记录**：通过 `UserDefaults` 持久化（最多保留 500 条）

### API 通信

`APIClient` 支持三种 API 协议：
- **OpenAI 兼容格式**：用于 OpenAI、DeepSeek、智谱、通义等大多数服务商
- **Claude 格式**：专用于 Anthropic Claude API
- **百度格式**：专用于百度文心一言（需要 Access Token 流程）

## 配置 API

1. 启动应用后点击左侧「API配置」
2. 从服务商列表中选择您的 AI 服务商
3. 填入对应的 API Key
4. 点击「连接测试」验证配置
5. 点击「设为当前」激活该服务商
6. 点击「保存配置」

## 文件导入/导出

- **导入**：支持 TXT、RTF 格式文件导入
- **导出**：支持导出为 TXT、RTF、LaTeX（.tex）格式
- **剪贴板**：支持一键复制到系统剪贴板

## 与 Windows 版本的对比

| 特性 | Windows 版本 | macOS 版本 |
|------|-------------|------------|
| UI 框架 | Python / Tkinter | SwiftUI |
| 数据存储 | JSON 文件 | UserDefaults |
| API 支持 | 20+ 服务商 | 20+ 服务商 ✅ |
| 功能模块 | 完整 | 完整 ✅ |
| 文件导出 | Word (.docx) | TXT / RTF / LaTeX |
| 设计风格 | Windows 原生 | macOS 原生 HIG |
