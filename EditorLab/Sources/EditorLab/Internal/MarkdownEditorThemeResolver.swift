import AppKit

struct MarkdownEditorThemeResolver {
    static let bulletPrefix = "\u{2022}\t"
    static let dividerPlaceholder = "\u{200B}"

    let theme: MarkdownEditorTheme

    func attributes(for block: MarkdownEditorBlock) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .markdownEditorBlock: block.storageValue,
            .ligature: 1
        ]

        switch block {
        case .paragraph:
            attributes[.font] = theme.bodyStyle.font
            attributes[.foregroundColor] = theme.bodyStyle.textColor
            attributes[.paragraphStyle] = paragraphStyle(for: theme.bodyStyle)
        case .heading(let level):
            let style = theme.headingStyle(for: level)
            attributes[.font] = style.font
            attributes[.foregroundColor] = style.textColor
            attributes[.paragraphStyle] = paragraphStyle(for: style)
        case .bullet:
            attributes[.font] = theme.bulletStyle.font
            attributes[.foregroundColor] = theme.bulletStyle.textColor
            attributes[.paragraphStyle] = bulletParagraphStyle
        case .divider:
            attributes[.font] = theme.bodyStyle.font
            attributes[.foregroundColor] = NSColor.clear
            attributes[.paragraphStyle] = dividerParagraphStyle
        }

        return attributes
    }

    private func paragraphStyle(for style: MarkdownEditorTextStyle) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = style.lineSpacing
        paragraphStyle.paragraphSpacingBefore = style.paragraphSpacingBefore
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        return paragraphStyle
    }

    private var bulletParagraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = theme.bulletStyle.lineSpacing
        paragraphStyle.paragraphSpacingBefore = theme.bulletStyle.paragraphSpacingBefore
        paragraphStyle.paragraphSpacing = theme.bulletStyle.paragraphSpacing
        paragraphStyle.firstLineHeadIndent = theme.bulletIndent
        paragraphStyle.headIndent = theme.bulletContentIndent
        paragraphStyle.defaultTabInterval = theme.bulletContentIndent
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: theme.bulletContentIndent)
        ]
        return paragraphStyle
    }

    private var dividerParagraphStyle: NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = theme.dividerLineHeight
        paragraphStyle.maximumLineHeight = theme.dividerLineHeight
        paragraphStyle.paragraphSpacingBefore = theme.dividerSpacingBefore
        paragraphStyle.paragraphSpacing = theme.dividerSpacing
        return paragraphStyle
    }
}
