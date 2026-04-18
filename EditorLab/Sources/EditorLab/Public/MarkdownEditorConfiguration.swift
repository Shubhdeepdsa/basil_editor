import AppKit

/// Supported heading levels for live markdown-style heading conversion.
public enum MarkdownEditorHeadingLevel: Int, CaseIterable, Hashable {
    case h1 = 1
    case h2 = 2
    case h3 = 3
    case h4 = 4
}

/// A text style applied to a specific block type inside the editor.
public struct MarkdownEditorTextStyle: Equatable {
    public var font: NSFont
    public var textColor: NSColor
    public var lineSpacing: CGFloat
    public var paragraphSpacingBefore: CGFloat
    public var paragraphSpacing: CGFloat

    public init(
        font: NSFont,
        textColor: NSColor,
        lineSpacing: CGFloat,
        paragraphSpacingBefore: CGFloat = 0,
        paragraphSpacing: CGFloat
    ) {
        self.font = font
        self.textColor = textColor
        self.lineSpacing = lineSpacing
        self.paragraphSpacingBefore = paragraphSpacingBefore
        self.paragraphSpacing = paragraphSpacing
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.font.isEqual(rhs.font)
            && lhs.textColor.isEqual(rhs.textColor)
            && lhs.lineSpacing == rhs.lineSpacing
            && lhs.paragraphSpacingBefore == rhs.paragraphSpacingBefore
            && lhs.paragraphSpacing == rhs.paragraphSpacing
    }
}

/// Visual configuration for the editor surface and supported block types.
public struct MarkdownEditorTheme: Equatable {
    public var bodyStyle: MarkdownEditorTextStyle
    public var heading1Style: MarkdownEditorTextStyle
    public var heading2Style: MarkdownEditorTextStyle
    public var heading3Style: MarkdownEditorTextStyle
    public var heading4Style: MarkdownEditorTextStyle
    public var bulletStyle: MarkdownEditorTextStyle
    public var editorBackgroundColor: NSColor
    public var contentInset: NSSize
    public var bulletIndent: CGFloat
    public var bulletContentIndent: CGFloat
    public var dividerColor: NSColor
    public var dividerThickness: CGFloat
    public var dividerHorizontalInset: CGFloat
    public var dividerLineHeight: CGFloat
    public var dividerSpacingBefore: CGFloat
    public var dividerSpacing: CGFloat

