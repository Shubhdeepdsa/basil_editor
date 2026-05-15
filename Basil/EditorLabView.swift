import SwiftUI

struct EditorLabView: View {
    @State private var documentHTML = ""

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            TiptapEditorView(html: $documentHTML)
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
