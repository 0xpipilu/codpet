import AppKit
import Foundation

enum DockLayoutMode: String, CaseIterable, Identifiable {
    case vertical
    case horizontal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vertical:
            "Vertical"
        case .horizontal:
            "Horizontal"
        }
    }

    var subtitle: String {
        switch self {
        case .vertical:
            "Float as a slim vertical strip on the right side."
        case .horizontal:
            "Pin near the Dynamic Island area and browse pets left to right."
        }
    }
}

final class PetLibraryStore: ObservableObject {
    @Published var selectedSection: LibrarySection = .myPets
    @Published var searchText = ""
    @Published var repoRoot: URL?
    @Published var installedPets: [PetRecord] = []
    @Published var discoverPets: [PetRecord] = []
    @Published var trashedPets: [PetRecord] = []
    @Published var activePetSlug: String?
    @Published var statusMessage: String?
    @Published var applyMode: ApplyMode {
        didSet {
            UserDefaults.standard.set(applyMode.rawValue, forKey: Self.applyModeKey)
        }
    }
    @Published var dockLayoutMode: DockLayoutMode {
        didSet {
            UserDefaults.standard.set(dockLayoutMode.rawValue, forKey: Self.dockLayoutModeKey)
        }
    }
    
    private static let applyModeKey = "codpet.personal.apply.mode"
    private static let dockLayoutModeKey = "codpet.personal.dock.layout.mode"
    private static let repoRootKey = "codpet.personal.repo.root"
    private static let repoBookmarkKey = "codpet.personal.repo.bookmark"
    private let repository = PetRepository()
    private let codexController = CodexController()
    private var repoScopeURL: URL?
    
    deinit {
        stopAccessingRepositoryIfNeeded()
    }
    
    init() {
        debugStartup("PetLibraryStore.init start")
        if let rawValue = UserDefaults.standard.string(forKey: Self.applyModeKey),
           let restored = ApplyMode(rawValue: rawValue) {
            applyMode = restored
        } else {
            applyMode = .immediate
        }
        if let rawValue = UserDefaults.standard.string(forKey: Self.dockLayoutModeKey),
           let restored = DockLayoutMode(rawValue: rawValue) {
            dockLayoutMode = restored
        } else {
            dockLayoutMode = .vertical
        }
        repoRoot = repository.bundledCatalogRoot()
        if repoRoot == nil {
            restoreRepositoryAccess()
        } else {
            UserDefaults.standard.removeObject(forKey: Self.repoRootKey)
            UserDefaults.standard.removeObject(forKey: Self.repoBookmarkKey)
        }
        activePetSlug = codexController.currentActiveSlug()
        debugStartup("PetLibraryStore.init end")
        refreshAll()
        if let activePetSlug {
            Task {
                await codexController.prewarmCompatibilityIfNeeded(for: activePetSlug)
            }
        }
    }

    var currentPet: PetRecord? {
        installedPets.first(where: { $0.isActive })
            ?? discoverPets.first(where: { $0.isActive })
    }
    
    var filteredInstalledPets: [PetRecord] {
        filtered(pets: installedPets)
    }
    
    var filteredDiscoverPets: [PetRecord] {
        filtered(pets: discoverPets)
    }

    func refreshAll() {
        activePetSlug = codexController.currentActiveSlug()
        
        let catalog = repository.loadCatalog(from: repoRoot)
        installedPets = repository.loadInstalledPets(
            repoRoot: repoRoot,
            catalog: catalog,
            activeSlug: activePetSlug
        )
        discoverPets = repository.makeDiscoverPets(
            repoRoot: repoRoot,
            catalog: catalog,
            installedPets: installedPets,
            activeSlug: activePetSlug
        )
        trashedPets = repository.loadTrashedPets(
            repoRoot: repoRoot,
            catalog: catalog
        )
        
        if repoRoot == nil {
            statusMessage = "No pet catalog is available yet."
        } else if currentPet != nil {
            statusMessage = "Synced \(installedPets.count) installed pets."
        } else if installedPets.isEmpty {
            statusMessage = "No pets are installed yet. You can install one from Discover or import a local pet."
        } else {
            statusMessage = "Synced \(installedPets.count) installed pets."
        }
    }
    
