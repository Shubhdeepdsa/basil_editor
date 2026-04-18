import AppKit
import XCTest
@testable import EditorLab

@MainActor
final class MarkdownEditorIntegrationTests: XCTestCase {
    func testHeadingTriggerConvertsCurrentParagraph() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "# "))
        harness.textView.setSelectedRange(NSRange(location: 2, length: 0))

        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        XCTAssertEqual(harness.textView.string, "")
        XCTAssertEqual(harness.blockAtInsertionPoint(), .heading(level: .h1))
        XCTAssertEqual(harness.textView.selectedRange(), NSRange(location: 0, length: 0))
    }

    func testBulletTriggerConvertsCurrentParagraph() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "- "))
        harness.textView.setSelectedRange(NSRange(location: 2, length: 0))

        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        XCTAssertEqual(harness.textView.string, MarkdownEditorThemeResolver.bulletPrefix)
        XCTAssertEqual(harness.block(at: 0), .bullet)
    }

    func testDividerTriggerConvertsCurrentParagraph() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "---"))
        harness.textView.setSelectedRange(NSRange(location: 3, length: 0))

        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        XCTAssertEqual(
            harness.textView.string,
            MarkdownEditorThemeResolver.dividerPlaceholder + "\n"
        )
        XCTAssertEqual(harness.block(at: 0), .divider)
        XCTAssertEqual(harness.textView.selectedRange(), NSRange(location: 2, length: 0))
    }

    func testEmptyBulletReturnExitsBackToParagraph() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "- "))
        harness.textView.setSelectedRange(NSRange(location: 2, length: 0))
        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        let handled = harness.coordinator.markdownEditorTextViewHandleInsertNewline(harness.textView)
        await harness.flushAsyncEdits()

        XCTAssertTrue(handled)
        XCTAssertEqual(harness.textView.string, "")
        XCTAssertEqual(harness.blockAtInsertionPoint(), .paragraph)
        XCTAssertEqual(harness.textView.selectedRange(), NSRange(location: 0, length: 0))
    }

    func testEmptyBulletDeleteBackwardExitsBackToParagraph() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "- "))
        harness.textView.setSelectedRange(NSRange(location: 2, length: 0))
        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        let handled = harness.coordinator.markdownEditorTextViewHandleDeleteBackward(harness.textView)
        await harness.flushAsyncEdits()

        XCTAssertTrue(handled)
        XCTAssertEqual(harness.textView.string, "")
        XCTAssertEqual(harness.blockAtInsertionPoint(), .paragraph)
        XCTAssertEqual(harness.textView.selectedRange(), NSRange(location: 0, length: 0))
    }

    func testEmptyHeadingDeleteBackwardConvertsBackToParagraph() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "# "))
        harness.textView.setSelectedRange(NSRange(location: 2, length: 0))
        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        let handled = harness.coordinator.markdownEditorTextViewHandleDeleteBackward(harness.textView)
        await harness.flushAsyncEdits()

        XCTAssertTrue(handled)
        XCTAssertEqual(harness.textView.string, "")
        XCTAssertEqual(harness.blockAtInsertionPoint(), .paragraph)
    }

    func testPasteNormalizationConvertsMarkdownAndReappliesThemeColors() async {
        let theme = MarkdownEditorTheme(
            bodyStyle: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: .systemGreen,
                lineSpacing: 5,
                paragraphSpacing: 10
            ),
            heading1Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 30, weight: .bold),
                textColor: .systemRed,
                lineSpacing: 3,
                paragraphSpacingBefore: 18,
                paragraphSpacing: 14
            ),
            heading2Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 25, weight: .bold),
                textColor: .systemOrange,
                lineSpacing: 3,
                paragraphSpacingBefore: 16,
                paragraphSpacing: 13
            ),
            heading3Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 21, weight: .semibold),
                textColor: .systemPurple,
                lineSpacing: 3,
                paragraphSpacingBefore: 14,
                paragraphSpacing: 12
            ),
            heading4Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 18, weight: .semibold),
                textColor: .systemBlue,
                lineSpacing: 3,
                paragraphSpacingBefore: 12,
                paragraphSpacing: 11
            ),
            bulletStyle: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: .systemPink,
                lineSpacing: 5,
                paragraphSpacing: 8
            )
        )
        let harness = EditorHarness(
            testCase: self,
            configuration: MarkdownEditorConfiguration(theme: theme)
        )
        let foreignAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.black,
            .font: NSFont.systemFont(ofSize: 13, weight: .regular)
        ]
        let pasted = NSAttributedString(
            string: "### Section\n- Item",
            attributes: foreignAttributes
        )

        harness.textView.textStorage?.setAttributedString(pasted)
        harness.textView.setSelectedRange(NSRange(location: harness.textView.string.utf16.count, length: 0))

        harness.coordinator.markdownEditorTextViewWillPaste(harness.textView)
        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        XCTAssertEqual(harness.block(at: 0), .heading(level: .h3))
        XCTAssertEqual(harness.block(at: "Section\n".utf16.count), .bullet)
        XCTAssertEqual(harness.textView.string, "Section\n" + MarkdownEditorThemeResolver.bulletPrefix + "Item")

        let headingColor = harness.textColor(at: 0)
        let bulletColor = harness.textColor(at: "Section\n".utf16.count)

        XCTAssertTrue(headingColor?.isEqual(theme.heading3Style.textColor) == true)
        XCTAssertTrue(bulletColor?.isEqual(theme.bulletStyle.textColor) == true)
    }

    func testDividerReturnInsertsParagraphAfterDivider() async {
        let harness = EditorHarness(testCase: self)

        harness.textView.textStorage?.setAttributedString(NSAttributedString(string: "---\nBody"))
        harness.textView.setSelectedRange(NSRange(location: 3, length: 0))
        harness.triggerTextDidChange()
        await harness.flushAsyncEdits()

        harness.textView.setSelectedRange(NSRange(location: 1, length: 0))

        let handled = harness.coordinator.markdownEditorTextViewHandleInsertNewline(harness.textView)
        await harness.flushAsyncEdits()

        XCTAssertTrue(handled)
        XCTAssertEqual(
            harness.textView.string,
            MarkdownEditorThemeResolver.dividerPlaceholder + "\n\nBody"
        )
        XCTAssertEqual(harness.block(at: 0), .divider)
        XCTAssertEqual(harness.blockAtInsertionPoint(), .paragraph)
        XCTAssertEqual(harness.textView.selectedRange(), NSRange(location: 3, length: 0))
    }
}

