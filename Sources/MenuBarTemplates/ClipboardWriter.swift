import AppKit
import EmailTemplateCore

enum ClipboardWriter {
    static func copySubject(_ subject: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(subject, forType: .string)
    }

    static func copyBody(_ resolved: ResolvedTemplate) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(resolved.bodyHtml, forType: .html)
        pasteboard.setString(resolved.bodyPlainText, forType: .string)
    }
}
