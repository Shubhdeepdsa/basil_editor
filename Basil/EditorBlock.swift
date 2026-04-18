import AppKit

enum EditorBlock: Equatable {
    case paragraph
    case heading(level: Int)
    case bullet
    case divider

    var storageValue: String {
        switch self {
        case .paragraph:
            return "paragraph"
        case .heading(let level):
            return "heading:\(level)"
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
            guard let level = Int(suffix), (1 ... 4).contains(level) else {
                return nil
            }

            self = .heading(level: level)
        }
    }
}

extension NSAttributedString.Key {
    static let editorBlock = NSAttributedString.Key("EditorLabBlock")
}
