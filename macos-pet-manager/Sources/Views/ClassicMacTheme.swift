import SwiftUI
import AppKit

enum ClassicMacTheme {
    static let desktop = Color(red: 0.74, green: 0.74, blue: 0.86)
    static let window = Color.white
    static let ink = Color.black
    static let softLine = Color.black.opacity(0.35)
    static let selected = Color.black
    static let disabled = Color.black.opacity(0.4)
    
    static func menuFont(_ size: CGFloat) -> Font {
        AppFont.menu(size)
    }

    static func pixelFont(_ size: CGFloat) -> Font {
        AppFont.pixel(size)
    }

    static func font(_ size: CGFloat) -> Font {
        menuFont(size)
    }
}

struct ClassicDesktopBackground: View {
    var body: some View {
        Canvas { context, size in
            let background = Path(CGRect(origin: .zero, size: size))
            context.fill(background, with: .color(ClassicMacTheme.desktop))
            
            for y in stride(from: 0.0, to: size.height, by: 4.0) {
                for x in stride(from: 0.0, to: size.width, by: 4.0) {
                    var dot = Path()
                    dot.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                    context.fill(dot, with: .color(.black.opacity(((Int(x + y) / 4) % 2 == 0) ? 0.14 : 0.04)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct ClassicWindow<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ClassicTitleBar(title: title)
            content
                .padding(12)
                .background(ClassicMacTheme.window)
        }
        .background(ClassicMacTheme.window)
        .overlay(
            Rectangle()
                .stroke(ClassicMacTheme.ink, lineWidth: 1)
        )
    }
}

struct ClassicTitleBar: View {
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            stripes
            Text(title)
                .font(fontOrSystem(size: 18))
                .foregroundStyle(ClassicMacTheme.ink)
                .lineLimit(1)
            stripes
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(ClassicMacTheme.window)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ClassicMacTheme.ink)
                .frame(height: 1)
        }
    }
    
    private var stripes: some View {
        VStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { _ in
                Rectangle()
                    .fill(ClassicMacTheme.ink)
                    .frame(height: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func fontOrSystem(size: CGFloat) -> Font {
        ClassicMacTheme.font(size)
    }
}

struct ClassicMenuStrip: View {
    var body: some View {
        HStack(spacing: 18) {
            Text("Codpet")
            Text("File")
            Text("Pets")
            Text("View")
            Text("Special")
            Spacer()
            Text("Pet Manager")
        }
        .font(ClassicMacTheme.font(13))
        .padding(.horizontal, 14)
        .frame(height: 24)
        .background(ClassicMacTheme.window)
        .overlay(
            Rectangle()
                .stroke(ClassicMacTheme.ink, lineWidth: 1)
        )
    }
}

struct ClassicButtonStyle: ButtonStyle {
    let filled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClassicMacTheme.menuFont(12))
            .foregroundStyle(configuration.isPressed || filled ? Color.white : ClassicMacTheme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(minHeight: 28)
            .background(buttonBackground(pressed: configuration.isPressed))
            .overlay(borderOverlay(pressed: configuration.isPressed))
    }

    @ViewBuilder
    private func buttonBackground(pressed: Bool) -> some View {
        if pressed || filled {
            ClassicMacTheme.ink
        } else {
            Color.white
        }
    }

    @ViewBuilder
    private func borderOverlay(pressed: Bool) -> some View {
        ZStack {
            Rectangle()
                .stroke(ClassicMacTheme.ink, lineWidth: 1)

            if !(pressed || filled) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 1)
                    Spacer()
                }

                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1)
                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(height: 1)
                }

                HStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 1)
                }
            }
        }
    }
}

struct ClassicSearchFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(ClassicMacTheme.font(12))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(ClassicMacTheme.window)
            .overlay(
                Rectangle()
                    .stroke(ClassicMacTheme.ink, lineWidth: 1)
            )
    }
}

struct ClassicBadge: View {
    let text: String
    let inverted: Bool
    
    var body: some View {
        Text(text)
            .font(ClassicMacTheme.font(11))
            .foregroundStyle(inverted ? Color.white : ClassicMacTheme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(inverted ? ClassicMacTheme.ink : ClassicMacTheme.window)
            .overlay(
                Rectangle()
                    .stroke(ClassicMacTheme.ink, lineWidth: 1)
            )
    }
}

struct WindowBootstrapper: NSViewRepresentable {
    final class Coordinator {
        var didConfigure = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configureWindowIfNeeded(from: view, coordinator: context.coordinator)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindowIfNeeded(from: nsView, coordinator: context.coordinator)
        }
    }
    
    private func configureWindowIfNeeded(from view: NSView, coordinator: Coordinator) {
        guard !coordinator.didConfigure,
              let window = view.window else { return }
        
        coordinator.didConfigure = true
        var styleMask = window.styleMask
        styleMask.remove(.titled)
        styleMask.insert(.borderless)
        styleMask.insert(.resizable)
        styleMask.insert(.miniaturizable)
        styleMask.insert(.closable)
        styleMask.insert(.fullSizeContentView)
        window.styleMask = styleMask
        window.isRestorable = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbar = nil
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.74, green: 0.74, blue: 0.86, alpha: 1)
        window.hasShadow = false
        window.isOpaque = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        debugStartup("WindowBootstrapper configured window")
    }
}
