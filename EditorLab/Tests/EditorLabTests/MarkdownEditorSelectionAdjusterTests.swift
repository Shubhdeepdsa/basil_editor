import Foundation
import XCTest
@testable import EditorLab

final class MarkdownEditorSelectionAdjusterTests: XCTestCase {
    func testCaretAfterSingleHashMovesBackToParagraphStart() {
        let adjusted = MarkdownEditorSelectionAdjuster.afterRemovingPrefix(
            selection: NSRange(location: 2, length: 0),
            prefixLength: 2,
            at: 0
        )

        XCTAssertEqual(adjusted, NSRange(location: 0, length: 0))
    }

    func testCaretAfterDoubleHashMovesBackByTriggerLength() {
        let adjusted = MarkdownEditorSelectionAdjuster.afterRemovingPrefix(
            selection: NSRange(location: 7, length: 0),
            prefixLength: 3,
            at: 0
        )

        XCTAssertEqual(adjusted, NSRange(location: 4, length: 0))
    }

    func testCaretAfterTripleHashMovesBackByTriggerLength() {
        let adjusted = MarkdownEditorSelectionAdjuster.afterRemovingPrefix(
            selection: NSRange(location: 10, length: 0),
            prefixLength: 4,
            at: 0
        )

        XCTAssertEqual(adjusted, NSRange(location: 6, length: 0))
    }

    func testCaretAfterQuadrupleHashMovesBackByTriggerLength() {
        let adjusted = MarkdownEditorSelectionAdjuster.afterRemovingPrefix(
            selection: NSRange(location: 12, length: 0),
            prefixLength: 5,
            at: 0
        )

        XCTAssertEqual(adjusted, NSRange(location: 7, length: 0))
    }

    func testBulletReplacementKeepsSelectionWhenReplacementLengthMatches() {
        let adjusted = MarkdownEditorSelectionAdjuster.forReplacement(
            selection: NSRange(location: 5, length: 0),
            replacedRange: NSRange(location: 0, length: 2),
            replacementLength: MarkdownEditorThemeResolver.bulletPrefix.utf16.count
        )

        XCTAssertEqual(adjusted, NSRange(location: 5, length: 0))
    }

    func testSelectionBeforeReplacementIsUnchanged() {
        let selection = NSRange(location: 0, length: 0)

        let adjusted = MarkdownEditorSelectionAdjuster.forReplacement(
            selection: selection,
            replacedRange: NSRange(location: 3, length: 2),
            replacementLength: MarkdownEditorThemeResolver.bulletPrefix.utf16.count
        )

        XCTAssertEqual(adjusted, selection)
    }

    func testSelectionNeverGoesNegative() {
        let adjusted = MarkdownEditorSelectionAdjuster.afterRemovingPrefix(
            selection: NSRange(location: 1, length: 0),
            prefixLength: 5,
            at: 0
        )

        XCTAssertEqual(adjusted, NSRange(location: 0, length: 0))
    }
}
