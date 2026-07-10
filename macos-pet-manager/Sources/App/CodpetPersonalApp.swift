import SwiftUI
import AppKit
import Combine

private final class FloatingPetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@main
struct CodpetPersonalApp: App {
    @NSApplicationDelegateAdaptor(CodpetPersonalAppDelegate.self) private var appDelegate

    init() {
        debugStartup("CodpetPersonalApp.init")
    }

    var body: some Scene {
        Settings {
            SettingsView(onClose: {
                NSApp.keyWindow?.close()
            })
            .environmentObject(appDelegate.store)
        }
    }
}

final class CodpetPersonalAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let store = PetLibraryStore()
    private var mainWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        debugStartup("applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.regular)
        bindStore()
        createMainWindowIfNeeded()
        placeWindowForVisibility()
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "🐾"
        }
        
        let menu = NSMenu()
        let showItem = NSMenuItem(title: "Show Library", action: #selector(showLibrary), keyEquivalent: "l")
        showItem.target = self
        menu.addItem(showItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit CodpetPersonal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func showLibrary() {
        createMainWindowIfNeeded()
        placeWindowForVisibility()
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            createMainWindowIfNeeded()
        }
        placeWindowForVisibility()
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldSaveApplicationState(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldRestoreApplicationState(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        false
    }

    private func createMainWindowIfNeeded() {
        if let mainWindow {
            self.mainWindow = mainWindow
            return
        }

        let contentView = RootView()
            .environmentObject(store)
        let hostingView = NSHostingView(rootView: contentView)
        let initialSize = Self.windowSize(for: store.dockLayoutMode)
        hostingView.frame = NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height)

        let window = FloatingPetWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialSize.width, height: initialSize.height),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.isMovableByWindowBackground = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.delegate = self
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("")

        self.mainWindow = window
        debugStartup("mainWindow created")
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }

    private func bindStore() {
        store.$dockLayoutMode
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateWindowLayout()
            }
            .store(in: &cancellables)
    }

    private func updateWindowLayout() {
        guard let window = mainWindow else { return }
        let newSize = Self.windowSize(for: store.dockLayoutMode)
        var frame = window.frame
        frame.size = newSize
        window.setFrame(frame, display: true)
        if let hostingView = window.contentView as? NSHostingView<RootView> {
            hostingView.frame = NSRect(origin: .zero, size: newSize)
        }
        placeWindowForVisibility()
        window.makeKeyAndOrderFront(nil)
    }

    private func placeWindowForVisibility() {
        guard let window = mainWindow else { return }

        let targetScreen = window.screen ?? NSScreen.main
        guard let screen = targetScreen else {
            window.center()
            return
        }

        let visible = screen.visibleFrame
        let origin: NSPoint
        switch store.dockLayoutMode {
        case .vertical:
            let horizontalMargin: CGFloat = 160
            origin = NSPoint(
                x: visible.maxX - window.frame.width - horizontalMargin,
                y: visible.midY - (window.frame.height / 2)
            )
        case .horizontal:
            let topOffset: CGFloat = 18
            origin = NSPoint(
                x: visible.midX - (window.frame.width / 2),
                y: visible.maxY - window.frame.height - topOffset
            )
        }

        window.setFrameOrigin(origin)
        debugStartup("mainWindow repositioned for visibility")
    }

    private static func windowSize(for mode: DockLayoutMode) -> NSSize {
        switch mode {
        case .vertical:
            return NSSize(width: 76, height: 306)
        case .horizontal:
            return NSSize(width: 332, height: 78)
        }
    }
}

func debugStartup(_ message: String) {
    let line = "[CodpetPersonal] \(message)\n"
    fputs(line, stderr)
    fflush(stderr)

    let logURL = FileManager.default.temporaryDirectory.appendingPathComponent("codpetpersonal-startup.log")
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            }
        } else {
            try? FileManager.default.createDirectory(
                at: logURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: logURL)
        }
    }
}
