import AppKit

protocol EditorTextViewCommandHandling: AnyObject {
    func editorTextViewHandleInsertNewline(_ textView: EditorTextView) -> Bool
    func editorTextViewHandleDeleteBackward(_ textView: EditorTextView) -> Bool
}

final class EditorTextView: NSTextView {
    weak var commandHandler: EditorTextViewCommandHandling?

    override func doCommand(by selector: Selector) {
        switch selector {
        case #selector(NSResponder.insertNewline(_:)):
            if commandHandler?.editorTextViewHandleInsertNewline(self) == true {
                return
            }
        case #selector(NSResponder.deleteBackward(_:)):
            if commandHandler?.editorTextViewHandleDeleteBackward(self) == true {
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

        textStorage.enumerateAttribute(.editorBlock, in: visibleCharacterRange) { value, range, _ in
            guard let rawValue = value as? String else {
                return
            }

            guard let block = EditorBlock(storageValue: rawValue), block == .divider else {
                return
            }

            let glyphIndex = layoutManager.glyphIndexForCharacter(at: range.location)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil, withoutAdditionalLayout: true)
            let ruleRect = NSRect(
                x: origin.x + EditorTheme.dividerHorizontalInset,
                y: floor(origin.y + lineRect.midY),
                width: max(0, textContainer.size.width - (EditorTheme.dividerHorizontalInset * 2)),
                height: 1
            )

            guard ruleRect.intersects(dirtyRect) else {
                return
            }

            NSColor.separatorColor.withAlphaComponent(0.75).setFill()
            NSBezierPath(rect: ruleRect).fill()
        }
    }
}
