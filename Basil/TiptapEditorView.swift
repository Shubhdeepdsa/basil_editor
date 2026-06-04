import Foundation
import SwiftUI
import WebKit

enum NoteSwipeDirection {
    case newer
    case older
}

enum NoteSwipeEvent {
    case began
    case changed(CGFloat)
    case ended(NoteSwipeDirection?)
}

struct TiptapEditorView: NSViewRepresentable {
    var noteID: UUID
    var generation: Int
    @Binding var markdown: String
    @Binding var wordCount: Int
    var isEditable: Bool
    var acceptsEditorUpdates: Bool
    var onTrackpadSwipeEvent: (NoteSwipeEvent) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "onContentChange")
        configuration.userContentController.add(context.coordinator, name: "onWordCountChange")
        configuration.setValue(false, forKey: "drawsBackground")

        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        let webView = SwipeAwareWKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.onHorizontalSwipeEvent = { event in
            context.coordinator.parent.onTrackpadSwipeEvent(event)
        }

        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebEditor") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        if let webView = webView as? SwipeAwareWKWebView {
            webView.onHorizontalSwipeEvent = { event in
                context.coordinator.parent.onTrackpadSwipeEvent(event)
            }
        }
        context.coordinator.applyState(to: webView)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "onContentChange")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "onWordCountChange")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: TiptapEditorView
        private var debugEventCounter = 0

        init(_ parent: TiptapEditorView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            applyState(to: webView)

            if parent.isEditable {
                webView.becomeFirstResponder()
            }
        }

        func applyState(to webView: WKWebView) {
            guard !webView.isLoading else { return }

            debugEventCounter += 1
            print("[BasilEditor #\(debugEventCounter)] applyState noteID=\(parent.noteID), generation=\(parent.generation), markdownChars=\(parent.markdown.count), wordCount=\(parent.wordCount), editable=\(parent.isEditable), acceptsUpdates=\(parent.acceptsEditorUpdates)")
            let script = """
            if (window.updateContent) { window.updateContent(\(parent.markdown.javaScriptLiteral)); }
            if (window.setEditable) { window.setEditable(\(parent.isEditable ? "true" : "false")); }
            """
            webView.evaluateJavaScript(script)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "onContentChange", let body = message.body as? String {
                DispatchQueue.main.async {
                    self.debugEventCounter += 1

                    guard self.parent.acceptsEditorUpdates else {
                        print("[BasilEditor #\(self.debugEventCounter)] ignored content update noteID=\(self.parent.noteID), generation=\(self.parent.generation), incomingChars=\(body.count)")
                        return
                    }

                    print("[BasilEditor #\(self.debugEventCounter)] content update noteID=\(self.parent.noteID), generation=\(self.parent.generation), oldChars=\(self.parent.markdown.count), incomingChars=\(body.count), changed=\(self.parent.markdown != body)")
                    if self.parent.markdown != body {
                        self.parent.markdown = body
                    }
                }
            } else if message.name == "onWordCountChange", let count = message.body as? Int {
                DispatchQueue.main.async {
                    self.debugEventCounter += 1

                    guard self.parent.acceptsEditorUpdates else {
                        print("[BasilEditor #\(self.debugEventCounter)] ignored word count update noteID=\(self.parent.noteID), generation=\(self.parent.generation), incomingWordCount=\(count)")
                        return
                    }

                    print("[BasilEditor #\(self.debugEventCounter)] word count update noteID=\(self.parent.noteID), generation=\(self.parent.generation), oldWordCount=\(self.parent.wordCount), incomingWordCount=\(count)")
                    self.parent.wordCount = count
                }
            }
        }
    }
}

private final class SwipeAwareWKWebView: WKWebView {
    var onHorizontalSwipeEvent: ((NoteSwipeEvent) -> Void)?

    private var accumulatedHorizontalDelta: CGFloat = 0
    private var endTimer: Timer?
    private var isTrackingSwipe = false
    private let swipeThreshold: CGFloat = 80
    private let visualScale: CGFloat = 1.35

    override func scrollWheel(with event: NSEvent) {
        guard event.momentumPhase == [] else {
            print("[BasilSwipe] ignoring momentum phase=\(event.momentumPhase.rawValue)")
            return
        }

        let horizontalDelta = event.scrollingDeltaX
        let verticalDelta = event.scrollingDeltaY
        let isHorizontal = abs(horizontalDelta) > abs(verticalDelta) && abs(horizontalDelta) > 0.5

        guard isHorizontal else {
            super.scrollWheel(with: event)
            return
        }

        if event.phase.contains(.began) || !isTrackingSwipe {
            isTrackingSwipe = true
            accumulatedHorizontalDelta = 0
            print("[BasilSwipe] horizontal scroll began")
            onHorizontalSwipeEvent?(.began)
        }

        accumulatedHorizontalDelta += horizontalDelta
        print("[BasilSwipe] horizontal delta=\(horizontalDelta), accumulated=\(accumulatedHorizontalDelta), phase=\(event.phase.rawValue), momentum=\(event.momentumPhase.rawValue)")
        onHorizontalSwipeEvent?(.changed(accumulatedHorizontalDelta * visualScale))
        scheduleEndTimer()

        if event.phase.contains(.ended) || event.phase.contains(.cancelled) || event.momentumPhase.contains(.ended) {
            finishSwipe(reason: "phase ended")
        }
    }

    private func scheduleEndTimer() {
        endTimer?.invalidate()
        endTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { [weak self] _ in
            self?.finishSwipe(reason: "inactivity timeout")
        }
    }

    private func finishSwipe(reason: String) {
        guard isTrackingSwipe else { return }

        endTimer?.invalidate()
        endTimer = nil

        let direction: NoteSwipeDirection? = abs(accumulatedHorizontalDelta) >= swipeThreshold
            ? (accumulatedHorizontalDelta > 0 ? .older : .newer)
            : nil

        print("[BasilSwipe] horizontal scroll ended reason=\(reason), direction=\(String(describing: direction))")
        onHorizontalSwipeEvent?(.ended(direction))
        accumulatedHorizontalDelta = 0
        isTrackingSwipe = false
    }
}

private extension String {
    var javaScriptLiteral: String {
        guard let data = try? JSONEncoder().encode(self),
              let literal = String(data: data, encoding: .utf8)
        else {
            return "\"\""
        }

        return literal
    }
}
