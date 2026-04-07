import Foundation

// MARK: - Paper Model
struct Paper: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var topic: String
    var style: PaperStyle
    var referenceStyle: ReferenceStyle
    var subject: String
    var outline: String
    var sections: [PaperSection]
    var abstract: String
    var keywords: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String = "",
        topic: String = "",
        style: PaperStyle = .academic,
        referenceStyle: ReferenceStyle = .gbt7714,
        subject: String = "",
        outline: String = "",
        sections: [PaperSection] = [],
        abstract: String = "",
        keywords: [String] = []
    ) {
        self.title = title
        self.topic = topic
        self.style = style
        self.referenceStyle = referenceStyle
        self.subject = subject
        self.outline = outline
        self.sections = sections
        self.abstract = abstract
        self.keywords = keywords
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var fullText: String {
        var parts: [String] = []
        if !abstract.isEmpty {
            parts.append("摘要\n\(abstract)")
        }
        for section in sections {
            parts.append(section.fullContent)
        }
        return parts.joined(separator: "\n\n")
    }

    var wordCount: Int {
        fullText.count
    }
}

// MARK: - Paper Section
struct PaperSection: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var level: Int
    var order: Int

    init(title: String = "", content: String = "", level: Int = 1, order: Int = 0) {
        self.title = title
        self.content = content
        self.level = level
        self.order = order
    }

    var fullContent: String {
        let prefix = String(repeating: "#", count: level)
        return "\(prefix) \(title)\n\n\(content)"
    }
}

// MARK: - Paper Style
enum PaperStyle: String, CaseIterable, Codable {
    case academic = "学术论文"
    case review = "综述论文"
    case experimental = "实验报告"
    case graduation = "毕业论文"
    case conference = "会议论文"
    case journal = "期刊论文"
}

// MARK: - Reference Style
enum ReferenceStyle: String, CaseIterable, Codable {
    case gbt7714 = "GB/T 7714"
    case apa = "APA"
    case mla = "MLA"
    case chicago = "Chicago"
    case vancouver = "Vancouver"
    case ieee = "IEEE"
}
