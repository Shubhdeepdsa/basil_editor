import AppKit
import Combine

@MainActor
public final class MarkdownEditorState: ObservableObject {
    @Published public var attributedText: NSAttributedString

    public init(attributedText: NSAttributedString = NSAttributedString(string: "")) {
        self.attributedText = attributedText
    }

    public convenience init(text: String) {
        self.init(attributedText: NSAttributedString(string: text))
    }

    public var plainText: String {
        attributedText.string
    }
}
