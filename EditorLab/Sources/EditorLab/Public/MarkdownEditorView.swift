import SwiftUI

@MainActor
public struct MarkdownEditorView: View {
    @ObservedObject private var state: MarkdownEditorState
    private let configuration: MarkdownEditorConfiguration

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
