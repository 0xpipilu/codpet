import SwiftUI
import WebKit
import AppKit
import Combine

struct HybridContentView: View {
    @EnvironmentObject private var store: CodpetHybridStore
    @State private var isShowingSettings = false
    private let syncTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            if let pageURL = store.webStoreURL(), let repoRoot = store.repoRoot {
                CodpetWebStoreView(pageURL: pageURL, readAccessRoot: repoRoot, isShowingSettings: $isShowingSettings)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "没有找到 cod.pet 仓库",
                    systemImage: "folder.badge.questionmark",
                    description: Text("请在设置中配置正确的仓库路径。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 1080, height: 720)
        .background(Color.white)
        .background(
            WindowAccessor { window in
                window.styleMask = [.borderless, .resizable]
                
                window.titlebarAppearsTransparent = false
                window.isMovableByWindowBackground = true
                window.backgroundColor = .white
                window.isOpaque = true
                window.hasShadow = false
                window.isReleasedWhenClosed = false
            }
        )
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                HybridSettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") {
                                isShowingSettings = false
                            }
                        }
                    }
            }
            .frame(width: 500, height: 480)
        }
        .onReceive(syncTimer) { _ in
            store.syncFromCodex()
        }
    }
}

struct HybridSettingsView: View {
    @EnvironmentObject private var store: CodpetHybridStore
    
