import AppKit

@MainActor
final class MarkdownEditorCoordinator: NSObject, NSTextViewDelegate, MarkdownEditorTextViewCommandHandling {
    private weak var textView: MarkdownEditorTextView?
    private var state: MarkdownEditorState
    private var configuration: MarkdownEditorConfiguration
    private var isPerformingProgrammaticEdit = false
    private var isApplyingExternalState = false
    private var shouldNormalizeAfterPaste = false
    private var trailingEmptyBlock: MarkdownEditorBlock = .paragraph

    init(state: MarkdownEditorState, configuration: MarkdownEditorConfiguration) {
        self.state = state
        self.configuration = configuration
    }

    func configure(textView: MarkdownEditorTextView, in scrollView: NSScrollView) {
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

        textView.textContainer?.lineFragmentPadding = 0
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        applyVisualConfiguration(to: textView, in: scrollView)
        syncTextViewFromState(force: true, in: textView)
    }

    func update(
        textView: MarkdownEditorTextView,
        in scrollView: NSScrollView,
        state: MarkdownEditorState,
        configuration: MarkdownEditorConfiguration
    ) {
        self.state = state

        if self.configuration != configuration {
            self.configuration = configuration
            applyVisualConfiguration(to: textView, in: scrollView)
            restyleDocument(in: textView)
            syncTypingAttributes(in: textView)
            publishStateSnapshot(from: textView)
        }

        syncTextViewFromState(force: false, in: textView)
    }

    func textDidChange(_ notification: Notification) {
        guard
            let textView = notification.object as? MarkdownEditorTextView,
            !isPerformingProgrammaticEdit
        else {
            return
        }

        if shouldNormalizeAfterPaste {
            shouldNormalizeAfterPaste = false
            normalizeDocumentAfterPaste(in: textView)
        } else {
            transformCurrentParagraphIfNeeded(in: textView)
        }

        if !hasEmptyTrailingParagraph(in: textView) {
            trailingEmptyBlock = .paragraph
        }

        syncTypingAttributes(in: textView)
        publishStateSnapshot(from: textView)
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        guard
            let textView = notification.object as? MarkdownEditorTextView,
            !isPerformingProgrammaticEdit
        else {
            return
        }

        syncTypingAttributes(in: textView)
    }

