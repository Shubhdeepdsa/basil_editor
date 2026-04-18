import AppKit
import XCTest
@testable import EditorLab

@MainActor
final class MarkdownEditorParagraphNormalizerTests: XCTestCase {
    func testHeadingLevelOneNormalization() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "# Title", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "Title")
        XCTAssertEqual(result.block, .heading(level: .h1))
    }

    func testHeadingLevelTwoNormalization() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "## Title", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "Title")
        XCTAssertEqual(result.block, .heading(level: .h2))
    }

    func testHeadingLevelThreeNormalization() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "### Title", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "Title")
        XCTAssertEqual(result.block, .heading(level: .h3))
    }

    func testHeadingLevelFourNormalization() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "#### Title", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "Title")
        XCTAssertEqual(result.block, .heading(level: .h4))
    }

    func testBulletNormalization() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "- item", existingBlock: .paragraph)

        XCTAssertEqual(result.text, MarkdownEditorThemeResolver.bulletPrefix + "item")
        XCTAssertEqual(result.block, .bullet)
    }

    func testDividerNormalization() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "---", existingBlock: .paragraph)

        XCTAssertEqual(result.text, MarkdownEditorThemeResolver.dividerPlaceholder)
        XCTAssertEqual(result.block, .divider)
    }

    func testPlainParagraphStaysParagraph() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(for: "Plain text", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "Plain text")
        XCTAssertEqual(result.block, .paragraph)
    }

    func testDisabledBulletsLeaveTextUnchanged() {
        let configuration = MarkdownEditorConfiguration(
            behavior: MarkdownEditorBehavior(enablesBullets: false)
        )
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: configuration)

        let result = normalizer.normalizedTarget(for: "- item", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "- item")
        XCTAssertEqual(result.block, .paragraph)
    }

    func testDisabledDividersLeaveTextUnchanged() {
        let configuration = MarkdownEditorConfiguration(
            behavior: MarkdownEditorBehavior(enablesDividers: false)
        )
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: configuration)

        let result = normalizer.normalizedTarget(for: "---", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "---")
        XCTAssertEqual(result.block, .paragraph)
    }

    func testDisabledHeadingLevelsLeaveTriggerTextUnchanged() {
        let configuration = MarkdownEditorConfiguration(
            behavior: MarkdownEditorBehavior(enabledHeadingLevels: [.h1])
        )
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: configuration)

        let result = normalizer.normalizedTarget(for: "## Title", existingBlock: .paragraph)

        XCTAssertEqual(result.text, "## Title")
        XCTAssertEqual(result.block, .paragraph)
    }

    func testExistingDividerPlaceholderStaysDivider() {
        let normalizer = MarkdownEditorParagraphNormalizer(configuration: .default)

        let result = normalizer.normalizedTarget(
            for: MarkdownEditorThemeResolver.dividerPlaceholder,
            existingBlock: .divider
        )

        XCTAssertEqual(result.text, MarkdownEditorThemeResolver.dividerPlaceholder)
        XCTAssertEqual(result.block, .divider)
    }
}
