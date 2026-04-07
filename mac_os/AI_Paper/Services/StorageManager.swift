import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Storage Manager
final class StorageManager {
    static let shared = StorageManager()
    private init() {}

    // MARK: - Export Text
    func exportText(_ text: String, defaultName: String = "output", completion: ((Bool) -> Void)? = nil) {
        let savePanel = NSSavePanel()
        savePanel.title = "导出文本"
        savePanel.nameFieldStringValue = "\(defaultName).txt"
        savePanel.allowedContentTypes = [.plainText]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                completion?(false)
                return
            }
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }

    // MARK: - Export RTF (Word-like)
    func exportRTF(_ text: String, defaultName: String = "output", completion: ((Bool) -> Void)? = nil) {
        let savePanel = NSSavePanel()
        savePanel.title = "导出为RTF文档"
        savePanel.nameFieldStringValue = "\(defaultName).rtf"
        savePanel.allowedContentTypes = [.rtf]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                completion?(false)
                return
            }

            let attributed = NSAttributedString(string: text, attributes: [
                .font: NSFont(name: "STSong", size: 12) ?? NSFont.systemFont(ofSize: 12)
            ])
            let docAttrs: [NSAttributedString.DocumentAttributeKey: Any] = [
                .documentType: NSAttributedString.DocumentType.rtf
            ]
            do {
                let data = try attributed.data(
                    from: NSRange(location: 0, length: attributed.length),
                    documentAttributes: docAttrs
                )
                try data.write(to: url)
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }

    // MARK: - Import Text File
    func importTextFile(completion: @escaping (String?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "导入文件"
        openPanel.allowedContentTypes = [.plainText, .rtf, UTType(filenameExtension: "doc") ?? .data]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false

        openPanel.begin { response in
            guard response == .OK, let url = openPanel.url else {
                completion(nil)
                return
            }
            do {
                let text = try String(contentsOf: url, encoding: .utf8)
                completion(text)
            } catch {
                // Try other encodings
                if let text = try? String(contentsOf: url, encoding: .utf16) {
                    completion(text)
                } else if let data = try? Data(contentsOf: url),
                          let attr = try? NSAttributedString(
                            data: data,
                            options: [.documentType: NSAttributedString.DocumentType.rtf],
                            documentAttributes: nil
                          ) {
                    completion(attr.string)
                } else {
                    completion(nil)
                }
            }
        }
    }

    // MARK: - Export LaTeX
    func exportLaTeX(_ text: String, defaultName: String = "paper", completion: ((Bool) -> Void)? = nil) {
        let latex = convertToLaTeX(text)
        let savePanel = NSSavePanel()
        savePanel.title = "导出为 LaTeX"
        savePanel.nameFieldStringValue = "\(defaultName).tex"
        if let texType = UTType(filenameExtension: "tex") {
            savePanel.allowedContentTypes = [texType]
        } else {
            savePanel.allowedContentTypes = [.plainText]
        }
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else {
                completion?(false)
                return
            }
            do {
                try latex.write(to: url, atomically: true, encoding: .utf8)
                completion?(true)
            } catch {
                completion?(false)
            }
        }
    }

    // MARK: - LaTeX Conversion
    func convertToLaTeX(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        var latexLines: [String] = []

        latexLines.append("""
        \\documentclass[12pt,a4paper]{article}
        \\usepackage{ctex}
        \\usepackage{geometry}
        \\geometry{left=2.5cm,right=2.5cm,top=3cm,bottom=3cm}
        \\usepackage{hyperref}
        \\begin{document}

        """)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                let title = trimmed.dropFirst(2)
                latexLines.append("\\section{\(escapeLatex(String(title)))}")
            } else if trimmed.hasPrefix("## ") {
                let title = trimmed.dropFirst(3)
                latexLines.append("\\subsection{\(escapeLatex(String(title)))}")
            } else if trimmed.hasPrefix("### ") {
                let title = trimmed.dropFirst(4)
                latexLines.append("\\subsubsection{\(escapeLatex(String(title)))}")
            } else if trimmed.isEmpty {
                latexLines.append("")
            } else {
                latexLines.append(escapeLatex(trimmed))
            }
        }

        latexLines.append("\n\\end{document}")
        return latexLines.joined(separator: "\n")
    }

    private func escapeLatex(_ text: String) -> String {
        var result = text
        let replacements: [(String, String)] = [
            ("\\", "\\textbackslash{}"),
            ("&", "\\&"),
            ("%", "\\%"),
            ("$", "\\$"),
            ("#", "\\#"),
            ("^", "\\^{}"),
            ("_", "\\_"),
            ("{", "\\{"),
            ("}", "\\}"),
            ("~", "\\textasciitilde{}"),
        ]
        for (from, to) in replacements {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }

    // MARK: - Copy to Clipboard
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