    func markdownEditorTextViewHandleInsertNewline(_ textView: MarkdownEditorTextView) -> Bool {
        switch blockAtInsertionPoint(in: textView) {
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

    func markdownEditorTextViewHandleDeleteBackward(_ textView: MarkdownEditorTextView) -> Bool {
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

    func markdownEditorTextViewWillPaste(_ textView: MarkdownEditorTextView) {
        shouldNormalizeAfterPaste = true
    }

    private var themeResolver: MarkdownEditorThemeResolver {
        MarkdownEditorThemeResolver(theme: configuration.theme)
    }

    private var paragraphNormalizer: MarkdownEditorParagraphNormalizer {
        MarkdownEditorParagraphNormalizer(configuration: configuration)
    }

    private func applyVisualConfiguration(to textView: MarkdownEditorTextView, in _: NSScrollView) {
        textView.theme = configuration.theme
        textView.backgroundColor = configuration.theme.editorBackgroundColor
        textView.drawsBackground = true
        textView.insertionPointColor = configuration.theme.bodyStyle.textColor
        textView.textContainerInset = configuration.theme.contentInset
        textView.needsDisplay = true
    }

    private func syncTextViewFromState(force: Bool, in textView: MarkdownEditorTextView) {
        let currentSnapshot = textView.attributedString()
        let desiredSnapshot = state.attributedText

        guard force || !currentSnapshot.isEqual(desiredSnapshot) else {
            return
        }

        let preservedSelection = textView.selectedRange()
        isApplyingExternalState = true

        performProgrammaticEdit(in: textView) {
            textView.textStorage?.setAttributedString(desiredSnapshot)
            normalizeEntireDocument(in: textView)
        }

        isApplyingExternalState = false

        let clampedLocation = min(preservedSelection.location, textView.string.utf16.count)
        textView.setSelectedRange(NSRange(location: clampedLocation, length: 0))
        trailingEmptyBlock = .paragraph
        syncTypingAttributes(in: textView)
        publishStateSnapshot(from: textView)
    }

    private func publishStateSnapshot(from textView: MarkdownEditorTextView) {
        guard !isApplyingExternalState else {
            return
        }

        let snapshot = NSAttributedString(attributedString: textView.attributedString())
        guard !state.attributedText.isEqual(snapshot) else {
            return
        }

        isApplyingExternalState = true
        state.attributedText = snapshot
        isApplyingExternalState = false
    }

    private func restyleDocument(in textView: MarkdownEditorTextView) {
        guard
            let textStorage = textView.textStorage,
            textStorage.length > 0
        else {
            textView.typingAttributes = themeResolver.attributes(for: .paragraph)
            return
        }

        let string = textStorage.string as NSString
        var location = 0

        while location < string.length {
            let paragraphRange = string.paragraphRange(for: NSRange(location: location, length: 0))
            let block = blockForParagraph(at: paragraphRange.location, in: textStorage)
            applyBlock(block, to: paragraphRange, in: textStorage)
            location = NSMaxRange(paragraphRange)
        }

        textView.theme = configuration.theme
        textView.needsDisplay = true
    }

    private func normalizeDocumentAfterPaste(in textView: MarkdownEditorTextView) {
        let preservedSelection = textView.selectedRange()

        performProgrammaticEdit(in: textView) {
            normalizeEntireDocument(in: textView)
        }

        let clampedLocation = min(preservedSelection.location, textView.string.utf16.count)
        textView.setSelectedRange(NSRange(location: clampedLocation, length: 0))
    }

    private func normalizeEntireDocument(in textView: MarkdownEditorTextView) {
        guard
            let textStorage = textView.textStorage,
            textStorage.length > 0
        else {
            textView.typingAttributes = themeResolver.attributes(for: .paragraph)
            return
        }

        var location = 0

        while location < textStorage.length {
            guard let currentParagraphRange = paragraphRange(at: location, in: textStorage) else {
                break
            }

            let nextLocation = normalizeParagraph(in: currentParagraphRange, textStorage: textStorage)
            if nextLocation <= location {
                break
            }
            location = nextLocation
        }

        textView.theme = configuration.theme
        textView.needsDisplay = true
    }

    @discardableResult
    private func normalizeParagraph(in currentParagraphRange: NSRange, textStorage: NSTextStorage) -> Int {
        let string = textStorage.string as NSString
        let contentRange = contentRange(for: currentParagraphRange, in: string)
        let text = string.substring(with: contentRange)
        let existingBlock = blockForParagraph(at: currentParagraphRange.location, in: textStorage)
        let target = paragraphNormalizer.normalizedTarget(for: text, existingBlock: existingBlock)

        if text != target.text {
            textStorage.replaceCharacters(in: contentRange, with: target.text)
        }

        guard let updatedRange = paragraphRange(at: currentParagraphRange.location, in: textStorage) else {
            return textStorage.length
        }

        applyBlock(target.block, to: updatedRange, in: textStorage)
        return NSMaxRange(updatedRange)
    }

    private func contentRange(for paragraphRange: NSRange, in string: NSString) -> NSRange {
        let endsWithNewline = paragraphRange.length > 0
            && NSMaxRange(paragraphRange) <= string.length
            && string.substring(with: NSRange(location: NSMaxRange(paragraphRange) - 1, length: 1)) == "\n"

        return endsWithNewline
            ? NSRange(location: paragraphRange.location, length: paragraphRange.length - 1)
            : paragraphRange
    }

    private func transformCurrentParagraphIfNeeded(in textView: MarkdownEditorTextView) {
        guard let context = paragraphContextAroundSelection(in: textView) else {
            return
        }

        if configuration.behavior.enablesDividers, context.text == "---" {
            convertToDivider(context: context, in: textView)
            return
        }

        if let level = paragraphNormalizer.headingLevel(for: context.text) {
            convertToHeading(level: level, context: context, in: textView)
            return
        }

        if configuration.behavior.enablesBullets, context.text.hasPrefix("- ") {
            convertToBullet(context: context, in: textView)
        }
    }

    private func convertToHeading(
        level: MarkdownEditorHeadingLevel,
        context: ParagraphContext,
        in textView: MarkdownEditorTextView
    ) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let triggerLength = level.rawValue + 1
        let selectionAfterRemoval = MarkdownEditorSelectionAdjuster.afterRemovingPrefix(
            selection: textView.selectedRange(),
            prefixLength: triggerLength,
            at: context.paragraphRange.location
        )
        let headingBlock = MarkdownEditorBlock.heading(level: level)

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

        Task { [weak textView] in
            await MainActor.run {
                guard let textView else {
                    return
                }

                textView.setSelectedRange(selectionAfterRemoval)
                textView.typingAttributes = self.themeResolver.attributes(for: headingBlock)
                self.publishStateSnapshot(from: textView)
            }
        }
    }

    private func convertToBullet(context: ParagraphContext, in textView: MarkdownEditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let replacement = MarkdownEditorThemeResolver.bulletPrefix
        let selectionAfterReplacement = MarkdownEditorSelectionAdjuster.forReplacement(
            selection: textView.selectedRange(),
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
            textView.typingAttributes = themeResolver.attributes(for: .bullet)
        }
    }

    private func convertToDivider(context: ParagraphContext, in textView: MarkdownEditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let replacement: String
        var selectionLocation = context.paragraphRange.location

        if context.endsAtDocumentEnd {
            replacement = MarkdownEditorThemeResolver.dividerPlaceholder + "\n"
            trailingEmptyBlock = .paragraph
        } else {
            replacement = MarkdownEditorThemeResolver.dividerPlaceholder
        }

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: context.contentRange, with: replacement)

            guard let dividerRange = paragraphRange(at: context.paragraphRange.location, in: textStorage) else {
                return
            }

            applyBlock(.divider, to: dividerRange, in: textStorage)
            selectionLocation = NSMaxRange(dividerRange)

            if selectionLocation < textStorage.length,
               let bodyRange = paragraphRange(at: selectionLocation, in: textStorage) {
                applyBlock(.paragraph, to: bodyRange, in: textStorage)
            }
        }

        Task { [weak textView] in
            await MainActor.run {
                guard let textView else {
                    return
                }

                textView.setSelectedRange(NSRange(location: selectionLocation, length: 0))
                textView.typingAttributes = self.themeResolver.attributes(for: .paragraph)
                self.publishStateSnapshot(from: textView)
            }
        }
    }

