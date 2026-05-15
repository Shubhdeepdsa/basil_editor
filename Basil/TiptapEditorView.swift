import SwiftUI
import WebKit

struct TiptapEditorView: NSViewRepresentable {
    @Binding var html: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "onContentChange")
        
        // Background should be transparent to match the app's styling
        configuration.setValue(false, forKey: "drawsBackground")

        // Enable local file access for modular JS
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Force focus ability
        webView.becomeFirstResponder()
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebEditor") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Update content if changed externally
        if !nsView.isLoading {
            let script = "if (window.updateContent) { window.updateContent('\(html.escapedForJavaScript())'); }"
            nsView.evaluateJavaScript(script)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: TiptapEditorView

        init(_ parent: TiptapEditorView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "onContentChange", let body = message.body as? String {
                DispatchQueue.main.async {
                    if self.parent.html != body {
                        self.parent.html = body
                    }
                }
            }
        }
    }
}

extension String {
    func escapedForJavaScript() -> String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}
