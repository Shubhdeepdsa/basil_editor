import AppKit
import SwiftUI

@MainActor
struct MarkdownEditorRepresentable: NSViewRepresentable {
    @ObservedObject var state: MarkdownEditorState
    let configuration: MarkdownEditorConfiguration

    func makeCoordinator() -> MarkdownEditorCoordinator {
        MarkdownEditorCoordinator(state: state, configuration: configuration)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = MarkdownEditorTextView(frame: .zero, textContainer: textContainer)
        let scrollView = NSScrollView()
        context.coordinator.configure(textView: textView, in: scrollView)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? MarkdownEditorTextView else {
            return
        }

        context.coordinator.update(
            textView: textView,
            in: nsView,
            state: state,
            configuration: configuration
        )
    }
}
