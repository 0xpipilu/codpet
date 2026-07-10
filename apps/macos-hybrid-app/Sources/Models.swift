import Foundation

struct AtlasInfo: Codable, Hashable {
    let columns: Int
    let rows: Int
    let frameWidth: Int
    let frameHeight: Int
    let sheetWidth: Int
    let sheetHeight: Int
}

struct PreviewRow: Codable, Hashable, Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let rowIndex: Int
    let frames: Int
    let durationMs: Int
    let semantic: String?
    let notes: String?
}

struct PetIndexEntry: Codable, Hashable, Identifiable {
    var id: String { slug }
    let slug: String
    let folder: String
    let displayName: String
    let description: String
    let spritesheetPath: String
    let petJsonPath: String
    let spritesheetFile: String
    let atlas: AtlasInfo
    let previewRows: [PreviewRow]
    let defaultPreviewRow: String
}

struct PetCatalog: Codable {
    let count: Int
    let pets: [PetIndexEntry]
}

struct LocalPetConfig: Codable {
    let id: String?
    let displayName: String
    let description: String
    let spritesheetPath: String?
    
    struct LocalAtlas: Codable {
        let columns: Int
        let rows: Int
        let cellWidth: Int
        let cellHeight: Int
    }
    
    let atlas: LocalAtlas?
    let atlasRowSemantics: [String: String]?
}

struct InstalledPet: Identifiable, Hashable {
    var id: String { slug }
    let slug: String
    let displayName: String
    let description: String
    let folderURL: URL
    let previewImageURL: URL?
}

enum HybridTab: String, CaseIterable, Identifiable {
    case discover = "发现"
    case installed = "已安装"
    case settings = "设置"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .discover:
            return "sparkles.rectangle.stack"
        case .installed:
            return "pawprint.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

enum CodexApplyMode: String, CaseIterable, Identifiable {
    case softReload
    case restartCodex
    case manual
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .softReload:
            return "尝试即时刷新"
        case .restartCodex:
            return "重启 Codex"
        case .manual:
            return "手动刷新"
        }
    }
    
    var subtitle: String {
        switch self {
        case .softReload:
            return "优先调用 Codex 自己的内部应用接口；如果 macOS 没授权或 Codex 窗口不可控，再回退到刷新窗口。"
        case .restartCodex:
            return "当即时刷新不可用时，这是目前最稳的兜底方案。"
        case .manual:
            return "只写入配置，由你自己回到 Codex 里刷新或重新选择。"
        }
    }
}
