import AppKit
import ImageIO
import SwiftUI

final class SpritePreviewLoader: ObservableObject {
    @Published private(set) var frames: [CGImage] = []
    @Published private(set) var fallbackImage: NSImage?
    
    private let pet: PetRecord
    
    init(pet: PetRecord) {
        self.pet = pet
        load()
    }
    
    private func load() {
        if let frames = SpriteFrameCache.shared.frames(for: pet), !frames.isEmpty {
            self.frames = frames
            return
        }
        
        if let url = pet.stillPreviewURL {
            self.fallbackImage = NSImage(contentsOf: url)
        }
    }
}

private final class SpriteFrameCache {
    static let shared = SpriteFrameCache()
    
    private var cachedFrames: [String: [CGImage]] = [:]
    private let lock = NSLock()
    
    func frames(for pet: PetRecord) -> [CGImage]? {
        guard let spritesheetURL = pet.spritesheetURL else {
            return nil
        }
        
        let row = pet.defaultPreviewRow
        let cacheKey = "\(spritesheetURL.path)#\(row.rowIndex)#\(row.frames)#\(pet.atlas.frameWidth)x\(pet.atlas.frameHeight)"
        
        lock.lock()
        if let cached = cachedFrames[cacheKey] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        guard let source = CGImageSourceCreateWithURL(spritesheetURL as CFURL, nil),
              let sheet = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        
        let actualHeight = sheet.height
        let frameWidth = pet.atlas.frameWidth
        let frameHeight = pet.atlas.frameHeight
        let rowOriginY = max(0, actualHeight - ((row.rowIndex + 1) * frameHeight))
        let frameCount = min(row.frames, pet.atlas.columns)
        
        var result: [CGImage] = []
        for frameIndex in 0..<frameCount {
            let rect = CGRect(
                x: frameIndex * frameWidth,
                y: rowOriginY,
                width: frameWidth,
                height: frameHeight
            ).integral
            if let cropped = sheet.cropping(to: rect) {
                result.append(cropped)
            }
        }
        
        lock.lock()
        cachedFrames[cacheKey] = result
        lock.unlock()
        return result
    }
}