@MainActor
private final class EditorHarness {
    private unowned let testCase: XCTestCase

    let state: MarkdownEditorState
    let coordinator: MarkdownEditorCoordinator
    let scrollView: NSScrollView
    let textView: MarkdownEditorTextView

    init(
        testCase: XCTestCase,
        configuration: MarkdownEditorConfiguration = .default,
        attributedText: NSAttributedString = NSAttributedString(string: "")
    ) {
        self.testCase = testCase
        state = MarkdownEditorState(attributedText: attributedText)
        coordinator = MarkdownEditorCoordinator(state: state, configuration: configuration)

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(
            containerSize: NSSize(width: 640, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textView = MarkdownEditorTextView(frame: .zero, textContainer: textContainer)
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))

        coordinator.configure(textView: textView, in: scrollView)
    }

    func triggerTextDidChange() {
        coordinator.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
    }

    func flushAsyncEdits() async {
        let expectation = XCTestExpectation(description: "flush main queue")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        await testCase.fulfillment(of: [expectation], timeout: 1.0)
    }

    func block(at location: Int) -> MarkdownEditorBlock {
        guard
            let textStorage = textView.textStorage,
            location < textStorage.length,
            let rawValue = textStorage.attribute(.markdownEditorBlock, at: location, effectiveRange: nil) as? String,
            let block = MarkdownEditorBlock(storageValue: rawValue)
        else {
            return .paragraph
        }

        return block
    }

    func blockAtInsertionPoint() -> MarkdownEditorBlock {
        let attributes = textView.typingAttributes
        guard
            let rawValue = attributes[.markdownEditorBlock] as? String,
            let block = MarkdownEditorBlock(storageValue: rawValue)
        else {
            return .paragraph
        }

        return block
    }

    func textColor(at location: Int) -> NSColor? {
        textView.textStorage?.attribute(.foregroundColor, at: location, effectiveRange: nil) as? NSColor
    }
}
