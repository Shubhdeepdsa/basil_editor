import Foundation

enum MarkdownEditorSelectionAdjuster {
    static func afterRemovingPrefix(
        selection: NSRange,
        prefixLength: Int,
        at paragraphStart: Int
    ) -> NSRange {
        let location: Int

        if selection.location <= paragraphStart + prefixLength {
            location = paragraphStart
        } else {
            location = selection.location - prefixLength
        }

        return NSRange(location: max(0, location), length: selection.length)
    }

    static func forReplacement(
        selection: NSRange,
        replacedRange: NSRange,
        replacementLength: Int
    ) -> NSRange {
        let delta = replacementLength - replacedRange.length

        if selection.location <= replacedRange.location {
            return selection
        }

        return NSRange(location: max(0, selection.location + delta), length: selection.length)
    }
}
