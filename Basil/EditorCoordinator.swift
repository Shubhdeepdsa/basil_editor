import AppKit

final class EditorCoordinator: NSObject, NSTextViewDelegate, EditorTextViewCommandHandling {
    private weak var textView: EditorTextView?
    private var isPerformingProgrammaticEdit = false
    private var trailingEmptyBlock: EditorBlock = .paragraph

    func configure(textView: EditorTextView) {
        self.textView = textView
        textView.delegate = self
        textView.commandHandler = self

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.usesFindBar = true
        textView.usesInspectorBar = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true

        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.insertionPointColor = .labelColor
        textView.textContainerInset = EditorTheme.containerInset
        textView.textContainer?.lineFragmentPadding = 0
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
    }

    func textDidChange(_ notification: Notification) {
        guard
            let textView = notification.object as? EditorTextView,
            !isPerformingProgrammaticEdit
        else {
            return
        }

        transformCurrentParagraphIfNeeded(in: textView)

        if !hasEmptyTrailingParagraph(in: textView) {
            trailingEmptyBlock = .paragraph
        }

        syncTypingAttributes(in: textView)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard
            let textView = notification.object as? EditorTextView,
            !isPerformingProgrammaticEdit
        else {
            return
        }

        syncTypingAttributes(in: textView)
    }

    func editorTextViewHandleInsertNewline(_ textView: EditorTextView) -> Bool {
        let currentBlock = blockAtInsertionPoint(in: textView)

        switch currentBlock {
        case .heading:
            insertNewline(with: .paragraph, in: textView)
            trailingEmptyBlock = .paragraph
            return true
        case .bullet:
            return handleBulletReturn(in: textView)
        case .divider:
            return handleDividerReturn(in: textView)
        default:
            return false
        }
    }

    func editorTextViewHandleDeleteBackward(_ textView: EditorTextView) -> Bool {
        guard textView.selectedRange().length == 0 else {
            return false
        }

        if handleEmptyHeadingBackspace(in: textView) {
            return true
        }

        if handleEmptyBulletBackspace(in: textView) {
            return true
        }

        return false
    }

    private func transformCurrentParagraphIfNeeded(in textView: EditorTextView) {
        guard let context = paragraphContextAroundSelection(in: textView) else {
            return
        }

        if context.text == "---" {
            convertToDivider(context: context, in: textView)
            return
        }

        if let level = headingLevel(for: context.text) {
            convertToHeading(level: level, context: context, in: textView)
            return
        }

        if context.text.hasPrefix("- ") {
            convertToBullet(context: context, in: textView)
        }
    }

    private func convertToHeading(level: Int, context: ParagraphContext, in textView: EditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let triggerLength = level + 1
        let selectionAfterRemoval = adjustedSelectionAfterRemovingPrefix(
            selection: textView.selectedRange(),
            prefixLength: triggerLength,
            at: context.paragraphRange.location
        )
        let headingBlock: EditorBlock = .heading(level: level)

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(
                in: NSRange(location: context.paragraphRange.location, length: triggerLength),
                with: ""
            )

            if context.paragraphRange.location < textStorage.length,
               let updatedRange = paragraphRange(at: context.paragraphRange.location, in: textStorage) {
                applyBlock(headingBlock, to: updatedRange, in: textStorage)
            }

            if hasEmptyTrailingParagraph(in: textView), selectionAfterRemoval.location == textStorage.length {
                trailingEmptyBlock = headingBlock
            }
        }