    func install(_ pet: PetRecord) {
        do {
            try repository.installFromRepository(slug: pet.slug, repoRoot: repoRoot)
            statusMessage = "\(pet.displayName) was installed."
            refreshAll()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
    
    func uninstall(_ pet: PetRecord) {
        do {
            try repository.uninstall(slug: pet.slug)
            if pet.isActive {
                statusMessage = "\(pet.displayName) was moved to Trash. If Codex still shows it, switch pets once inside Codex."
            } else {
                statusMessage = "\(pet.displayName) was moved to Trash."
            }
            refreshAll()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
    
    func apply(_ pet: PetRecord) {
        Task { @MainActor in
            statusMessage = "Applying \(pet.displayName) to Codex..."
            let feedback = await codexController.apply(slug: pet.slug, mode: applyMode)
            statusMessage = feedback.message
            if feedback.didLiveApply || applyMode == .configOnly {
                refreshAll()
            }
        }
    }
    
    func importLocalPet() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Import"
        panel.message = "Choose a pet folder that contains a pet.json file."
        
        if panel.runModal() == .OK, let sourceURL = panel.url {
            do {
                try repository.importLocalPet(from: sourceURL, repoRoot: repoRoot)
                statusMessage = "Imported \(sourceURL.lastPathComponent)."
                selectedSection = .myPets
                refreshAll()
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }
    
    func revealInstalledFolder(for pet: PetRecord) {
        guard let folderURL = pet.installedFolderURL else { return }
        repository.reveal(folderURL)
    }
    
    func restoreFromTrash(_ pet: PetRecord) {
        do {
            try repository.restoreFromTrash(slug: pet.slug)
            statusMessage = "\(pet.displayName) was restored."
            refreshAll()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
    
    func permanentlyDeleteFromTrash(_ pet: PetRecord) {
        do {
            try repository.permanentlyDeleteFromTrash(slug: pet.slug)
            statusMessage = "\(pet.displayName) was deleted permanently."
            refreshAll()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
    
    func revealRepositoryRoot() {
        guard let repoRoot else { return }
        repository.reveal(repoRoot)
    }
    
    func chooseRepositoryRoot() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Connect"
        panel.message = "Choose the cod.pet repository root. It should contain index.json, index.html, and pets."
        
        if panel.runModal() == .OK, let selectedURL = panel.url {
            guard repository.isRepositoryRoot(selectedURL) else {
                statusMessage = "That folder doesn't look like a cod.pet repository."
                return
            }
            
            stopAccessingRepositoryIfNeeded()
            repoRoot = selectedURL
            UserDefaults.standard.set(selectedURL.path, forKey: Self.repoRootKey)
            saveRepositoryBookmark(for: selectedURL)
            _ = selectedURL.startAccessingSecurityScopedResource()
            repoScopeURL = selectedURL
            statusMessage = "Connected to the cod.pet repository."
            refreshAll()
        }
    }
    
    func revealCodexPetsFolder() {
        repository.reveal(repository.petsDir)
    }
    
    func openCodex() {
        codexController.openCodex()
    }

    func restartCodexOnceForPetRefresh() {
        Task { @MainActor in
            statusMessage = "Restarting Codex once..."
            let result = await codexController.restartCodexOnceForPetRefresh()
            statusMessage = result
        }
    }
    
    private func filtered(pets: [PetRecord]) -> [PetRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return pets }
        
        return pets.filter { pet in
            pet.displayName.localizedCaseInsensitiveContains(query) ||
            pet.slug.localizedCaseInsensitiveContains(query) ||
            pet.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func restoreRepositoryAccess() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: Self.repoBookmarkKey) else {
            UserDefaults.standard.removeObject(forKey: Self.repoRootKey)
            repoRoot = nil
            return
        }
        
        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            UserDefaults.standard.removeObject(forKey: Self.repoBookmarkKey)
            UserDefaults.standard.removeObject(forKey: Self.repoRootKey)
            repoRoot = nil
            return
        }
        
        if isStale {
            saveRepositoryBookmark(for: resolvedURL)
        }
        
        if resolvedURL.startAccessingSecurityScopedResource() {
            repoScopeURL = resolvedURL
        }
        repoRoot = resolvedURL
        UserDefaults.standard.set(resolvedURL.path, forKey: Self.repoRootKey)
    }
    
    private func saveRepositoryBookmark(for url: URL) {
        guard let bookmarkData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return
        }
        UserDefaults.standard.set(bookmarkData, forKey: Self.repoBookmarkKey)
    }
    
    private func stopAccessingRepositoryIfNeeded() {
        repoScopeURL?.stopAccessingSecurityScopedResource()
        repoScopeURL = nil
    }
}
