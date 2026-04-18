import AppKit

struct MarkdownEditorParagraphNormalizationResult: Equatable {
    let text: String
    let block: MarkdownEditorBlock
}

struct MarkdownEditorParagraphNormalizer {
    let configuration: MarkdownEditorConfiguration

    func normalizedTarget(
        for text: String,
        existingBlock: MarkdownEditorBlock
    ) -> MarkdownEditorParagraphNormalizationResult {
        if configuration.behavior.enablesDividers,
           text == "---" || (existingBlock == .divider && text == MarkdownEditorThemeResolver.dividerPlaceholder) {
            return MarkdownEditorParagraphNormalizationResult(
                text: MarkdownEditorThemeResolver.dividerPlaceholder,
                block: .divider
            )
        }

        if let level = headingLevel(for: text) {
            let triggerLength = level.rawValue + 1
            let start = text.index(text.startIndex, offsetBy: triggerLength)
            return MarkdownEditorParagraphNormalizationResult(
                text: String(text[start...]),
                block: .heading(level: level)
            )
        }

        if configuration.behavior.enablesBullets, text.hasPrefix("- ") {
            let start = text.index(text.startIndex, offsetBy: 2)
            return MarkdownEditorParagraphNormalizationResult(
                text: MarkdownEditorThemeResolver.bulletPrefix + text[start...],
                block: .bullet
            )
        }

        switch existingBlock {
        case .heading, .bullet, .divider:
            return MarkdownEditorParagraphNormalizationResult(text: text, block: existingBlock)
        case .paragraph:
            return MarkdownEditorParagraphNormalizationResult(text: text, block: .paragraph)
        }
    }

    func headingLevel(for text: String) -> MarkdownEditorHeadingLevel? {
        let triggers: [(String, MarkdownEditorHeadingLevel)] = [
            ("#### ", .h4),
            ("### ", .h3),
            ("## ", .h2),
            ("# ", .h1)
        ]

        return triggers.first {
            configuration.behavior.enabledHeadingLevels.contains($0.1) && text.hasPrefix($0.0)
        }?.1
    }

    func bulletContentText(from text: String) -> String {
        guard text.hasPrefix(MarkdownEditorThemeResolver.bulletPrefix) else {
            return text
        }

        let start = text.index(text.startIndex, offsetBy: MarkdownEditorThemeResolver.bulletPrefix.count)
        return String(text[start...])
    }
}
