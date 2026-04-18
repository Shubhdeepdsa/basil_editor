import AppKit
import Combine

/// Observable editor state exposed to host apps.
///
/// The current public surface is attributed text plus a plain text convenience
/// accessor. Host apps should own this object and pass it to
/// ``MarkdownEditorView``.
@MainActor
public final class MarkdownEditorState: ObservableObject {
    @Published public var attributedText: NSAttributedString

    /// Creates editor state with an attributed text snapshot.
    public init(attributedText: NSAttributedString = NSAttributedString(string: "")) {
        self.attributedText = attributedText
    }

    /// Creates editor state from plain text.
    public convenience init(text: String) {
        self.init(attributedText: NSAttributedString(string: text))
    }

    /// The editor contents as plain text.
    public var plainText: String {
        attributedText.string
    }
}