    public init(
        bodyStyle: MarkdownEditorTextStyle = MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: .labelColor,
            lineSpacing: 5,
            paragraphSpacing: 10
        ),
        heading1Style: MarkdownEditorTextStyle = MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 30, weight: .bold),
            textColor: .labelColor,
            lineSpacing: 3,
            paragraphSpacingBefore: 18,
            paragraphSpacing: 14
        ),
        heading2Style: MarkdownEditorTextStyle = MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 25, weight: .bold),
            textColor: .labelColor,
            lineSpacing: 3,
            paragraphSpacingBefore: 16,
            paragraphSpacing: 13
        ),
        heading3Style: MarkdownEditorTextStyle = MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 21, weight: .semibold),
            textColor: .labelColor,
            lineSpacing: 3,
            paragraphSpacingBefore: 14,
            paragraphSpacing: 12
        ),
        heading4Style: MarkdownEditorTextStyle = MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 18, weight: .semibold),
            textColor: .labelColor,
            lineSpacing: 3,
            paragraphSpacingBefore: 12,
            paragraphSpacing: 11
        ),
        bulletStyle: MarkdownEditorTextStyle = MarkdownEditorTextStyle(
            font: .systemFont(ofSize: 17, weight: .regular),
            textColor: .labelColor,
            lineSpacing: 5,
            paragraphSpacing: 8
        ),
        editorBackgroundColor: NSColor = .textBackgroundColor,
        contentInset: NSSize = NSSize(width: 28, height: 26),
        bulletIndent: CGFloat = 18,
        bulletContentIndent: CGFloat = 38,
        dividerColor: NSColor = .separatorColor,
        dividerThickness: CGFloat = 1,
        dividerHorizontalInset: CGFloat = 12,
        dividerLineHeight: CGFloat = 26,
        dividerSpacingBefore: CGFloat = 10,
        dividerSpacing: CGFloat = 12
    ) {
        self.bodyStyle = bodyStyle
        self.heading1Style = heading1Style
        self.heading2Style = heading2Style
        self.heading3Style = heading3Style
        self.heading4Style = heading4Style
        self.bulletStyle = bulletStyle
        self.editorBackgroundColor = editorBackgroundColor
        self.contentInset = contentInset
        self.bulletIndent = bulletIndent
        self.bulletContentIndent = bulletContentIndent
        self.dividerColor = dividerColor
        self.dividerThickness = dividerThickness
        self.dividerHorizontalInset = dividerHorizontalInset
        self.dividerLineHeight = dividerLineHeight
        self.dividerSpacingBefore = dividerSpacingBefore
        self.dividerSpacing = dividerSpacing
    }

    public func headingStyle(for level: MarkdownEditorHeadingLevel) -> MarkdownEditorTextStyle {
        switch level {
        case .h1:
            heading1Style
        case .h2:
            heading2Style
        case .h3:
            heading3Style
        case .h4:
            heading4Style
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bodyStyle == rhs.bodyStyle
            && lhs.heading1Style == rhs.heading1Style
            && lhs.heading2Style == rhs.heading2Style
            && lhs.heading3Style == rhs.heading3Style
            && lhs.heading4Style == rhs.heading4Style
            && lhs.bulletStyle == rhs.bulletStyle
            && lhs.editorBackgroundColor.isEqual(rhs.editorBackgroundColor)
            && lhs.contentInset == rhs.contentInset
            && lhs.bulletIndent == rhs.bulletIndent
            && lhs.bulletContentIndent == rhs.bulletContentIndent
            && lhs.dividerColor.isEqual(rhs.dividerColor)
            && lhs.dividerThickness == rhs.dividerThickness
            && lhs.dividerHorizontalInset == rhs.dividerHorizontalInset
            && lhs.dividerLineHeight == rhs.dividerLineHeight
            && lhs.dividerSpacingBefore == rhs.dividerSpacingBefore
            && lhs.dividerSpacing == rhs.dividerSpacing
    }
}

/// Behavior switches for live paragraph conversion and editing edge cases.
public struct MarkdownEditorBehavior: Equatable {
    public var enabledHeadingLevels: Set<MarkdownEditorHeadingLevel>
    public var enablesBullets: Bool
    public var enablesDividers: Bool
    public var exitsBulletOnReturnWhenEmpty: Bool
    public var convertsEmptyHeadingOnDeleteBackward: Bool

    public init(
        enabledHeadingLevels: Set<MarkdownEditorHeadingLevel> = Set(MarkdownEditorHeadingLevel.allCases),
        enablesBullets: Bool = true,
        enablesDividers: Bool = true,
        exitsBulletOnReturnWhenEmpty: Bool = true,
        convertsEmptyHeadingOnDeleteBackward: Bool = true
    ) {
        self.enabledHeadingLevels = enabledHeadingLevels
        self.enablesBullets = enablesBullets
        self.enablesDividers = enablesDividers
        self.exitsBulletOnReturnWhenEmpty = exitsBulletOnReturnWhenEmpty
        self.convertsEmptyHeadingOnDeleteBackward = convertsEmptyHeadingOnDeleteBackward
    }
}

/// Root configuration type for the editor.
///
/// Use this to provide visual theme values and enable or disable supported
/// live markdown-style behaviors.
public struct MarkdownEditorConfiguration: Equatable {
    public var theme: MarkdownEditorTheme
    public var behavior: MarkdownEditorBehavior

    public init(
        theme: MarkdownEditorTheme = .init(),
        behavior: MarkdownEditorBehavior = .init()
    ) {
        self.theme = theme
        self.behavior = behavior
    }

    public static var `default`: Self {
        .init()
    }
}
