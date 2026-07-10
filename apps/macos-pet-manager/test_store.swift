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

struct PreviewRow: Codable, Hashable {
    let key: String
    let label: String
    let rowIndex: Int
    let frames: Int
    let durationMs: Int
    let semantic: String?
    let notes: String?
}

struct PetCatalogEntry: Codable, Hashable {
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

enum PetSource: String, Hashable {
    case codpet = "cod.pet"
    case local = "Local"
}

struct PetRecord: Hashable {
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

struct PetRepository {
    let fileManager = FileManager.default
    
    var codexDir: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
    }
    
    var petsDir: URL {
        codexDir.appendingPathComponent("pets")
    }
    
    func bundledCatalogRoot() -> URL? {
        // Since we are running outside the app bundle, we simulate this by looking at the built app
        let projectRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let appBundleURL = projectRoot.appendingPathComponent("dist/CodpetPersonal.app")
        let catalogURL = appBundleURL.appendingPathComponent("Contents/Resources/Catalog")
        guard fileManager.fileExists(atPath: catalogURL.appendingPathComponent("index.json").path),
              fileManager.fileExists(atPath: catalogURL.appendingPathComponent("pets").path) else {
            return nil
        }
        return catalogURL
    }
    
    func loadCatalog(from repoRoot: URL?) -> [PetCatalogEntry] {
        guard let repoRoot else { return [] }
        let indexURL = repoRoot.appendingPathComponent("index.json")
        
        do {
            let data = try Data(contentsOf: indexURL)
            let decoded = try JSONDecoder().decode(PetCatalog.self, from: data)
            return decoded.pets
        } catch {
            print("Failed to decode Catalog index.json: \(error)")
            return []
        }
    }
    
    func loadInstalledPets(repoRoot: URL?, catalog: [PetCatalogEntry]) -> [PetRecord] {
        let catalogBySlug = Dictionary(uniqueKeysWithValues: catalog.map { ($0.slug.lowercased(), $0) })
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: petsDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return contents.compactMap { folderURL in
            makeLocalPetRecord(
                from: folderURL,
                repoRoot: repoRoot,
                catalogBySlug: catalogBySlug
            )
        }
    }
    
    private func firstExistingURL(at folder: URL, candidates: [String]) -> URL? {
        for candidate in candidates {
            let url = folder.appendingPathComponent(candidate)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }
    
    private func makeLocalPetRecord(
        from folderURL: URL,
        repoRoot: URL?,
        catalogBySlug: [String: PetCatalogEntry]
    ) -> PetRecord? {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }
        
        let slug = folderURL.lastPathComponent
        let normalizedSlug = slug.lowercased()
        let petJSONURL = folderURL.appendingPathComponent("pet.json")
        let data = try? Data(contentsOf: petJSONURL)
        let localConfig = data.flatMap { try? JSONDecoder().decode(LocalPetConfig.self, from: $0) }
        let matchedCatalog = catalogBySlug[normalizedSlug]
        
        let displayName = localConfig?.displayName
            ?? matchedCatalog?.displayName
            ?? slug
        let description = localConfig?.description
            ?? matchedCatalog?.description
            ?? "Local Codex pet."
        
        let atlas: AtlasInfo
        if let localAtlas = localConfig?.atlas {
            atlas = AtlasInfo(
                columns: localAtlas.columns,
                rows: localAtlas.rows,
                frameWidth: localAtlas.cellWidth,
                frameHeight: localAtlas.cellHeight,
                sheetWidth: localAtlas.columns * localAtlas.cellWidth,
                sheetHeight: localAtlas.rows * localAtlas.cellHeight
            )
        } else {
            atlas = matchedCatalog?.atlas ?? .standardCodpet
        }
        
        let previewRows = matchedCatalog?.previewRows ?? PetRecord.fallbackPreviewRows
        let defaultPreviewRowKey = matchedCatalog?.defaultPreviewRow ?? previewRows.first?.key ?? "idle"
        let spritesheetName = localConfig?.spritesheetPath ?? matchedCatalog?.spritesheetPath ?? "spritesheet.webp"
        let spritesheetURL = folderURL.appendingPathComponent(spritesheetName)
        let stillPreviewURL = firstExistingURL(at: folderURL, candidates: ["base.png", "base.webp", spritesheetName])
        let repoFolderURL = matchedCatalog.flatMap { entry in
            repoRoot?.appendingPathComponent(entry.folder)
        }
        
        return PetRecord(
            slug: slug,
            normalizedSlug: normalizedSlug,
            displayName: displayName,
            description: description,
            source: matchedCatalog == nil ? .local : .codpet,
            atlas: atlas,
            previewRows: previewRows,
            defaultPreviewRowKey: defaultPreviewRowKey,
            spritesheetURL: fileManager.fileExists(atPath: spritesheetURL.path) ? spritesheetURL : nil,
            stillPreviewURL: stillPreviewURL,
            repoFolderURL: repoFolderURL,
            installedFolderURL: folderURL,
            isInstalled: true,
            isActive: false
        )
    }
}

let repository = PetRepository()
if let repoRoot = repository.bundledCatalogRoot() {
    print("repoRoot found: \(repoRoot.path)")
    let catalog = repository.loadCatalog(from: repoRoot)
    print("Catalog entry count: \(catalog.count)")
    let installed = repository.loadInstalledPets(repoRoot: repoRoot, catalog: catalog)
    print("Installed pets count: \(installed.count)")
    if let first = installed.first {
        print("First pet details - displayName: \(first.displayName), slug: \(first.slug), source: \(first.source)")
    }
} else {
    print("repoRoot is nil")
}
