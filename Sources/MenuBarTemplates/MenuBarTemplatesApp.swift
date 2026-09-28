import AppKit
import SwiftUI

@main
@MainActor
final class MenuBarTemplatesApp: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var window: NSWindow?
    private let store = TemplateStore()

    static func main() {
        let app = NSApplication.shared
        let delegate = MenuBarTemplatesApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: "Email Templates")
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
            button.action = #selector(statusItemClicked(_:))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.saveImmediately()
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            showWindow()
            return
        }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
            menu.items.first?.target = self
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleWindow()
        }
    }

    @objc private func quit() {
        store.saveImmediately()
        NSApp.terminate(nil)
    }

    /// The window is "shown" when it exists, is on screen, and isn't minimized.
    /// A minimized window still lives in the Dock, so we treat it as shown and
    /// simply bring it back on the next menu-bar click.
    private var isWindowShown: Bool {
        guard let window else { return false }
        return window.isVisible && !window.isMiniaturized
    }

    private func toggleWindow() {
        if isWindowShown {
            hideWindow()
        } else {
            showWindow()
        }
    }

    private func showWindow() {
        if window == nil {
            let content = ContentView().environmentObject(store)
            let hostingView = NSHostingView(rootView: content)
            let createdWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1080, height: 720),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            createdWindow.title = "Email Templates"
            createdWindow.contentView = hostingView
            createdWindow.center()
            createdWindow.isReleasedWhenClosed = false
            createdWindow.delegate = self
            window = createdWindow
        }

        setDockVisible(true)
        window?.deminiaturize(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Hide the window back into the menu bar (kept alive, off screen) and drop
    /// the Dock icon. Shares the Dock switch with the red-cross close path.
    private func hideWindow() {
        window?.orderOut(nil)
        setDockVisible(false)
    }

    /// Show or hide the Dock icon by switching the app's activation policy.
    /// `.regular` = Dock icon + app menu; `.accessory` = menu-bar only.
    private func setDockVisible(_ visible: Bool) {
        let desired: NSApplication.ActivationPolicy = visible ? .regular : .accessory
        if NSApp.activationPolicy() != desired {
            NSApp.setActivationPolicy(desired)
        }
    }

    // MARK: - NSWindowDelegate

    /// The red cross (or ⌘W) closes the window; the window is reused
    /// (`isReleasedWhenClosed = false`), so we just drop the Dock icon.
    func windowWillClose(_ notification: Notification) {
        setDockVisible(false)
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Email Templates", action: #selector(quit), keyEquivalent: "q"))
        appMenu.items.first?.target = self
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Paste and Match Style", action: #selector(NSTextView.pasteAsPlainText(_:)), keyEquivalent: "V"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))

        for item in editMenu.items {
            item.target = nil
        }

        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }
}
