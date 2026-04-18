import AppKit

enum MarkdownEditorBlock: Equatable {
    case paragraph
    case heading(level: MarkdownEditorHeadingLevel)
    case bullet
    case divider

    var storageValue: String {
        switch self {
        case .paragraph:
            return "paragraph"
        case .heading(let level):
            return "heading:\(level.rawValue)"
        case .bullet:
            return "bullet"
        case .divider:
            return "divider"
        }
    }

    init?(storageValue: String) {
        switch storageValue {
        case "paragraph":
            self = .paragraph
        case "bullet":
            self = .bullet
        case "divider":
            self = .divider
        default:
            guard storageValue.hasPrefix("heading:") else {
                return nil
            }

            let suffix = storageValue.replacingOccurrences(of: "heading:", with: "")
            guard
                let rawValue = Int(suffix),
                let level = MarkdownEditorHeadingLevel(rawValue: rawValue)
            else {
                return nil
            }

            self = .heading(level: level)
        }
    }
}

extension NSAttributedString.Key {
    static let markdownEditorBlock = NSAttributedString.Key("EditorLabBlock")
}