        DispatchQueue.main.async { [weak textView] in
            guard let textView else {
                return
            }

            textView.setSelectedRange(selectionAfterRemoval)
            textView.typingAttributes = EditorTheme.attributes(for: headingBlock)
        }
    }

    private func convertToBullet(context: ParagraphContext, in textView: EditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let originalSelection = textView.selectedRange()
        let replacement = EditorTheme.bulletPrefix
        let selectionAfterReplacement = adjustedSelectionForReplacement(
            selection: originalSelection,
            replacedRange: NSRange(location: context.paragraphRange.location, length: 2),
            replacementLength: replacement.utf16.count
        )

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(
                in: NSRange(location: context.paragraphRange.location, length: 2),
                with: replacement
            )

            if let updatedRange = paragraphRange(at: context.paragraphRange.location, in: textStorage) {
                applyBlock(.bullet, to: updatedRange, in: textStorage)
            }

            textView.setSelectedRange(selectionAfterReplacement)
            textView.typingAttributes = EditorTheme.attributes(for: .bullet)
        }
    }

    private func convertToDivider(context: ParagraphContext, in textView: EditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let replacement: String
        var selectionLocation = context.paragraphRange.location

        if context.endsAtDocumentEnd {
            replacement = EditorTheme.dividerPlaceholder + "\n"
            trailingEmptyBlock = .paragraph
        } else {
            replacement = EditorTheme.dividerPlaceholder
        }

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: context.contentRange, with: replacement)

            guard let dividerRange = paragraphRange(at: context.paragraphRange.location, in: textStorage) else {
                return
            }

            applyBlock(.divider, to: dividerRange, in: textStorage)

            selectionLocation = NSMaxRange(dividerRange)

            if selectionLocation < textStorage.length, let bodyRange = paragraphRange(at: selectionLocation, in: textStorage) {
                applyBlock(.paragraph, to: bodyRange, in: textStorage)
            }
        }

        DispatchQueue.main.async { [weak textView] in
            guard let textView else {
                return
            }

            textView.setSelectedRange(NSRange(location: selectionLocation, length: 0))
            textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
        }
    }

    private func handleBulletReturn(in textView: EditorTextView) -> Bool {
        guard
            let context = paragraphContextAroundSelection(in: textView),
            let textStorage = textView.textStorage
        else {
            return false
        }

        let bulletContent = bulletContentText(from: context.text)

        if bulletContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let selectionLocation = context.paragraphRange.location

            performProgrammaticEdit(in: textView) {
                textStorage.replaceCharacters(in: context.contentRange, with: "")

                if selectionLocation < textStorage.length,
                   let updatedRange = paragraphRange(at: selectionLocation, in: textStorage) {
                    applyBlock(.paragraph, to: updatedRange, in: textStorage)
                }

                trailingEmptyBlock = .paragraph
            }

            DispatchQueue.main.async { [weak textView] in
                guard let textView else {
                    return
                }

                textView.setSelectedRange(NSRange(location: selectionLocation, length: 0))
                textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
            }
            return true
        }

        let insertion = "\n" + EditorTheme.bulletPrefix
        let insertionRange = textView.selectedRange()
        let newSelectionLocation = insertionRange.location + insertion.utf16.count

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: insertionRange, with: insertion)

            if let newParagraphRange = paragraphRange(at: newSelectionLocation, in: textStorage) {
                applyBlock(.bullet, to: newParagraphRange, in: textStorage)
            }

            textView.setSelectedRange(NSRange(location: newSelectionLocation, length: 0))
            textView.typingAttributes = EditorTheme.attributes(for: .bullet)
            trailingEmptyBlock = hasEmptyTrailingParagraph(in: textView) ? .bullet : .paragraph
        }

        return true
    }

    private func handleDividerReturn(in textView: EditorTextView) -> Bool {
        guard let textStorage = textView.textStorage else {
            return false
        }

        let selection = textView.selectedRange()
        let insertion = "\n"
        let newSelectionLocation = selection.location + 1

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: selection, with: insertion)
            if newSelectionLocation < textStorage.length, let newParagraphRange = paragraphRange(at: newSelectionLocation, in: textStorage) {
                applyBlock(.paragraph, to: newParagraphRange, in: textStorage)
            }

            textView.setSelectedRange(NSRange(location: newSelectionLocation, length: 0))
            textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
            trailingEmptyBlock = hasEmptyTrailingParagraph(in: textView) ? .paragraph : trailingEmptyBlock
        }

        return true
    }

    private func insertNewline(with block: EditorBlock, in textView: EditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let selection = textView.selectedRange()
        let newSelectionLocation = selection.location + 1

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: selection, with: "\n")

            if newSelectionLocation < textStorage.length, let newParagraphRange = paragraphRange(at: newSelectionLocation, in: textStorage) {
                applyBlock(block, to: newParagraphRange, in: textStorage)
            }

            textView.setSelectedRange(NSRange(location: newSelectionLocation, length: 0))
            textView.typingAttributes = EditorTheme.attributes(for: block)
            trailingEmptyBlock = hasEmptyTrailingParagraph(in: textView) ? block : .paragraph
        }
    }

    private func handleEmptyHeadingBackspace(in textView: EditorTextView) -> Bool {
        let currentBlock = blockAtInsertionPoint(in: textView)

        guard case .heading = currentBlock else {
            return false
        }

        guard textView.selectedRange().length == 0 else {
            return false
        }

        if hasEmptyTrailingParagraph(in: textView), textView.selectedRange().location == textView.string.utf16.count {
            trailingEmptyBlock = .paragraph
            textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
            return true
        }

        guard
            let context = paragraphContextAroundSelection(in: textView),
            context.text.isEmpty,
            textView.selectedRange().location == context.paragraphRange.location
        else {
            return false
        }

        guard let textStorage = textView.textStorage else {
            return false
        }

        performProgrammaticEdit(in: textView) {
            applyBlock(.paragraph, to: context.paragraphRange, in: textStorage)
            textView.setSelectedRange(NSRange(location: context.paragraphRange.location, length: 0))
            textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
        }

        return true
    }

    private func handleEmptyBulletBackspace(in textView: EditorTextView) -> Bool {
        guard
            let context = paragraphContextAroundSelection(in: textView),
            context.block == .bullet,
            bulletContentText(from: context.text).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            textView.selectedRange().location == context.paragraphRange.location + EditorTheme.bulletPrefix.utf16.count,
            let textStorage = textView.textStorage
        else {
            return false
        }

        let selectionLocation = context.paragraphRange.location

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: context.contentRange, with: "")

            if selectionLocation < textStorage.length,
               let updatedRange = paragraphRange(at: selectionLocation, in: textStorage) {
                applyBlock(.paragraph, to: updatedRange, in: textStorage)
            }

            trailingEmptyBlock = .paragraph
        }

        DispatchQueue.main.async { [weak textView] in
            guard let textView else {
                return
            }

            textView.setSelectedRange(NSRange(location: selectionLocation, length: 0))
            textView.typingAttributes = EditorTheme.attributes(for: .paragraph)
        }

        return true
    }

    private func syncTypingAttributes(in textView: EditorTextView) {
        let block = blockAtInsertionPoint(in: textView)
        textView.typingAttributes = EditorTheme.attributes(for: block)
    }

    private func blockAtInsertionPoint(in textView: EditorTextView) -> EditorBlock {
        let selection = textView.selectedRange()

        if hasEmptyTrailingParagraph(in: textView), selection.length == 0, selection.location == textView.string.utf16.count {
            return trailingEmptyBlock
        }

        return paragraphContextAroundSelection(in: textView)?.block ?? .paragraph
    }

    private func headingLevel(for text: String) -> Int? {
        let triggers = [
            ("#### ", 4),
            ("### ", 3),
            ("## ", 2),
            ("# ", 1)
        ]

        return triggers.first(where: { text.hasPrefix($0.0) })?.1
    }

    private func applyBlock(_ block: EditorBlock, to range: NSRange, in textStorage: NSTextStorage) {
        textStorage.setAttributes(EditorTheme.attributes(for: block), range: range)
    }

    private func paragraphRange(at location: Int, in textStorage: NSTextStorage) -> NSRange? {
        let string = textStorage.string as NSString
        let length = string.length

        guard length > 0 else {
            return nil
        }

        let safeLocation = min(max(location, 0), max(length - 1, 0))
        return string.paragraphRange(for: NSRange(location: safeLocation, length: 0))
    }

    private func paragraphContextAroundSelection(in textView: NSTextView) -> ParagraphContext? {
        let string = textView.string as NSString
        let length = string.length

        guard length > 0 else {
            return nil
        }

        let selection = textView.selectedRange()
        let probeLocation = min(max(selection.location, 0), length - 1)
        let paragraphRange = string.paragraphRange(for: NSRange(location: probeLocation, length: 0))
        let endsWithNewline = paragraphRange.length > 0 && NSMaxRange(paragraphRange) <= length && string.substring(with: NSRange(location: NSMaxRange(paragraphRange) - 1, length: 1)) == "\n"
        let contentRange = endsWithNewline
            ? NSRange(location: paragraphRange.location, length: paragraphRange.length - 1)
            : paragraphRange

        let rawValue = textView.textStorage?.attribute(.editorBlock, at: paragraphRange.location, effectiveRange: nil) as? String
        let block: EditorBlock

        if let rawValue, let decodedBlock = EditorBlock(storageValue: rawValue) {
            block = decodedBlock
        } else {
            block = .paragraph
        }

        return ParagraphContext(
            paragraphRange: paragraphRange,
            contentRange: contentRange,
            text: string.substring(with: contentRange),
            block: block,
            endsAtDocumentEnd: NSMaxRange(paragraphRange) == length
        )
    }

    private func bulletContentText(from text: String) -> String {
        guard text.hasPrefix(EditorTheme.bulletPrefix) else {
            return text
        }

        let start = text.index(text.startIndex, offsetBy: EditorTheme.bulletPrefix.count)
        return String(text[start...])
    }

    private func adjustedSelectionAfterRemovingPrefix(selection: NSRange, prefixLength: Int, at paragraphStart: Int) -> NSRange {
        let location: Int

        if selection.location <= paragraphStart + prefixLength {
            location = paragraphStart
        } else {
            location = selection.location - prefixLength
        }

        return NSRange(location: location, length: selection.length)
    }

    private func adjustedSelectionForReplacement(selection: NSRange, replacedRange: NSRange, replacementLength: Int) -> NSRange {
        let delta = replacementLength - replacedRange.length

        if selection.location <= replacedRange.location {
            return selection
        }

        return NSRange(location: selection.location + delta, length: selection.length)
    }

    private func hasEmptyTrailingParagraph(in textView: NSTextView) -> Bool {
        let text = textView.string
        return text.isEmpty || text.hasSuffix("\n")
    }

    private func performProgrammaticEdit(in textView: EditorTextView, _ edits: () -> Void) {
        guard let textStorage = textView.textStorage else {
            return
        }

        isPerformingProgrammaticEdit = true
        textStorage.beginEditing()
        edits()
        textStorage.endEditing()
        isPerformingProgrammaticEdit = false

        textView.needsDisplay = true
    }
}

private struct ParagraphContext {
    let paragraphRange: NSRange
    let contentRange: NSRange
    let text: String
    let block: EditorBlock
    let endsAtDocumentEnd: Bool
}
