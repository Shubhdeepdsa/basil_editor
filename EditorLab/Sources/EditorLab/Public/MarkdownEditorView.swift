import SwiftUI

/// SwiftUI entry point for the EditorLab macOS editor.
///
/// This view embeds the internal AppKit editor engine and applies the supplied
/// ``MarkdownEditorConfiguration`` while synchronizing with
/// ``MarkdownEditorState``.
@MainActor
public struct MarkdownEditorView: View {
    @ObservedObject private var state: MarkdownEditorState
    private let configuration: MarkdownEditorConfiguration

    /// Creates a markdown-trigger editor view.
    ///
    /// - Parameters:
    ///   - state: Host-owned editor state.
    ///   - configuration: Theme and behavior settings for the editor surface.
    public init(
        state: MarkdownEditorState,
        configuration: MarkdownEditorConfiguration = .default
    ) {
        self.state = state
        self.configuration = configuration
    }

    public var body: some View {
        MarkdownEditorRepresentable(
            state: state,
            configuration: configuration
        )
    }
}
