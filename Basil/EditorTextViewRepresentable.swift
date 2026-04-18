import AppKit
import SwiftUI

struct EditorTextViewRepresentable: NSViewRepresentable {
    func makeCoordinator() -> EditorCoordinator {
        EditorCoordinator()
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

        let textView = EditorTextView(frame: NSRect.zero, textContainer: textContainer)
        context.coordinator.configure(textView: textView)

        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
    }
}
