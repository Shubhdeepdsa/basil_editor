import AppKit

@MainActor
protocol MarkdownEditorTextViewCommandHandling: AnyObject {
    func markdownEditorTextViewHandleInsertNewline(_ textView: MarkdownEditorTextView) -> Bool
    func markdownEditorTextViewHandleDeleteBackward(_ textView: MarkdownEditorTextView) -> Bool
    func markdownEditorTextViewWillPaste(_ textView: MarkdownEditorTextView)
}

@MainActor
final class MarkdownEditorTextView: NSTextView {
    weak var commandHandler: MarkdownEditorTextViewCommandHandling?
    var theme: MarkdownEditorTheme = .init()

    override func doCommand(by selector: Selector) {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            if commandHandler?.markdownEditorTextViewHandleInsertNewline(self) == true {
                return
            }
        case #selector(NSResponder.deleteBackward(_:)):
            if commandHandler?.markdownEditorTextViewHandleDeleteBackward(self) == true {
                return
            }
        default:
            break
        }

        super.doCommand(by: selector)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawDividers(in: dirtyRect)
    }

    override func paste(_ sender: Any?) {
        commandHandler?.markdownEditorTextViewWillPaste(self)
        super.paste(sender)
    }

    private func drawDividers(in dirtyRect: NSRect) {
        guard
            let textStorage,
            let layoutManager,
            let textContainer,
            textStorage.length > 0
        else {
            return
        }

        let origin = textContainerOrigin
        let visibleRectInContainer = visibleRect.offsetBy(dx: -origin.x, dy: -origin.y)
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRectInContainer, in: textContainer)
        let visibleCharacterRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        textStorage.enumerateAttribute(.markdownEditorBlock, in: visibleCharacterRange) { value, range, _ in
            guard
                let rawValue = value as? String,
                let block = MarkdownEditorBlock(storageValue: rawValue),
                block == .divider
            else {
                return
            }

            let glyphIndex = layoutManager.glyphIndexForCharacter(at: range.location)
            let lineRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex,
                effectiveRange: nil,
                withoutAdditionalLayout: true
            )
            let thickness = max(theme.dividerThickness, 1)
            let ruleRect = NSRect(
                x: origin.x + theme.dividerHorizontalInset,
                y: floor(origin.y + lineRect.midY - (thickness / 2)),
                width: max(0, textContainer.size.width - (theme.dividerHorizontalInset * 2)),
                height: thickness
            )

            guard ruleRect.intersects(dirtyRect) else {
                return
            }

            theme.dividerColor.withAlphaComponent(0.75).setFill()
            NSBezierPath(rect: ruleRect).fill()
        }
    }
}
