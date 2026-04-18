import AppKit

enum EditorTheme {
    static let bulletPrefix = "\u{2022}\t"
    static let dividerPlaceholder = "\u{200B}"
    static let dividerHorizontalInset: CGFloat = 12
    static let bulletIndent: CGFloat = 18
    static let bulletContentIndent: CGFloat = 38

    static let containerInset = NSSize(width: 28, height: 26)

    static func attributes(for block: EditorBlock) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .editorBlock: block.storageValue,
            .ligature: 1
        ]

        switch block {
        case .paragraph:
            attributes[.font] = NSFont.systemFont(ofSize: 17, weight: .regular)
            attributes[.foregroundColor] = NSColor.labelColor
            attributes[.paragraphStyle] = bodyParagraphStyle
        case .heading(let level):
            attributes[.font] = headingFont(for: level)
            attributes[.foregroundColor] = NSColor.labelColor
            attributes[.paragraphStyle] = headingParagraphStyle(for: level)
        case .bullet:
            attributes[.font] = NSFont.systemFont(ofSize: 17, weight: .regular)
            attributes[.foregroundColor] = NSColor.labelColor
            attributes[.paragraphStyle] = bulletParagraphStyle
        case .divider:
            attributes[.font] = NSFont.systemFont(ofSize: 15, weight: .regular)
            attributes[.foregroundColor] = NSColor.clear
            attributes[.paragraphStyle] = dividerParagraphStyle
        }

        return attributes
    }

    private static var bodyParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.paragraphSpacing = 10
        style.paragraphSpacingBefore = 0
        style.lineBreakMode = .byWordWrapping
        return style
    }

    private static func headingParagraphStyle(for level: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.paragraphSpacing = 10
        style.lineBreakMode = .byWordWrapping

        switch level {
        case 1:
            style.paragraphSpacingBefore = 18
            style.paragraphSpacing = 14
        case 2:
            style.paragraphSpacingBefore = 16
            style.paragraphSpacing = 13
        case 3:
            style.paragraphSpacingBefore = 14
            style.paragraphSpacing = 12
        default:
            style.paragraphSpacingBefore = 12
            style.paragraphSpacing = 11
        }

        return style
    }

    private static var bulletParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        style.paragraphSpacing = 8
        style.firstLineHeadIndent = bulletIndent
        style.headIndent = bulletContentIndent
        style.defaultTabInterval = bulletContentIndent
        style.tabStops = [
            NSTextTab(textAlignment: .left, location: bulletContentIndent)
        ]
        return style
    }

    private static var dividerParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 26
        style.maximumLineHeight = 26
        style.paragraphSpacingBefore = 10
        style.paragraphSpacing = 12
        return style
    }

    private static func headingFont(for level: Int) -> NSFont {
        switch level {
        case 1:
            return NSFont.systemFont(ofSize: 30, weight: .bold)
        case 2:
            return NSFont.systemFont(ofSize: 25, weight: .bold)
        case 3:
            return NSFont.systemFont(ofSize: 21, weight: .semibold)
        default:
            return NSFont.systemFont(ofSize: 18, weight: .semibold)
        }
    }
}
