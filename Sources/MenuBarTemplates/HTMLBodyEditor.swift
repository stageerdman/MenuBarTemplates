import SwiftUI
import WebKit

struct HTMLBodyEditor: NSViewRepresentable {
    @Binding var html: String
    var isEditable: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(html: $html)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "templateEditor")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView
        HTMLCommandCenter.webView = webView
        HTMLCommandCenter.isEditable = isEditable
        webView.loadHTMLString(document(for: html, editable: isEditable), baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.html = $html
        context.coordinator.isEditable = isEditable
        HTMLCommandCenter.webView = webView
        HTMLCommandCenter.isEditable = isEditable

        guard context.coordinator.loaded else {
            return
        }

        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.evaluateJavaScript("window.setEditorHTML(\(html.javaScriptEscaped));")
        }

        webView.evaluateJavaScript("document.body.contentEditable = \(isEditable ? "'true'" : "'false'");")
    }

    static func command(_ command: String, value: String? = nil) {
        HTMLCommandCenter.command(command, value: value ?? "")
    }

    private func document(for body: String, editable: Bool) -> String {
        """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        :root {
            color-scheme: light dark;
        }
        html, body {
            margin: 0;
            min-height: 100%;
            font: -apple-system-body;
            color: CanvasText;
            background: transparent;
        }
        body {
            box-sizing: border-box;
            padding: 14px 16px;
            outline: none;
            line-height: 1.45;
        }
        body, body * {
            color: CanvasText !important;
            background-color: transparent;
        }
        p { margin: 0 0 0.85em; }
        h1, h2, h3 { margin: 0.8em 0 0.35em; line-height: 1.2; }
        ul, ol { margin-top: 0.35em; padding-left: 1.6em; }
        a { color: LinkText !important; }
        img { max-width: 100%; height: auto; }
        </style>
        </head>
        <body contenteditable="\(editable ? "true" : "false")">\(body)</body>
        <script>
        window.setEditorHTML = function(value) {
            if (document.body.innerHTML !== value) {
                document.body.innerHTML = value;
            }
        };
        window.emitHTML = function() {
            window.webkit.messageHandlers.templateEditor.postMessage(document.body.innerHTML);
        };
        document.body.addEventListener('input', window.emitHTML);
        document.body.addEventListener('paste', function() {
            setTimeout(window.emitHTML, 0);
        });
        </script>
        </html>
        """
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var html: Binding<String>
        weak var webView: WKWebView?
        var loaded = false
        var lastHTML: String
        var isEditable = true

        init(html: Binding<String>) {
            self.html = html
            self.lastHTML = html.wrappedValue
            super.init()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            lastHTML = html.wrappedValue
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let value = message.body as? String else {
                return
            }
            lastHTML = value
            html.wrappedValue = value
        }
    }
}

@MainActor
private enum HTMLCommandCenter {
    static weak var webView: WKWebView?
    static var isEditable = true

    static func command(_ command: String, value: String) {
        guard isEditable else {
            return
        }
        webView?.evaluateJavaScript("document.execCommand('\(command)', false, \(value.javaScriptEscaped)); window.emitHTML();")
    }
}

struct FormattingToolbar: View {
    var disabled: Bool

    var body: some View {
        HStack(spacing: 6) {
            Button("B") { HTMLBodyEditor.command("bold") }
                .font(.headline)
                .help("Bold")
            Button("I") { HTMLBodyEditor.command("italic") }
                .italic()
                .help("Italic")
            Button("H2") { HTMLBodyEditor.command("formatBlock", value: "h2") }
                .help("Heading")
            Button("•") { HTMLBodyEditor.command("insertUnorderedList") }
                .help("Bullet list")
            Button("1.") { HTMLBodyEditor.command("insertOrderedList") }
                .help("Numbered list")
            Button("Link") { insertLink() }
                .help("Create link")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(disabled)
    }

    private func insertLink() {
        let alert = NSAlert()
        alert.messageText = "Insert Link"
        alert.informativeText = "Enter the URL for the selected text."
        alert.addButton(withTitle: "Insert")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        textField.placeholderString = "https://example.com"
        alert.accessoryView = textField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
        HTMLBodyEditor.command("createLink", value: textField.stringValue)
    }
}