    private func handleBulletReturn(in textView: MarkdownEditorTextView) -> Bool {
        guard
            let context = paragraphContextAroundSelection(in: textView),
            let textStorage = textView.textStorage
        else {
            return false
        }

        let bulletContent = paragraphNormalizer.bulletContentText(from: context.text)

        if bulletContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           configuration.behavior.exitsBulletOnReturnWhenEmpty {
            let selectionLocation = context.paragraphRange.location

            performProgrammaticEdit(in: textView) {
                textStorage.replaceCharacters(in: context.contentRange, with: "")

                if selectionLocation < textStorage.length,
                   let updatedRange = paragraphRange(at: selectionLocation, in: textStorage) {
                    applyBlock(.paragraph, to: updatedRange, in: textStorage)
                }

                trailingEmptyBlock = .paragraph
            }

            Task { [weak textView] in
                await MainActor.run {
                    guard let textView else {
                        return
                    }

                    textView.setSelectedRange(NSRange(location: selectionLocation, length: 0))
                    textView.typingAttributes = self.themeResolver.attributes(for: .paragraph)
                    self.publishStateSnapshot(from: textView)
                }
            }
            return true
        }

        let insertion = "\n" + MarkdownEditorThemeResolver.bulletPrefix
        let insertionRange = textView.selectedRange()
        let newSelectionLocation = insertionRange.location + insertion.utf16.count

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: insertionRange, with: insertion)

            if let newParagraphRange = paragraphRange(at: newSelectionLocation, in: textStorage) {
                applyBlock(.bullet, to: newParagraphRange, in: textStorage)
            }

