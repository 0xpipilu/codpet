import Foundation

struct AtlasInfo: Codable, Hashable {
    let columns: Int
    let rows: Int
    let frameWidth: Int
    let frameHeight: Int
    let sheetWidth: Int
    let sheetHeight: Int
    
    static let standardCodpet = AtlasInfo(
        columns: 8,
        rows: 9,
        frameWidth: 192,
        frameHeight: 208,
        sheetWidth: 1536,
        sheetHeight: 1872
    )
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

struct PetCatalogEntry: Codable, Hashable, Identifiable {
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
    let pets: [PetCatalogEntry]
}

struct LocalPetConfig: Codable {
    struct LocalAtlas: Codable {
        let columns: Int
        let rows: Int
        let cellWidth: Int
        let cellHeight: Int
    }
    
    let id: String?
    let displayName: String
    let description: String
    let spritesheetPath: String?
    let atlas: LocalAtlas?
}

enum LibrarySection: String, CaseIterable, Identifiable {
    case myPets = "My Pets"
    case discover = "Discover"
    
    var id: String { rawValue }
}

enum PetSource: String, Hashable {
    case codpet = "cod.pet"
    case local = "Local"
}

enum ApplyMode: String, CaseIterable, Identifiable {
    case immediate = "immediate"
    case configOnly = "configOnly"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .immediate:
            return "Apply Without Restart"
        case .configOnly:
            return "Config Only"
        }
    }
    
    var subtitle: String {
        switch self {
        case .immediate:
            return "Try to switch the running Codex pet live without touching the current Codex window. If this session was launched without Codpet's live channel, use Enable Live Apply Once in Settings."
        case .configOnly:
            return "Only update the config file. The change will appear after you return to Codex."
        }
    }
}

struct PetRecord: Identifiable, Hashable {
    var id: String { normalizedSlug }
    
    let slug: String
    let normalizedSlug: String
    let displayName: String
    let description: String
    let source: PetSource
    let atlas: AtlasInfo
    let previewRows: [PreviewRow]
    let defaultPreviewRowKey: String
    let spritesheetURL: URL?
    let stillPreviewURL: URL?
    let repoFolderURL: URL?
    let installedFolderURL: URL?
    let isInstalled: Bool
    let isActive: Bool
    
    var sourceLabel: String { source.rawValue }
    
    var defaultPreviewRow: PreviewRow {
        previewRows.first(where: { $0.key == defaultPreviewRowKey }) ?? previewRows.first ?? Self.fallbackPreviewRows[0]
    }
    
    static let fallbackPreviewRows: [PreviewRow] = [
        PreviewRow(key: "idle", label: "Idle", rowIndex: 0, frames: 6, durationMs: 1100, semantic: "idle", notes: nil),
        PreviewRow(key: "running-right", label: "Run Right", rowIndex: 1, frames: 8, durationMs: 980, semantic: "walk-right", notes: nil),
        PreviewRow(key: "running-left", label: "Run Left", rowIndex: 2, frames: 8, durationMs: 980, semantic: "walk-left", notes: nil),
        PreviewRow(key: "waving", label: "Waving", rowIndex: 3, frames: 4, durationMs: 840, semantic: "happy", notes: nil),
        PreviewRow(key: "jumping", label: "Jumping", rowIndex: 4, frames: 5, durationMs: 900, semantic: "pounce", notes: nil),
        PreviewRow(key: "failed", label: "Failed", rowIndex: 5, frames: 8, durationMs: 1120, semantic: "roll", notes: nil),
        PreviewRow(key: "waiting", label: "Waiting", rowIndex: 6, frames: 6, durationMs: 1260, semantic: "sleep", notes: nil),
        PreviewRow(key: "running", label: "Running", rowIndex: 7, frames: 6, durationMs: 960, semantic: "walk", notes: nil),
        PreviewRow(key: "review", label: "Review", rowIndex: 8, frames: 6, durationMs: 1080, semantic: "curious", notes: nil)
    ]
}
