import AppKit
import Foundation

struct PetRepository {
    private let fileManager = FileManager.default
    
    var codexDir: URL {
        fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
    }
    
    var petsDir: URL {
        codexDir.appendingPathComponent("pets")
    }
    
    var trashDir: URL {
        codexDir.appendingPathComponent("trash")
    }
    
    func isRepositoryRoot(_ url: URL) -> Bool {
        looksLikeRepositoryRoot(url)
    }
    
    func bundledCatalogRoot() -> URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let catalogURL = resourceURL.appendingPathComponent("Catalog")
        guard fileManager.fileExists(atPath: catalogURL.appendingPathComponent("index.json").path),
              fileManager.fileExists(atPath: catalogURL.appendingPathComponent("pets").path) else {
            return nil
        }
        return catalogURL
    }
    
    func locateRepositoryRoot() -> URL? {
        var candidates: [URL] = []
        
        if let envPath = ProcessInfo.processInfo.environment["CODPET_REPO_ROOT"] {
            candidates.append(URL(fileURLWithPath: envPath))
        }
        
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        candidates.append(currentDirectory)
        candidates.append(contentsOf: ancestors(of: currentDirectory))
        
        let bundleDirectory = Bundle.main.bundleURL.deletingLastPathComponent()
        candidates.append(bundleDirectory)
        candidates.append(contentsOf: ancestors(of: bundleDirectory))
        
        for candidate in candidates where looksLikeRepositoryRoot(candidate) {
            return candidate
        }
        
        return nil
    }
    
    func loadCatalog(from repoRoot: URL?) -> [PetCatalogEntry] {
        guard let repoRoot else { return [] }
        let indexURL = repoRoot.appendingPathComponent("index.json")
        
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode(PetCatalog.self, from: data) else {
            return []
        }
        
        return decoded.pets
    }
    
    func loadInstalledPets(repoRoot: URL?, catalog: [PetCatalogEntry], activeSlug: String?) -> [PetRecord] {
        ensurePetsDirectory()
        
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
                catalogBySlug: catalogBySlug,
                activeSlug: activeSlug,
                isInstalled: true
            )
        }
        .sorted { lhs, rhs in
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
    
    func loadTrashedPets(repoRoot: URL?, catalog: [PetCatalogEntry]) -> [PetRecord] {
        ensureTrashDirectory()
        
        let catalogBySlug = Dictionary(uniqueKeysWithValues: catalog.map { ($0.slug.lowercased(), $0) })
        guard let contents = try? fileManager.contentsOfDirectory(
            at: trashDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return contents.compactMap { folderURL in
            makeLocalPetRecord(
                from: folderURL,
                repoRoot: repoRoot,
                catalogBySlug: catalogBySlug,
                activeSlug: nil,
                isInstalled: false
            )
        }
        .sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
    
    func makeDiscoverPets(repoRoot: URL?, catalog: [PetCatalogEntry], installedPets: [PetRecord], activeSlug: String?) -> [PetRecord] {
        let installedBySlug = Dictionary(uniqueKeysWithValues: installedPets.map { ($0.normalizedSlug, $0) })
        
        return catalog.map { entry in
            if let installed = installedBySlug[entry.slug.lowercased()] {
                return PetRecord(
                    slug: installed.slug,
                    normalizedSlug: installed.normalizedSlug,
                    displayName: installed.displayName,
                    description: installed.description,
                    source: .codpet,
                    atlas: entry.atlas,
                    previewRows: entry.previewRows,
                    defaultPreviewRowKey: entry.defaultPreviewRow,
                    spritesheetURL: installed.spritesheetURL ?? repoRoot?.appendingPathComponent(entry.spritesheetFile),
                    stillPreviewURL: installed.stillPreviewURL ?? repoRoot?.appendingPathComponent(entry.folder).appendingPathComponent("base.webp"),
                    repoFolderURL: repoRoot?.appendingPathComponent(entry.folder),
                    installedFolderURL: installed.installedFolderURL,
                    isInstalled: true,
                    isActive: installed.normalizedSlug == activeSlug?.lowercased()
                )
            }
            
            let repoFolderURL = repoRoot?.appendingPathComponent(entry.folder)
            let previewFallback = repoFolderURL.flatMap { firstExistingURL(at: $0, candidates: ["base.png", "base.webp", entry.spritesheetPath]) }
            
            return PetRecord(
                slug: entry.slug,
                normalizedSlug: entry.slug.lowercased(),
                displayName: entry.displayName,
                description: entry.description,
                source: .codpet,
                atlas: entry.atlas,
                previewRows: entry.previewRows,
                defaultPreviewRowKey: entry.defaultPreviewRow,
                spritesheetURL: repoRoot?.appendingPathComponent(entry.spritesheetFile),
                stillPreviewURL: previewFallback,
                repoFolderURL: repoFolderURL,
                installedFolderURL: nil,
                isInstalled: false,
                isActive: false
            )
        }
    }
    
    func installFromRepository(slug: String, repoRoot: URL?) throws {
        guard let repoRoot else {
            throw PetRepositoryError.repositoryNotFound
        }
        
        let source = repoRoot.appendingPathComponent("pets").appendingPathComponent(slug)
        let destination = petsDir.appendingPathComponent(slug)
        
        guard fileManager.fileExists(atPath: source.path) else {
            throw PetRepositoryError.petSourceMissing
        }
        
        ensurePetsDirectory()
        if fileManager.fileExists(atPath: destination.path) {
            throw PetRepositoryError.petAlreadyInstalled
        }
        
        try fileManager.copyItem(at: source, to: destination)
    }
    
    func uninstall(slug: String) throws {
        let target = petsDir.appendingPathComponent(slug)
        guard fileManager.fileExists(atPath: target.path) else { return }
        ensureTrashDirectory()
        let trashedTarget = trashDir.appendingPathComponent(slug)
        if fileManager.fileExists(atPath: trashedTarget.path) {
            try fileManager.removeItem(at: trashedTarget)
        }
        try fileManager.moveItem(at: target, to: trashedTarget)
    }
    
    func importLocalPet(from source: URL, repoRoot: URL?) throws {
        let petJSONURL = source.appendingPathComponent("pet.json")
        guard fileManager.fileExists(atPath: petJSONURL.path) else {
            throw PetRepositoryError.invalidPetFolder
        }
        
        ensurePetsDirectory()
        let slug = source.lastPathComponent
        let destination = petsDir.appendingPathComponent(slug)
        
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }
    
    func restoreFromTrash(slug: String) throws {
        let source = trashDir.appendingPathComponent(slug)
        let destination = petsDir.appendingPathComponent(slug)
        guard fileManager.fileExists(atPath: source.path) else { return }
        
        ensurePetsDirectory()
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
    }
    
    func permanentlyDeleteFromTrash(slug: String) throws {
        let target = trashDir.appendingPathComponent(slug)
        guard fileManager.fileExists(atPath: target.path) else { return }
        try fileManager.removeItem(at: target)
    }
    
    func reveal(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func ensurePetsDirectory() {
        if !fileManager.fileExists(atPath: petsDir.path) {
            try? fileManager.createDirectory(
                at: petsDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func ensureTrashDirectory() {
        if !fileManager.fileExists(atPath: trashDir.path) {
            try? fileManager.createDirectory(
                at: trashDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
    
    private func looksLikeRepositoryRoot(_ url: URL) -> Bool {
        fileManager.fileExists(atPath: url.appendingPathComponent("index.html").path) &&
        fileManager.fileExists(atPath: url.appendingPathComponent("index.json").path) &&
        fileManager.fileExists(atPath: url.appendingPathComponent("pets").path)
    }
    
    private func ancestors(of url: URL) -> [URL] {
        var current = url
        var result: [URL] = []
        for _ in 0..<8 {
            current.deleteLastPathComponent()
            result.append(current)
        }
        return result
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
        catalogBySlug: [String: PetCatalogEntry],
        activeSlug: String?,
        isInstalled: Bool
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
            isInstalled: isInstalled,
            isActive: normalizedSlug == activeSlug?.lowercased()
        )
    }
}

enum PetRepositoryError: LocalizedError {
    case repositoryNotFound
    case petSourceMissing
    case petAlreadyInstalled
    case invalidPetFolder
    
    var errorDescription: String? {
        switch self {
        case .repositoryNotFound:
            return "Couldn't find the cod.pet repository folder."
        case .petSourceMissing:
            return "This pet is missing its source files in the repository."
        case .petAlreadyInstalled:
            return "This pet is already installed."
        case .invalidPetFolder:
            return "The selected folder doesn't contain a pet.json file."
        }
    }
}
