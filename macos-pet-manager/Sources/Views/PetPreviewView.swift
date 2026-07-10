import AppKit
import SwiftUI

struct PetPreviewView: View {
    let pet: PetRecord
    let animate: Bool

    private let hoverRowDuration: TimeInterval = 0.35
    private let hoverRefreshRate: TimeInterval = 1.0 / 30.0
    
    @StateObject private var loader: SpritePreviewLoader
    
    init(pet: PetRecord, animate: Bool) {
        self.pet = pet
        self.animate = animate
        _loader = StateObject(wrappedValue: SpritePreviewLoader(pet: pet))
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: hoverRefreshRate, paused: !animate)) { timeline in
            Group {
                if let frame = currentFrame(at: timeline.date) {
                    Image(decorative: frame, scale: 1, orientation: .up)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                } else if let fallback = loader.fallbackImage {
                    Image(nsImage: fallback)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles.tv")
                            .font(.title2)
                        Text("Preview Unavailable")
                            .font(ClassicMacTheme.font(11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func currentFrame(at date: Date) -> CGImage? {
        guard !loader.frames.isEmpty else { return nil }
        guard animate else { return loader.frames.first }
        
        let duration = hoverRowDuration
        let progress = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
        let index = min(Int(progress * Double(loader.frames.count)), max(loader.frames.count - 1, 0))
        return loader.frames[index]
    }
}
