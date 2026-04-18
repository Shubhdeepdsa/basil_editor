import SwiftUI

struct EditorLabView: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            EditorTextViewRepresentable()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
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