    var body: some View {
        Form {
            Section("工作区") {
                LabeledContent("仓库目录") {
                    Text(store.repoRoot?.path ?? "Not found")
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                LabeledContent("Codex Pet 目录") {
                    Text(store.petsDir.path)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                HStack(spacing: 12) {
                    Button("打开仓库目录") {
                        store.revealRepositoryRoot()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("打开 Codex Pet 目录") {
                        store.revealCodexPetsFolder()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("刷新全部状态") {
                        store.refreshAll()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section("应用方式") {
                Picker("选择 Pet 后", selection: $store.applyMode) {
                    ForEach(CodexApplyMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
                
                Text(store.applyMode.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("连接诊断") {
                Text("先用这里测试 Codex 当前窗口是否允许脚本注入；如果这一步不通，应用 pet 也不会即时生效。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let status = store.statusMessage {
                    Text(status)
                        .font(.callout)
                        .foregroundColor(.accentColor)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                }
                
                HStack(spacing: 12) {
                    Button("测试 Codex 应用桥") {
                        store.diagnoseCodexBridge()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("打开 Codex") {
                        store.restartCodexApp()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("创作者工具 (UGC)") {
                Text("导入自定义的 Pet，或为新宠物快速新建动作映射与图像模板文件夹。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button("导入本地 Pet...") {
                        store.importPetFromFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("新建 Pet 模板...") {
                        store.createNewPetTemplate()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("说明") {
                Text("这版 hybrid app 保留了现有 `cod.pet` 的展示体验，同时把本地安装、删除、应用这些动作接回了 macOS 原生层。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("当前版本会定时同步 `~/.codex/config.toml` 和本地 Pet 目录，所以你在 Codex 里手动切换后，这里也会很快反映出来。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("如果你选择“尝试即时刷新”，app 会优先请求 Codex 自己应用 `selected-avatar-id`。第一次使用时，macOS 可能会要求你允许这个 app 控制 Codex。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.top, 12)
        .navigationTitle("设置")
    }
}

struct CodpetWebStoreView: NSViewRepresentable {
    @EnvironmentObject private var store: CodpetHybridStore
    let pageURL: URL
    let readAccessRoot: URL
    @Binding var isShowingSettings: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(store: store, isShowingSettings: $isShowingSettings)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "codpetNative")
        contentController.addUserScript(
            WKUserScript(
                source: injectedBridgeScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.loadFileURL(pageURL, allowingReadAccessTo: readAccessRoot)
        
        // Add native drag view on top of the webView
        let dragView = DraggableNSView()
        dragView.translatesAutoresizingMaskIntoConstraints = false
        webView.addSubview(dragView)
        
        NSLayoutConstraint.activate([
            dragView.topAnchor.constraint(equalTo: webView.topAnchor),
            dragView.leadingAnchor.constraint(equalTo: webView.leadingAnchor, constant: 60),
            dragView.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: -60),
            dragView.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.store = store
        context.coordinator.isShowingSettings = $isShowingSettings
        context.coordinator.syncInstalledState(in: webView)
    }
    
    private var injectedBridgeScript: String {
        """
        (function() {
          if (window.__codpetNativeInjected) return;
          window.__codpetNativeInjected = true;

          const downloadIcon = `<svg viewBox="0 0 24 24" style="width:12px;height:12px;" shape-rendering="crispEdges" fill="none" xmlns="http://www.w3.org/2000/svg"><g fill="currentColor"><polygon points="22 8 22 14 20 14 20 8"/><path d="M16,4 L14,4 L14,2 L16,2 L16,4 Z M16,4 L18,4 L18,6 L20,6 L20,8 L16,8 L16,4 Z"/><polygon points="20 14 20 16 18 16 18 14"/><polygon points="8 2 8 0 14 0 14 2"/><polygon points="0 14 0 8 2 8 2 14"/><polygon points="2 14 4 14 4 16 2 16"/><path d="M6,4 L4,4 L4,6 L2,6 L2,8 L6,8 L6,4 Z M6,4 L8,4 L8,2 L6,2 L6,4 Z"/><polygon points="12 14 12 6 10 6 10 14 8 14 8 12 6 12 6 14 8 14 8 16 10 16 10 18 12 18 12 16 14 16 14 14 16 14 16 12 14 12 14 14"/></g></svg>`;
          const trashIcon = `<svg viewBox="0 0 24 24" style="width:12px;height:12px;" shape-rendering="crispEdges" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M10,6 L10,8 L4,8 L4,6 L10,6 Z M20,6 L20,8 L14,8 L14,6 L20,6 Z M14,4 L14,6 L10,6 L10,4 L14,4 Z M10,18 L10,20 L8,20 L8,18 L10,18 Z M8,10 L8,18 L6,18 L6,10 L8,10 Z M11,16 L11,10 L13,10 L13,16 L11,16 Z M16,18 L16,20 L14,20 L14,18 L16,18 Z M18,10 L18,18 L16,18 L16,10 L18,10 Z" fill="currentColor" fill-rule="nonzero"/></svg>`;

          const style = document.createElement("style");
          style.textContent = `
            @font-face {
              font-family: 'ChiKareGo2';
              src: url('ChiKareGo2.ttf') format('truetype');
            }
            @font-face {
              font-family: 'ChiKareGo';
              src: url('ChiKareGo.ttf') format('truetype');
            }
            @font-face {
              font-family: 'W95F';
              src: url('W95F.otf') format('opentype');
            }
            @font-face {
              font-family: 'Habbo';
              src: url('Habbo.ttf') format('truetype');
            }
            @font-face {
              font-family: 'battlenet';
              src: url('battlenet.ttf') format('truetype');
            }
            @font-face {
              font-family: 'dogica';
              src: url('dogica.otf') format('opentype');
            }
            @font-face {
              font-family: 'TinyUnicode';
              src: url('TinyUnicode.ttf') format('truetype');
            }
            html, body {
              margin: 0 !important;
              padding: 0 !important;
              height: 100% !important;
              overflow: hidden !important;
              background-color: #b4dcd0 !important;
            }
            body {
              user-select: none;
              box-sizing: border-box !important;
            }
            .header, .footer {
              display: none !important;
            }
             main.shell {
              max-width: 100% !important;
              width: 100% !important;
              height: 100vh !important;
              padding: 0 !important;
              margin: 0 !important;
              box-sizing: border-box !important;
              overflow: hidden !important;
              display: flex !important;
              flex-direction: column !important;
            }
            
            /* The vintage window */
            .retro-window {
              display: flex;
              flex-direction: column;
              background: #b4dcd0 !important;
              border: 2px solid #000000 !important;
              box-shadow: inset 2px 2px 0px #ffffff, inset -2px -2px 0px #709c90, 4px 4px 0px #000000 !important;
              width: 100% !important;
              height: 100% !important;
              box-sizing: border-box !important;
              overflow: hidden;
            }
            
            /* Scanline Title Bar */
            .retro-title-bar {
              height: 28px !important;
              min-height: 28px !important;
              border-bottom: 2px solid #000000 !important;
              background-color: #b4dcd0 !important;
              display: flex !important;
              align-items: center !important;
              box-sizing: border-box !important;
              padding: 0 8px !important;
            }
            .retro-title-left-buttons {
              display: flex !important;
              gap: 6px !important;
              align-items: center !important;
              flex-shrink: 0 !important;
              width: 44px !important;
            }
            .retro-title-right-buttons {
              display: flex !important;
              align-items: center !important;
              justify-content: flex-end !important;
              flex-shrink: 0 !important;
              width: 44px !important;
            }
            .retro-title-stripes {
              flex: 1 !important;
              height: 9px !important;
              margin: 0 10px !important;
              background-image: repeating-linear-gradient(0deg, #000000, #000000 1px, transparent 1px, transparent 2px) !important;
              pointer-events: none !important;
            }
            .retro-title-text-container {
              flex-shrink: 0 !important;
              display: flex !important;
              align-items: center !important;
              justify-content: center !important;
            }
            .retro-title-text {
              font-family: 'ChiKareGo', "Geneva", "Chicago", -apple-system, sans-serif !important;
              font-size: 20px !important;
              font-weight: bold !important;
              color: #000000 !important;
              text-transform: none !important;
              letter-spacing: 2px !important;
            }
            .retro-close-box, .retro-minimize-box, .retro-settings-box {
              width: 16px !important;
              height: 16px !important;
              border: none !important;
              background: transparent !important;
              box-shadow: none !important;
              cursor: pointer !important;
              display: flex !important;
              align-items: center !important;
              justify-content: center !important;
              box-sizing: border-box !important;
              padding: 0 !important;
            }
            .retro-close-box:hover, .retro-minimize-box:hover, .retro-settings-box:hover {
              background: #000000 !important;
            }
            .retro-btn-icon {
              width: 12px !important;
              height: 12px !important;
              color: #000000 !important;
            }
            .retro-close-box:hover .retro-btn-icon,
            .retro-minimize-box:hover .retro-btn-icon,
            .retro-settings-box:hover .retro-btn-icon {
              color: #ffffff !important;
            }
            
            .retro-window-content {
              flex: 1 !important;
              height: 0 !important;
              min-height: 0 !important;
              overflow-y: auto !important;
              background: #b4dcd0 !important;
              position: relative !important;
            }
            
            /* Custom classic Mac OS scrollbar styling */
            .retro-window-content::-webkit-scrollbar {
              width: 16px !important;
            }
            .retro-window-content::-webkit-scrollbar-track {
              background: #b4dcd0 !important;
              background-image: radial-gradient(#8cbcae 1px, transparent 1px) !important;
              background-size: 4px 4px !important;
              border-left: none !important;
              border-right: none !important;
              border-top: none !important;
              border-bottom: none !important;
            }
            .retro-window-content::-webkit-scrollbar-thumb {
              background: #ffffff !important;
              border: none !important;
              box-shadow: none !important;
            }
            .retro-window-content::-webkit-scrollbar-button {
              display: block !important;
              height: 16px !important;
              background-color: #ffffff !important;
              background-repeat: no-repeat !important;
              background-position: center !important;
              background-size: 12px 12px !important;
              box-sizing: border-box !important;
              border-left: none !important;
              border-right: none !important;
            }
            .retro-window-content::-webkit-scrollbar-button:vertical {
              border-left: none !important;
              border-right: none !important;
              box-sizing: border-box !important;
            }
            .retro-window-content::-webkit-scrollbar-button:start:increment,
            .retro-window-content::-webkit-scrollbar-button:end:decrement {
              display: none !important;
              height: 0px !important;
              width: 0px !important;
            }
            .retro-window-content::-webkit-scrollbar-button:vertical:start:decrement {
              border-top: none !important;
              border-bottom: 2px solid #000000 !important;
              border-left: none !important;
              border-right: none !important;
              background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(7.000000, 9.000000)" fill="black"><polygon fill-rule="nonzero" points="4 2 4 0 6 0 6 2"/><polygon fill-rule="nonzero" points="2 4 2 2 4 2 4 4"/><polygon fill-rule="nonzero" points="2 4 2 6 0 6 0 4"/><path d="M8,4 L8,2 L6,2 L6,4 L8,4 Z M8,4 L10,4 L10,6 L8,6 L8,4 Z"/></g></g></svg>') !important;
            }
            .retro-window-content::-webkit-scrollbar-button:vertical:end:decrement {
              border-top: 2px solid #000000 !important;
              border-bottom: none !important;
              border-left: none !important;
              border-right: none !important;
              background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(7.000000, 9.000000)" fill="black"><polygon fill-rule="nonzero" points="4 2 4 0 6 0 6 2"/><polygon fill-rule="nonzero" points="2 4 2 2 4 2 4 4"/><polygon fill-rule="nonzero" points="2 4 2 6 0 6 0 4"/><path d="M8,4 L8,2 L6,2 L6,4 L8,4 Z M8,4 L10,4 L10,6 L8,6 L8,4 Z"/></g></g></svg>') !important;
            }
            .retro-window-content::-webkit-scrollbar-button:vertical:end:increment {
              border-top: 2px solid #000000 !important;
              border-bottom: none !important;
              border-left: none !important;
              border-right: none !important;
              background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" shape-rendering="crispEdges"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(7.000000, 9.000000)" fill="black" fill-rule="nonzero"><polygon points="6 4 6 6 4 6 4 4"/><polygon points="8 2 8 4 6 4 6 2"/><polygon points="4 2 4 4 2 4 2 2"/><polygon points="10 0 10 2 8 2 8 0"/><polygon points="2 0 2 2 0 2 0 0"/></g></g></svg>') !important;
            }
            
            .gallery {
              border: none !important;
              min-height: 100% !important;
              grid-template-columns: repeat(6, 1fr) !important;
              background: transparent !important;
              margin-bottom: 0 !important;
              box-sizing: border-box !important;
              padding: 12px !important;
            }
            
            .tile-dl {
              display: none !important;
            }
            
            /* Compact Borderless Desktop Folder Layout */
            .tile {
              border-radius: 0 !important;
              border: none !important;
              background: transparent !important;
              padding: 12px 8px 8px !important;
              transition: none !important;
              display: flex !important;
              flex-direction: column !important;
              align-items: center !important;
              justify-content: center !important;
              gap: 4px !important;
            }
            .tile-stage {
              width: 80px !important;
              height: 80px !important;
              aspect-ratio: auto !important;
              display: grid !important;
              place-items: center !important;
              position: relative !important;
              transform: scale(0.75) !important;
              transform-origin: bottom center !important;
              margin-bottom: -6px !important;
            }
            .tile:hover {
              background: rgba(0, 0, 0, 0.05) !important;
              outline: 1px dotted #000000 !important;
              outline-offset: -2px !important;
            }
            
            /* Action Button replacing Pet Name on hover */
            .tile-name {
              display: block !important;
              font-family: 'Habbo', 'battlenet', 'dogica', 'TinyUnicode', 'W95F', 'MS Sans Serif', "Geneva", "Chicago", -apple-system, sans-serif !important;
              font-size: 16px !important;
              font-weight: normal !important;
              letter-spacing: 0px !important;
              text-align: center !important;
              padding: 2px 4px !important;
              color: #000000 !important;
              line-height: 1.2 !important;
              -webkit-font-smoothing: none !important;
              font-smoothing: none !important;
            }
            .tile:not(.native-active):hover .tile-name {
              display: none !important;
            }
            
            /* Retro Double-bordered Action Buttons -> Restyled to borderless outline icons with high-density click areas */
            .app-action-btn {
              display: none;
              align-items: center;
              justify-content: center;
              width: 32px !important;
              height: 24px !important;
              padding: 0 !important;
              border: none !important;
              background: transparent !important;
              box-shadow: none !important;
              cursor: pointer !important;
              position: static !important;
              transform: none !important;
              color: rgba(0, 0, 0, 0.56) !important;
              box-sizing: border-box !important;
            }
            .tile:not(.native-active):hover .app-action-btn {
              display: inline-flex !important;
            }
            .tile.native-active:hover {
              background: transparent !important;
              outline: none !important;
            }
            .app-action-btn:hover {
              color: #000000 !important;
              background: transparent !important;
              border: none !important;
              box-shadow: none !important;
            }
            .app-action-btn.delete-btn {
              color: rgba(0, 0, 0, 0.56) !important;
            }
            .app-action-btn.delete-btn:hover {
              color: #000000 !important;
              background: transparent !important;
              border: none !important;
              box-shadow: none !important;
            }
            
            /* Installed: colorful static image */
            .tile.native-installed:not(.playing) .sprite-static-gray {
              filter: grayscale(0%) !important;
              opacity: 1 !important;
            }
            .tile.native-installed:not(.playing) .sprite-static-color {
              clip-path: inset(0% 0 0 0) !important;
            }
                        /* System 7 Active selection label inversion */
            .tile.native-active .tile-label {
              background: transparent !important;
              padding: 2px 6px !important;
              border-radius: 0 !important;
            }
            .tile.native-active .tile-name {
              background: transparent !important;
              color: #000000 !important;
              padding: 2px 4px !important;
              display: block !important;
              text-align: center !important;
              height: auto !important;
              line-height: 1.2 !important;
              width: auto !important;
              max-width: 100% !important;
              box-sizing: border-box !important;
            }

            
            /* Selection inversion flash animation & retro watch ticker */
            .tile.native-applying {
              animation: retro-tile-flash 0.15s steps(2) 2 !important;
              position: relative !important;
            }
            .tile.native-applying .sprite-stage {
              opacity: 0.3 !important;
            }
            /* Pocket watch body */
            .tile.native-applying::after {
              content: "" !important;
              position: absolute !important;
              top: 50% !important;
              left: 50% !important;
              width: 24px !important;
              height: 24px !important;
              transform: translate(-50%, -50%) !important;
              background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><path d="M6 1h4v1H6zM5 2h6v1H5zM3 3h10v1H3zM2 4h12v8H2zM3 12h10v1H3zM5 13h6v1H5zM6 14h4v1H6z" fill="black"/><circle cx="8" cy="8" r="4" fill="white"/></svg>') !important;
              background-size: 100% 100% !important;
              z-index: 10 !important;
            }
            /* Pocket watch hand */
            .tile.native-applying::before {
              content: "" !important;
              position: absolute !important;
              top: 50% !important;
              left: 50% !important;
              width: 1px !important;
              height: 6px !important;
              background: black !important;
              transform-origin: 50% 100% !important;
              margin-top: -6px !important;
              margin-left: -0.5px !important;
              z-index: 11 !important;
              animation: retro-watch-tick 0.6s steps(4) infinite !important;
            }
            @keyframes retro-tile-flash {
              0% { filter: invert(0%); }
              100% { filter: invert(100%); }
            }
            @keyframes retro-watch-tick {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
            
            /* Image Preview Rendering */
            .sprite-static {
              image-rendering: pixelated !important;
              image-rendering: crisp-edges !important;
            }
            .sprite-player {
              image-rendering: pixelated !important;
              image-rendering: crisp-edges !important;
            }
            
            /* NEW badge styling */
            .tile.is-new-pet::before {
              content: "NEW" !important;
              position: absolute !important;
              top: 6px !important;
              left: 6px !important;
              background: #ffffff !important;
              color: #000000 !important;
              border: 2px solid #000000 !important;
              font-family: 'ChiKareGo2', "Geneva", "Chicago", -apple-system, sans-serif !important;
              font-size: 8px !important;
              font-weight: bold !important;
              padding: 1px 4px !important;
              border-radius: 0 !important;
              z-index: 5 !important;
              box-shadow: 1px 1px 0px #000000 !important;
              transition: none !important;
            }
            .tile.native-active.is-new-pet::before {
              display: none !important;
            }
            
            /* Defrost Loader Overrides */
            .defrost-loader {
              background: #ffffff !important;
              border: 2px solid #000000 !important;
              box-shadow: 4px 4px 0px #000000 !important;
              width: calc(100% - 32px) !important;
              height: calc(100% - 32px) !important;
              top: 16px !important;
              left: 16px !important;
              position: absolute !important;
              box-sizing: border-box !important;
            }
            .defrost-logo {
              font-family: 'ChiKareGo2', "Geneva", "Chicago", -apple-system, sans-serif !important;
              font-weight: bold !important;
              letter-spacing: 4px !important;
            }
            .defrost-progress {
              border: 2px solid #000000 !important;
              border-radius: 0 !important;
              background: #ffffff !important;
              height: 12px !important;
              width: 160px !important;
            }
            .defrost-progress-bar {
              background: #000000 !important;
              border-radius: 0 !important;
            }
          `;
          document.documentElement.appendChild(style);

          // Wrap gallery in standard System 7 window shell
          function initRetroWindow() {
            const gallery = document.getElementById("gallery");
            if (gallery && !document.getElementById("retro-window")) {
              const wrapper = document.createElement("div");
              wrapper.id = "retro-window";
              wrapper.className = "retro-window";
              
              const titleBar = document.createElement("div");
              titleBar.className = "retro-title-bar";
              titleBar.innerHTML = `
                <div class="retro-title-left-buttons">
                  <div class="retro-close-box" title="Close">
                    <svg viewBox="0 0 24 24" shape-rendering="crispEdges" class="retro-btn-icon"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(7.000000, 7.000000)" fill="currentColor" fill-rule="nonzero"><polygon points="0 10 2 10 2 8 4 8 4 6 6 6 6 8 8 8 8 10 10 10 10 8 8 8 8 6 6 6 6 4 4 4 4 2.00001 2 2.00001 2 1e-05 0 1e-05 0 2.00001 2 2.00001 2 4 4 4 4 6 2 6 2 8 0 8"/><polygon points="10 2 8 2 8 0 10 0"/><polygon points="8 2 6 2 6 4 8 4"/></g></g></svg>
                  </div>
                  <div class="retro-minimize-box" title="Minimize">
                    <svg viewBox="0 0 24 24" shape-rendering="crispEdges" class="retro-btn-icon"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(7.000000, 11.000000)" fill="currentColor" fill-rule="nonzero"><polygon points="10 0 10 2 0 2 0 0"/></g></g></svg>
                  </div>
                </div>
                <div class="retro-title-stripes"></div>
                <div class="retro-title-text-container">
                  <span class="retro-title-text">codpet</span>
                </div>
                <div class="retro-title-stripes"></div>
                <div class="retro-title-right-buttons">
                  <div class="retro-settings-box" title="Settings">
                    <svg viewBox="0 0 24 24" shape-rendering="crispEdges" class="retro-btn-icon"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g transform="translate(12.000000, 12.000000) rotate(-270.000000) translate(-12.000000, -12.000000) translate(4.000000, 4.000000)" fill="currentColor"><path d="M14,2 L14,3.7711671e-15 L10,3.7711671e-15 L10,2 L8,2 L8,6 L10,6 L10,8 L14,8 L14,6 L16,6 L16,2 L14,2 Z M14,2 L14,6 L10,6 L10,2 L14,2 Z"/><polygon fill-rule="nonzero" points="6 5 6 3 0 3 0 5"/><polygon fill-rule="nonzero" points="16 13 16 11 10 11 10 13"/><polygon fill-rule="nonzero" points="6 8 6 10 2 10 2 8"/><polygon fill-rule="nonzero" points="0 10 2 10 2 14 0 14"/><polygon fill-rule="nonzero" points="6 14 6 16 2 16 2 14"/><polygon fill-rule="nonzero" points="6 14 8 14 8 10 6 10"/></g></g></svg>
                  </div>
                </div>
              `;
              
              const content = document.createElement("div");
              content.className = "retro-window-content";
              
              gallery.parentNode.insertBefore(wrapper, gallery);
              wrapper.appendChild(titleBar);
              wrapper.appendChild(content);
              content.appendChild(gallery);

              // Observe changes to gallery to tag 6th-column tiles dynamically
              const tileColObserver = new MutationObserver(() => {
                const tiles = Array.from(gallery.querySelectorAll(".tile"));
                tiles.forEach((tile, index) => {
                  if ((index + 1) % 6 === 0) {
                    tile.classList.add("col-6");
                  } else {
                    tile.classList.remove("col-6");
                  }
                });
              });
              tileColObserver.observe(gallery, { childList: true });
              
              // Run immediately to cover initial items
              const initialTiles = Array.from(gallery.querySelectorAll(".tile"));
              initialTiles.forEach((tile, index) => {
                if ((index + 1) % 6 === 0) {
                  tile.classList.add("col-6");
                } else {
                  tile.classList.remove("col-6");
                }
              });
            }
          }
          if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", initRetroWindow);
          } else {
            initRetroWindow();
          }

          // NEW badge local tracker
          const SEEN_KEY = "codpet_seen_slugs";
          let seenSlugs = new Set(JSON.parse(localStorage.getItem(SEEN_KEY) || "[]"));
          
          window.updateNewBadges = function() {
            const tiles = document.querySelectorAll(".tile");
            if (tiles.length === 0) return;
            
            if (seenSlugs.size === 0) {
              // First run: mark all current pets as seen
              const allSlugs = Array.from(tiles).map(t => t.dataset.slug);
              seenSlugs = new Set(allSlugs);
              localStorage.setItem(SEEN_KEY, JSON.stringify(Array.from(seenSlugs)));
            } else {
              tiles.forEach(tile => {
                const slug = tile.dataset.slug;
                if (!seenSlugs.has(slug)) {
                  tile.classList.add("is-new-pet");
                }
              });
            }
          };

          // Hover listeners to clear NEW badge
          document.addEventListener("mouseenter", function(event) {
            const tile = event.target.closest(".tile");
            if (!tile) return;
            const slug = tile.dataset.slug;
            if (tile.classList.contains("is-new-pet")) {
              tile._seenTimeout = setTimeout(() => {
                tile.classList.remove("is-new-pet");
                seenSlugs.add(slug);
                localStorage.setItem(SEEN_KEY, JSON.stringify(Array.from(seenSlugs)));
              }, 1000);
            }
          }, true);

          document.addEventListener("mouseleave", function(event) {
            const tile = event.target.closest(".tile");
            if (!tile) return;
            if (tile._seenTimeout) {
              clearTimeout(tile._seenTimeout);
              delete tile._seenTimeout;
            }
          }, true);

          // Unified Click Router
          document.addEventListener("click", function(event) {
            const closeBtn = event.target.closest(".retro-close-box");
            if (closeBtn) {
              event.preventDefault();
              event.stopPropagation();
              event.stopImmediatePropagation();
              window.webkit.messageHandlers.codpetNative.postMessage({
                type: "closeWindow",
                slug: ""
              });
              return;
            }

            const minimizeBtn = event.target.closest(".retro-minimize-box");
            if (minimizeBtn) {
              event.preventDefault();
              event.stopPropagation();
              event.stopImmediatePropagation();
              window.webkit.messageHandlers.codpetNative.postMessage({
                type: "minimizeWindow",
                slug: ""
              });
              return;
            }

            const zoomBtn = event.target.closest(".retro-zoom-box");
            if (zoomBtn) {
              event.preventDefault();
              event.stopPropagation();
              event.stopImmediatePropagation();
              window.webkit.messageHandlers.codpetNative.postMessage({
                type: "zoomWindow",
                slug: ""
              });
              return;
            }

            const settingsBtn = event.target.closest(".retro-settings-box");
            if (settingsBtn) {
              event.preventDefault();
              event.stopPropagation();
              event.stopImmediatePropagation();
              window.webkit.messageHandlers.codpetNative.postMessage({
                type: "openSettings",
                slug: ""
              });
              return;
            }

            const actionBtn = event.target.closest(".app-action-btn");
            const tile = event.target.closest(".tile");
            
            if (actionBtn) {
              event.preventDefault();
              event.stopPropagation();
              event.stopImmediatePropagation();
              
              const slug = actionBtn.dataset.slug;
              const action = actionBtn.dataset.action;
              
              window.webkit.messageHandlers.codpetNative.postMessage({
                type: action,
                slug: slug
              });
              return;
            }
            
                        if (tile) {
              event.preventDefault();
              event.stopPropagation();
              event.stopImmediatePropagation();
              
              const slug = tile.dataset.slug;
              const isInstalled = tile.classList.contains("native-installed");
              const isActive = tile.classList.contains("native-active");
              
              if (isInstalled && !isActive) {
                // Apply System 7 style flash & watch loader feedback
                tile.classList.add("native-applying");
                setTimeout(() => {
                  tile.classList.remove("native-applying");
                }, 600);
              }
              
              window.webkit.messageHandlers.codpetNative.postMessage({
                type: isInstalled ? "apply" : "install",
                slug: slug
              });
            }
          }, true);

          window.codpetNativeSync = function(payload) {
            const installed = new Set((payload && payload.installed) || []);
            const active = payload && payload.active ? payload.active : "";
            
            // Check & draw NEW badges
            if (typeof window.updateNewBadges === "function") {
              window.updateNewBadges();
            }
            
            document.querySelectorAll(".tile").forEach((tile) => {
              const slug = tile.dataset.slug;
              const isInstalled = installed.has(slug);
              const isActive = slug === active;
              
              tile.classList.toggle("native-installed", isInstalled);
              tile.classList.toggle("native-active", isActive);
              
              // Append (using) to display name if active, restore base name if not
              const nameEl = tile.querySelector(".tile-name");
              if (nameEl) {
                if (!nameEl._baseName) {
                  nameEl._baseName = nameEl.textContent;
                }
                nameEl.textContent = isActive ? nameEl._baseName + " (using)" : nameEl._baseName;
              }

              // Active companion continuous play
              const wasActivePlay = !!tile._isActivePlay;
              tile._isActivePlay = isActive;
              if (isActive) {
                if (!wasActivePlay) {
                  startHover(tile);
                }
              } else {
                if (wasActivePlay) {
                  if (!tile._isHovered) {
                    stopHover(tile);
                  }
                }
              }
              
              let labelEl = tile.querySelector(".tile-label");
              if (labelEl) {
                let actionBtn = labelEl.querySelector(".app-action-btn");
                if (!actionBtn) {
                  actionBtn = document.createElement("button");
                  actionBtn.type = "button";
                  actionBtn.className = "app-action-btn";
                  labelEl.appendChild(actionBtn);
                }
                
                actionBtn.dataset.slug = slug;
                if (isInstalled) {
                  actionBtn.className = "app-action-btn delete-btn";
                  actionBtn.innerHTML = trashIcon;
                  actionBtn.dataset.action = "uninstall";
                  actionBtn.title = "Delete local pet";
                } else {
                  actionBtn.className = "app-action-btn install-btn";
                  actionBtn.innerHTML = downloadIcon;
                  actionBtn.dataset.action = "install";
                  actionBtn.title = "Install locally";
                }
              }
            });
          };
        })();
        """
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var store: CodpetHybridStore
        var isShowingSettings: Binding<Bool>
        
        init(store: CodpetHybridStore, isShowingSettings: Binding<Bool>) {
            self.store = store
            self.isShowingSettings = isShowingSettings
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "codpetNative",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String,
                  let slug = body["slug"] as? String else {
                return
            }
            
            switch type {
            case "install":
                store.installPet(slug: slug)
            case "apply":
                _ = store.applyPet(slug: slug)
            case "uninstall":
                store.uninstallPet(slug: slug)
            case "closeWindow":
                NSApp.terminate(nil)
            case "minimizeWindow":
                DispatchQueue.main.async {
                    if let window = message.webView?.window {
                        window.miniaturize(nil)
                    } else if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
                        window.miniaturize(nil)
                    }
                }
            case "zoomWindow":
                DispatchQueue.main.async {
                    if let window = message.webView?.window {
                        window.zoom(nil)
                    } else if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
                        window.zoom(nil)
                    }
                }
            case "openSettings":
                DispatchQueue.main.async {
                    self.isShowingSettings.wrappedValue = true
                }
            default:
                break
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            syncInstalledState(in: webView)
        }
        
        func syncInstalledState(in webView: WKWebView) {
            let script = "window.codpetNativeSync && window.codpetNativeSync(\(store.installedSlugsJSON()))"
            webView.evaluateJavaScript(script)
        }
    }
}

// Window Accessor for frameless styling
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.callback(window)
                
                // Keep them hidden whenever window state changes
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didBecomeKeyNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    self.callback(window)
                }
                
                NotificationCenter.default.addObserver(
                    forName: NSWindow.didUpdateNotification,
                    object: window,
                    queue: .main
                ) { _ in
                    self.callback(window)
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class DraggableNSView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let superview = superview else { return nil }
        let localPoint = convert(point, from: superview)
        if bounds.contains(localPoint) {
            return self
        }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
