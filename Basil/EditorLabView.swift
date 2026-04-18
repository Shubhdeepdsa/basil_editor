import AppKit
import EditorLab
import SwiftUI

struct EditorLabView: View {
    @StateObject private var editorState = MarkdownEditorState()

    private let configuration = MarkdownEditorConfiguration(
        theme: MarkdownEditorTheme(
            bodyStyle: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: .labelColor,
                lineSpacing: 5,
                paragraphSpacing: 10
            ),
            heading1Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 30, weight: .bold),
                textColor: .labelColor,
                lineSpacing: 3,
                paragraphSpacingBefore: 18,
                paragraphSpacing: 14
            ),
            heading2Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 25, weight: .bold),
                textColor: .labelColor,
                lineSpacing: 3,
                paragraphSpacingBefore: 16,
                paragraphSpacing: 13
            ),
            heading3Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 21, weight: .semibold),
                textColor: .labelColor,
                lineSpacing: 3,
                paragraphSpacingBefore: 14,
                paragraphSpacing: 12
            ),
            heading4Style: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 18, weight: .semibold),
                textColor: .labelColor,
                lineSpacing: 3,
                paragraphSpacingBefore: 12,
                paragraphSpacing: 11
            ),
            bulletStyle: MarkdownEditorTextStyle(
                font: .systemFont(ofSize: 17, weight: .regular),
                textColor: .labelColor,
                lineSpacing: 5,
                paragraphSpacing: 8
            ),
            editorBackgroundColor: .textBackgroundColor,
            contentInset: NSSize(width: 28, height: 26),
            bulletIndent: 18,
            bulletContentIndent: 38,
            dividerColor: .separatorColor,
            dividerThickness: 1,
            dividerHorizontalInset: 12,
            dividerLineHeight: 26,
            dividerSpacingBefore: 10,
            dividerSpacing: 12
        )
    )

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            MarkdownEditorView(
                state: editorState,
                configuration: configuration
            )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
                )
                .padding(24)
        }
        .frame(minWidth: 760, minHeight: 560)
    }
}

#Preview {
    EditorLabView()
}