            textView.setSelectedRange(NSRange(location: newSelectionLocation, length: 0))
            textView.typingAttributes = themeResolver.attributes(for: .bullet)
            trailingEmptyBlock = hasEmptyTrailingParagraph(in: textView) ? .bullet : .paragraph
        }

        return true
    }

    private func handleDividerReturn(in textView: MarkdownEditorTextView) -> Bool {
        guard let textStorage = textView.textStorage else {
            return false
        }

        let selection = textView.selectedRange()
        let newSelectionLocation = selection.location + 1

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: selection, with: "\n")

            if newSelectionLocation < textStorage.length,
               let newParagraphRange = paragraphRange(at: newSelectionLocation, in: textStorage) {
                applyBlock(.paragraph, to: newParagraphRange, in: textStorage)
            }

            textView.setSelectedRange(NSRange(location: newSelectionLocation, length: 0))
            textView.typingAttributes = themeResolver.attributes(for: .paragraph)
            trailingEmptyBlock = hasEmptyTrailingParagraph(in: textView) ? .paragraph : trailingEmptyBlock
        }

        return true
    }

    private func insertNewline(with block: MarkdownEditorBlock, in textView: MarkdownEditorTextView) {
        guard let textStorage = textView.textStorage else {
            return
        }

        let selection = textView.selectedRange()
        let newSelectionLocation = selection.location + 1

        performProgrammaticEdit(in: textView) {
            textStorage.replaceCharacters(in: selection, with: "\n")

            if newSelectionLocation < textStorage.length,
               let newParagraphRange = paragraphRange(at: newSelectionLocation, in: textStorage) {
                applyBlock(block, to: newParagraphRange, in: textStorage)
            }

            textView.setSelectedRange(NSRange(location: newSelectionLocation, length: 0))
            textView.typingAttributes = themeResolver.attributes(for: block)
            trailingEmptyBlock = hasEmptyTrailingParagraph(in: textView) ? block : .paragraph
        }
    }

    private func handleEmptyHeadingBackspace(in textView: MarkdownEditorTextView) -> Bool {
        guard configuration.behavior.convertsEmptyHeadingOnDeleteBackward else {
            return false
        }

        guard case .heading = blockAtInsertionPoint(in: textView) else {
            return false
        }

        if hasEmptyTrailingParagraph(in: textView), textView.selectedRange().location == textView.string.utf16.count {
            trailingEmptyBlock = .paragraph
            textView.typingAttributes = themeResolver.attributes(for: .paragraph)
            return true
        }

        guard
            let context = paragraphContextAroundSelection(in: textView),
            context.text.isEmpty,
            textView.selectedRange().location == context.paragraphRange.location,
            let textStorage = textView.textStorage
        else {
            return false
        }

        performProgrammaticEdit(in: textView) {
            applyBlock(.paragraph, to: context.paragraphRange, in: textStorage)
            textView.setSelectedRange(NSRange(location: context.paragraphRange.location, length: 0))
            textView.typingAttributes = themeResolver.attributes(for: .paragraph)
        }

        return true
    }

    private func handleEmptyBulletBackspace(in textView: MarkdownEditorTextView) -> Bool {
        guard
            let context = paragraphContextAroundSelection(in: textView),
            context.block == .bullet,
            paragraphNormalizer.bulletContentText(from: context.text).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            textView.selectedRange().location == context.paragraphRange.location + MarkdownEditorThemeResolver.bulletPrefix.utf16.count,
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

        Task { [weak textView] in
            await MainActor.run {
                guard let textView else {
                    return
                }

                textView.setSelectedRange(NSRange(location: selectionLocation, length: 0))
                textView.typingAttributes = self.themeResolver.attributes(for: .paragraph)
                self.publishStateSnapshot(from: textView)
            }
        }

        return true
    }

    private func syncTypingAttributes(in textView: MarkdownEditorTextView) {
        textView.typingAttributes = themeResolver.attributes(for: blockAtInsertionPoint(in: textView))
    }

    private func blockAtInsertionPoint(in textView: MarkdownEditorTextView) -> MarkdownEditorBlock {
        let selection = textView.selectedRange()

        if hasEmptyTrailingParagraph(in: textView),
           selection.length == 0,
           selection.location == textView.string.utf16.count {
            return trailingEmptyBlock
        }

        return paragraphContextAroundSelection(in: textView)?.block ?? .paragraph
    }

    private func applyBlock(_ block: MarkdownEditorBlock, to range: NSRange, in textStorage: NSTextStorage) {
        textStorage.setAttributes(themeResolver.attributes(for: block), range: range)
    }

    private func blockForParagraph(at location: Int, in textStorage: NSTextStorage) -> MarkdownEditorBlock {
        guard
            location < textStorage.length,
            let rawValue = textStorage.attribute(.markdownEditorBlock, at: location, effectiveRange: nil) as? String,
            let block = MarkdownEditorBlock(storageValue: rawValue)
        else {
            return .paragraph
        }

        return block
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
        let endsWithNewline = paragraphRange.length > 0
            && NSMaxRange(paragraphRange) <= length
            && string.substring(with: NSRange(location: NSMaxRange(paragraphRange) - 1, length: 1)) == "\n"
        let contentRange = endsWithNewline
            ? NSRange(location: paragraphRange.location, length: paragraphRange.length - 1)
            : paragraphRange

        let block = blockForParagraph(at: paragraphRange.location, in: textView.textStorage ?? NSTextStorage())

        return ParagraphContext(
            paragraphRange: paragraphRange,
            contentRange: contentRange,
            text: string.substring(with: contentRange),
            block: block,
            endsAtDocumentEnd: NSMaxRange(paragraphRange) == length
        )
    }

    private func hasEmptyTrailingParagraph(in textView: NSTextView) -> Bool {
        let text = textView.string
        return text.isEmpty || text.hasSuffix("\n")
    }

    private func performProgrammaticEdit(in textView: MarkdownEditorTextView, _ edits: () -> Void) {
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
    let block: MarkdownEditorBlock
    let endsAtDocumentEnd: Bool
}
