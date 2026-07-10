import AppKit
import QuartzCore
import SwiftUI

private enum DockMetrics {
    static let stripCornerRadius: CGFloat = 16
    static let itemWidth: CGFloat = 36
    static let itemHeight: CGFloat = 39
    static let itemSpacing: CGFloat = 8
    static let horizontalInset: CGFloat = 4
    static let contentVerticalInset: CGFloat = 8
    static let itemRenderScale: CGFloat = 0.78
    static let visibleItemCount: CGFloat = 6
    static let windowPadding: CGFloat = 16

    static func stripSize(for mode: DockLayoutMode) -> CGSize {
        switch mode {
        case .vertical:
            CGSize(
                width: 44,
                height:
                    (contentVerticalInset * 2) +
                    (visibleItemCount * itemHeight) +
                    ((visibleItemCount - 1) * itemSpacing)
            )
        case .horizontal:
            CGSize(
                width:
                    (horizontalInset * 2) +
                    (visibleItemCount * itemWidth) +
                    ((visibleItemCount - 1) * itemSpacing),
                height: 47
            )
        }
    }

    static func windowSize(for mode: DockLayoutMode) -> CGSize {
        let stripSize = stripSize(for: mode)
        switch mode {
        case .vertical:
            return CGSize(
                width: stripSize.width + 32,
                height: stripSize.height + windowPadding
            )
        case .horizontal:
            return CGSize(
                width: stripSize.width + windowPadding,
                height: stripSize.height + 31
            )
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: PetLibraryStore

    @State private var selectedSlug: String?

    private var windowSize: CGSize {
        DockMetrics.windowSize(for: store.dockLayoutMode)
    }

    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()

            PetDockStrip(
                pets: store.filteredInstalledPets,
                layoutMode: store.dockLayoutMode,
                selectedSlug: $selectedSlug,
                onApply: { pet in
                    store.apply(pet)
                }
            )
        }
        .frame(
            width: windowSize.width,
            height: windowSize.height
        )
        .onAppear {
            debugStartup("RootView.onAppear")
            reseedSelectionIfNeeded()
        }
        .onChange(of: store.installedPets) { _, _ in
            reseedSelectionIfNeeded()
        }
    }

    private func reseedSelectionIfNeeded() {
        let availableSlugs = Set(store.filteredInstalledPets.map(\.normalizedSlug))
        if let selectedSlug, availableSlugs.contains(selectedSlug.lowercased()) {
            return
        }
        selectedSlug = store.currentPet?.normalizedSlug ?? store.filteredInstalledPets.first?.normalizedSlug
    }
}

private struct PetDockStrip: View {
    let pets: [PetRecord]
    let layoutMode: DockLayoutMode
    @Binding var selectedSlug: String?
    let onApply: (PetRecord) -> Void
    @State private var suppressHoverEffects = false

    private var stripShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: DockMetrics.stripCornerRadius,
            style: .continuous
        )
    }

    private var stripSize: CGSize {
        DockMetrics.stripSize(for: layoutMode)
    }

    var body: some View {
        stripBody
    }

    private var stripBody: some View {
        ZStack {
            PetDockChrome(layoutMode: layoutMode)
                .allowsHitTesting(false)

            HiddenMomentumScrollView(
                axis: layoutMode == .vertical ? .vertical : .horizontal,
                suppressHoverEffects: $suppressHoverEffects
            ) {
                Group {
                    if layoutMode == .vertical {
                        LazyVStack(spacing: DockMetrics.itemSpacing) {
                            petItems
                        }
                        .padding(.horizontal, DockMetrics.horizontalInset)
                        .padding(.vertical, DockMetrics.contentVerticalInset)
                    } else {
                        LazyHStack(spacing: DockMetrics.itemSpacing) {
                            petItems
                        }
                        .padding(.horizontal, DockMetrics.contentVerticalInset)
                        .padding(.vertical, DockMetrics.horizontalInset)
                    }
                }
            }
        }
        .frame(width: stripSize.width, height: stripSize.height)
        .clipShape(stripShape)
    }

    @ViewBuilder
    private var petItems: some View {
        ForEach(pets) { pet in
            PetDockItem(
                pet: pet,
                isSelected: selectedSlug?.lowercased() == pet.normalizedSlug.lowercased(),
                suppressHoverEffects: suppressHoverEffects,
                onSelect: {
                    selectedSlug = pet.normalizedSlug
                },
                onApply: {
                    selectedSlug = pet.normalizedSlug
                    onApply(pet)
                }
            )
        }
    }
}

private struct PetDockChrome: View {
    let layoutMode: DockLayoutMode

    private var stripShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: DockMetrics.stripCornerRadius,
            style: .continuous
        )
    }

    private var darkGlassFill: LinearGradient {
        switch layoutMode {
        case .vertical:
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.995), location: 0.0),
                    .init(color: Color(red: 0.008, green: 0.008, blue: 0.012).opacity(0.985), location: 0.22),
                    .init(color: Color(red: 0.02, green: 0.02, blue: 0.024).opacity(0.94), location: 0.48),
                    .init(color: Color(red: 0.055, green: 0.055, blue: 0.06).opacity(0.72), location: 0.78),
                    .init(color: Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.52), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .horizontal:
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.88), location: 0.0),
                    .init(color: Color(red: 0.04, green: 0.04, blue: 0.05).opacity(0.80), location: 0.20),
                    .init(color: Color(red: 0.10, green: 0.10, blue: 0.115).opacity(0.72), location: 0.54),
                    .init(color: Color(red: 0.16, green: 0.16, blue: 0.175).opacity(0.60), location: 0.82),
                    .init(color: Color(red: 0.22, green: 0.22, blue: 0.235).opacity(0.48), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var innerTone: LinearGradient {
        switch layoutMode {
        case .vertical:
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.03), location: 0.0),
                    .init(color: .white.opacity(0.008), location: 0.10),
                    .init(color: .clear, location: 0.28),
                    .init(color: Color(red: 1.0, green: 0.95, blue: 0.86).opacity(0.03), location: 0.84),
                    .init(color: .black.opacity(0.06), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .horizontal:
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.18), location: 0.0),
                    .init(color: .white.opacity(0.08), location: 0.10),
                    .init(color: .white.opacity(0.02), location: 0.34),
                    .init(color: Color(red: 1.0, green: 0.96, blue: 0.90).opacity(0.032), location: 0.76),
                    .init(color: .black.opacity(0.04), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var topCoreFill: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.black.opacity(1.0), location: 0.0),
                .init(color: Color.black.opacity(0.985), location: 0.56),
                .init(color: Color.black.opacity(0.42), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topCoreHeightFactor: CGFloat {
        switch layoutMode {
        case .vertical:
            0.64
        case .horizontal:
            0.0
        }
    }

    private var topCoreOffsetFactor: CGFloat {
        switch layoutMode {
        case .vertical:
            -0.22
        case .horizontal:
            0.0
        }
    }

    private var glossStroke: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.68), location: 0.0),
                .init(color: .white.opacity(0.12), location: 0.16),
                .init(color: .white.opacity(0.02), location: 0.52),
                .init(color: Color(red: 1.0, green: 0.95, blue: 0.84).opacity(0.24), location: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topGlossFill: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.16), location: 0.0),
                .init(color: .white.opacity(0.045), location: 0.16),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var sideRimGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.18), location: 0.0),
                .init(color: .white.opacity(0.05), location: 0.12),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var horizontalShellFill: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.black.opacity(0.34), location: 0.0),
                .init(color: Color.black.opacity(0.18), location: 0.26),
                .init(color: Color.black.opacity(0.08), location: 0.50),
                .init(color: Color.black.opacity(0.18), location: 0.74),
                .init(color: Color.black.opacity(0.34), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        Group {
            if layoutMode == .horizontal {
                horizontalChrome
            } else {
                verticalChrome
            }
        }
    }

    private var horizontalChrome: some View {
        ZStack {
            stripShape
                .fill(Color(red: 0.02, green: 0.02, blue: 0.025).opacity(0.995))

            stripShape
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.018),
                            .white.opacity(0.004),
                            .black.opacity(0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            PulseInnerBeamAura()
                .clipShape(stripShape)
                .allowsHitTesting(false)

            stripShape
                .inset(by: 0.55)
                .stroke(Color.white.opacity(0.17), lineWidth: 0.95)
                .blur(radius: 0.14)
        }
        .allowsHitTesting(false)
        .clipShape(stripShape)
        .compositingGroup()
        .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 10)
        .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
    }

    private var verticalChrome: some View {
        ZStack {
            stripShape
                .fill(Color(red: 0.02, green: 0.02, blue: 0.025).opacity(0.995))

            stripShape
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.018),
                            .white.opacity(0.004),
                            .black.opacity(0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            PulseInnerBeamAura(layoutMode: .vertical)
                .clipShape(stripShape)
                .allowsHitTesting(false)

            stripShape
                .inset(by: 0.55)
                .stroke(Color.white.opacity(0.17), lineWidth: 0.95)
                .blur(radius: 0.14)
        }
        .allowsHitTesting(false)
        .clipShape(stripShape)
        .compositingGroup()
        .shadow(color: .black.opacity(0.22), radius: 16, x: 0, y: 10)
        .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 2)
    }
}

private struct PulseInnerBeamAura: View {
    let layoutMode: DockLayoutMode

    private let shape = RoundedRectangle(
        cornerRadius: DockMetrics.stripCornerRadius,
        style: .continuous
    )

    private struct Spot {
        let color: Color
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let strength: CGFloat
        let travelX: CGFloat
        let travelY: CGFloat
        let secondaryX: CGFloat
        let secondaryY: CGFloat
        let speed: Double
        let phase: Double
    }

    init(layoutMode: DockLayoutMode = .horizontal) {
        self.layoutMode = layoutMode
    }

    private var spots: [Spot] {
        switch layoutMode {
        case .horizontal:
            [
                Spot(color: Color(red: 0.22, green: 0.92, blue: 0.47), x: 0.05, y: 0.50, width: 94, height: 210, strength: 1.25, travelX: 28, travelY: 16, secondaryX: 12, secondaryY: 28, speed: 1.20, phase: 0.20),
                Spot(color: Color(red: 0.14, green: 0.64, blue: 1.0), x: 0.16, y: 0.17, width: 138, height: 68, strength: 0.95, travelX: 46, travelY: 18, secondaryX: 20, secondaryY: 12, speed: 1.42, phase: 1.10),
                Spot(color: Color(red: 0.95, green: 0.16, blue: 0.68), x: 0.50, y: 0.12, width: 260, height: 62, strength: 1.15, travelX: 56, travelY: 16, secondaryX: 18, secondaryY: 8, speed: 1.48, phase: 2.40),
                Spot(color: Color(red: 0.07, green: 0.84, blue: 0.91), x: 0.77, y: 0.17, width: 152, height: 60, strength: 0.92, travelX: 42, travelY: 16, secondaryX: 18, secondaryY: 9, speed: 1.30, phase: 3.50),
                Spot(color: Color(red: 0.74, green: 0.42, blue: 1.0), x: 0.95, y: 0.50, width: 94, height: 210, strength: 1.25, travelX: 26, travelY: 16, secondaryX: 12, secondaryY: 26, speed: 1.26, phase: 4.30),
                Spot(color: Color(red: 0.10, green: 0.52, blue: 1.0), x: 0.58, y: 0.88, width: 206, height: 52, strength: 0.82, travelX: 52, travelY: 16, secondaryX: 16, secondaryY: 10, speed: 1.56, phase: 5.10),
                Spot(color: Color(red: 0.99, green: 0.67, blue: 0.22), x: 0.34, y: 0.86, width: 214, height: 58, strength: 0.86, travelX: 46, travelY: 18, secondaryX: 18, secondaryY: 10, speed: 1.38, phase: 6.00),
                Spot(color: Color(red: 0.32, green: 0.92, blue: 0.40), x: 0.50, y: 0.56, width: 154, height: 58, strength: 0.26, travelX: 32, travelY: 14, secondaryX: 14, secondaryY: 10, speed: 1.12, phase: 2.90),
                Spot(color: Color(red: 0.72, green: 0.24, blue: 1.0), x: 0.88, y: 0.18, width: 116, height: 54, strength: 0.96, travelX: 36, travelY: 16, secondaryX: 13, secondaryY: 8, speed: 1.62, phase: 1.90),
            ]
        case .vertical:
            [
                Spot(color: Color(red: 0.95, green: 0.16, blue: 0.68), x: 0.50, y: 0.06, width: 58, height: 118, strength: 1.12, travelX: 10, travelY: 22, secondaryX: 8, secondaryY: 14, speed: 1.42, phase: 0.50),
                Spot(color: Color(red: 0.14, green: 0.64, blue: 1.0), x: 0.80, y: 0.18, width: 54, height: 126, strength: 0.96, travelX: 10, travelY: 30, secondaryX: 7, secondaryY: 16, speed: 1.58, phase: 1.20),
                Spot(color: Color(red: 0.07, green: 0.84, blue: 0.91), x: 0.82, y: 0.45, width: 48, height: 156, strength: 0.90, travelX: 9, travelY: 36, secondaryX: 6, secondaryY: 18, speed: 1.34, phase: 2.30),
                Spot(color: Color(red: 0.22, green: 0.92, blue: 0.47), x: 0.79, y: 0.82, width: 52, height: 126, strength: 1.10, travelX: 8, travelY: 28, secondaryX: 6, secondaryY: 14, speed: 1.28, phase: 3.10),
                Spot(color: Color(red: 0.99, green: 0.67, blue: 0.22), x: 0.50, y: 0.95, width: 66, height: 118, strength: 0.90, travelX: 10, travelY: 20, secondaryX: 8, secondaryY: 12, speed: 1.46, phase: 4.00),
                Spot(color: Color(red: 0.74, green: 0.42, blue: 1.0), x: 0.18, y: 0.82, width: 50, height: 130, strength: 1.06, travelX: 8, travelY: 30, secondaryX: 6, secondaryY: 16, speed: 1.50, phase: 4.80),
                Spot(color: Color(red: 0.10, green: 0.52, blue: 1.0), x: 0.16, y: 0.42, width: 46, height: 160, strength: 0.84, travelX: 8, travelY: 38, secondaryX: 6, secondaryY: 18, speed: 1.62, phase: 5.60),
                Spot(color: Color(red: 0.32, green: 0.92, blue: 0.40), x: 0.49, y: 0.52, width: 40, height: 116, strength: 0.22, travelX: 6, travelY: 20, secondaryX: 4, secondaryY: 10, speed: 1.18, phase: 2.60),
            ]
        }
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let hue = Angle.degrees((time / 7.2).truncatingRemainder(dividingBy: 1) * 360)
                let breathe = 0.88 + (0.12 * ((1 - cos(.pi * 2 * (time / 4.2))) / 2))

                ZStack {
                    pulseField(
                        in: proxy.size,
                        time: time,
                        widthScale: 1.45,
                        heightScale: 1.55,
                        alphaScale: 0.12
                    )
                    .hueRotation(hue)
                    .blur(radius: 20)
                    .opacity(0.28 * breathe)

                    pulseField(
                        in: proxy.size,
                        time: time,
                        widthScale: 1.08,
                        heightScale: 1.12,
                        alphaScale: 0.50
                    )
                    .hueRotation(hue)
                    .blur(radius: 9)
                    .opacity(0.96 * breathe)
                    .mask(
                        shape
                            .inset(by: 2.2)
                            .stroke(lineWidth: 24)
                            .blur(radius: 8)
                    )

                    pulseField(
                        in: proxy.size,
                        time: time,
                        widthScale: 1.0,
                        heightScale: 1.0,
                        alphaScale: 0.95
                    )
                    .hueRotation(hue)
                    .blur(radius: 0.75)
                    .opacity(1.06 * breathe)
                    .mask(
                        shape
                            .inset(by: 0.85)
                            .stroke(lineWidth: 1.45)
                    )
                }
                .clipShape(shape)
                .blendMode(.screen)
                .compositingGroup()
                .drawingGroup(opaque: false, colorMode: .linear)
            }
        }
    }

    @ViewBuilder
    private func pulseField(
        in size: CGSize,
        time: TimeInterval,
        widthScale: CGFloat,
        heightScale: CGFloat,
        alphaScale: CGFloat
    ) -> some View {
        ZStack {
            ForEach(Array(spots.enumerated()), id: \.offset) { _, spot in
                pulseSpot(
                    spot,
                    in: size,
                    time: time,
                    widthScale: widthScale,
                    heightScale: heightScale,
                    alphaScale: alphaScale
                )
            }
        }
    }

    private func pulseSpot(
        _ spot: Spot,
        in size: CGSize,
        time: TimeInterval,
        widthScale: CGFloat,
        heightScale: CGFloat,
        alphaScale: CGFloat
    ) -> some View {
        let flow = flowPosition(for: spot, in: size, time: time)
        let scale = 0.92 + (0.16 * ((1 - cos(.pi * 2 * ((time * spot.speed * 0.22) + spot.phase))) / 2))
        let width = spot.width * widthScale * scale
        let height = spot.height * heightScale * scale
        let opacity = spot.strength * alphaScale * (0.76 + (0.24 * ((1 - cos(.pi * 2 * ((time * spot.speed * 0.18) + spot.phase))) / 2)))

        return Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        spot.color.opacity(opacity),
                        spot.color.opacity(opacity * 0.18),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(width, height) * 0.5
                )
            )
            .frame(width: width, height: height)
            .position(flow)
    }

    private func flowPosition(for spot: Spot, in size: CGSize, time: TimeInterval) -> CGPoint {
        let primaryPhase = (time * spot.speed) + spot.phase
        let secondaryPhase = (time * spot.speed * 0.58) + spot.phase * 1.37
        let x = (size.width * spot.x)
            + (sin(primaryPhase) * spot.travelX)
            + (cos(secondaryPhase) * spot.secondaryX)
        let y = (size.height * spot.y)
            + (cos(primaryPhase * 0.92) * spot.travelY)
            + (sin(secondaryPhase * 1.11) * spot.secondaryY)

        return CGPoint(
            x: min(max(x, -32), size.width + 32),
            y: min(max(y, -32), size.height + 32)
        )
    }
}

private struct BorderBeamAura: View {
    let layoutMode: DockLayoutMode

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let size = proxy.size

                ZStack {
                    movingBeam(
                        size: size,
                        phase: normalizedPhase(t * 0.20),
                        color: Color(red: 1.0, green: 0.62, blue: 0.18),
                        longSide: layoutMode == .horizontal ? 88 : 54,
                        shortSide: layoutMode == .horizontal ? 10 : 34,
                        blur: layoutMode == .horizontal ? 4.2 : 6,
                        opacity: layoutMode == .horizontal ? 0.48 : 0.82
                    )

                    movingBeam(
                        size: size,
                        phase: normalizedPhase(t * 0.16 + 0.33),
                        color: Color(red: 0.68, green: 0.36, blue: 1.0),
                        longSide: layoutMode == .horizontal ? 76 : 48,
                        shortSide: layoutMode == .horizontal ? 9 : 32,
                        blur: layoutMode == .horizontal ? 4.0 : 6,
                        opacity: layoutMode == .horizontal ? 0.42 : 0.68
                    )

                    movingBeam(
                        size: size,
                        phase: normalizedPhase(t * 0.18 + 0.66),
                        color: Color(red: 0.20, green: 0.90, blue: 0.42),
                        longSide: layoutMode == .horizontal ? 68 : 42,
                        shortSide: layoutMode == .horizontal ? 8 : 28,
                        blur: layoutMode == .horizontal ? 3.8 : 5,
                        opacity: layoutMode == .horizontal ? 0.36 : 0.58
                    )
                }
                .blendMode(.screen)
                .compositingGroup()
            }
        }
    }

    private func movingBeam(
        size: CGSize,
        phase: CGFloat,
        color: Color,
        longSide: CGFloat,
        shortSide: CGFloat,
        blur: CGFloat,
        opacity: CGFloat
    ) -> some View {
        let point = perimeterPoint(in: size, phase: phase)
        let width = layoutMode == .horizontal ? longSide : shortSide
        let height = layoutMode == .horizontal ? shortSide : longSide

        return Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        color.opacity(opacity * 0.8),
                        color.opacity(opacity),
                        color.opacity(opacity * 0.72),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .blur(radius: blur)
            .rotationEffect(beamAngle(for: point.angle))
            .position(x: point.position.x, y: point.position.y)
    }

    private func normalizedPhase(_ value: Double) -> CGFloat {
        CGFloat(value - floor(value))
    }

    private func beamAngle(for radians: CGFloat) -> Angle {
        Angle(radians: Double(radians))
    }

    private func perimeterPoint(in size: CGSize, phase: CGFloat) -> (position: CGPoint, angle: CGFloat) {
        let inset: CGFloat = layoutMode == .horizontal ? 4.25 : 3.4
        let width = max(size.width - inset * 2, 1)
        let height = max(size.height - inset * 2, 1)
        let radius = max(DockMetrics.stripCornerRadius - inset, 2)
        let horizontal = max(width - radius * 2, 0.1)
        let vertical = max(height - radius * 2, 0.1)
        let arc = (.pi * radius) / 2
        let total = (horizontal * 2) + (vertical * 2) + (arc * 4)

        var distance = total * phase
        let left = inset
        let right = inset + width
        let top = inset
        let bottom = inset + height

        if distance <= horizontal {
            return (CGPoint(x: left + radius + distance, y: top), 0)
        }
        distance -= horizontal

        if distance <= arc {
            let theta = (-.pi / 2) + (distance / arc) * (.pi / 2)
            return (
                CGPoint(
                    x: right - radius + cos(theta) * radius,
                    y: top + radius + sin(theta) * radius
                ),
                theta + (.pi / 2)
            )
        }
        distance -= arc

        if distance <= vertical {
            return (CGPoint(x: right, y: top + radius + distance), .pi / 2)
        }
        distance -= vertical

        if distance <= arc {
            let theta = (distance / arc) * (.pi / 2)
            return (
                CGPoint(
                    x: right - radius + cos(theta) * radius,
                    y: bottom - radius + sin(theta) * radius
                ),
                theta + (.pi / 2)
            )
        }
        distance -= arc

        if distance <= horizontal {
            return (CGPoint(x: right - radius - distance, y: bottom), .pi)
        }
        distance -= horizontal

        if distance <= arc {
            let theta = (.pi / 2) + (distance / arc) * (.pi / 2)
            return (
                CGPoint(
                    x: left + radius + cos(theta) * radius,
                    y: bottom - radius + sin(theta) * radius
                ),
                theta + (.pi / 2)
            )
        }
        distance -= arc

        if distance <= vertical {
            return (CGPoint(x: left, y: bottom - radius - distance), -.pi / 2)
        }

        let theta = .pi + ((distance - vertical) / arc) * (.pi / 2)
        return (
            CGPoint(
                x: left + radius + cos(theta) * radius,
                y: top + radius + sin(theta) * radius
            ),
            theta + (.pi / 2)
        )
    }
}

private struct BorderBeamRingMask: View {
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let outerRadius = DockMetrics.stripCornerRadius
            let innerRadius = max(outerRadius - lineWidth, 1)

            ZStack {
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .fill(.white)

                RoundedRectangle(cornerRadius: innerRadius, style: .continuous)
                    .inset(by: lineWidth)
                    .fill(.black)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        }
    }
}

private enum DockScrollAxis {
    case vertical
    case horizontal
}

private struct HiddenMomentumScrollView<Content: View>: NSViewRepresentable {
    let axis: DockScrollAxis
    @Binding var suppressHoverEffects: Bool
    let content: Content

    init(
        axis: DockScrollAxis,
        suppressHoverEffects: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        _suppressHoverEffects = suppressHoverEffects
        self.content = content()
    }

    func makeNSView(context: Context) -> MomentumScrollView<Content> {
        let view = MomentumScrollView(axis: axis, rootView: content)
        view.onWheelInteractionChanged = { isActive in
            DispatchQueue.main.async {
                suppressHoverEffects = isActive
            }
        }
        return view
    }

    func updateNSView(_ nsView: MomentumScrollView<Content>, context: Context) {
        nsView.axis = axis
        nsView.onWheelInteractionChanged = { isActive in
            DispatchQueue.main.async {
                suppressHoverEffects = isActive
            }
        }
        nsView.update(rootView: content)
    }
}

private protocol MomentumEventHandling: AnyObject {
    func handleRightMouseDown(_ event: NSEvent)
    func handleRightMouseDragged(_ event: NSEvent)
    func handleRightMouseUp(_ event: NSEvent)
    func handleScrollWheel(_ event: NSEvent)
}

private final class MomentumHostingView<Content: View>: NSHostingView<Content> {
    weak var eventSink: MomentumEventHandling?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) ?? self
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        nil
    }

    override func rightMouseDown(with event: NSEvent) {
        eventSink?.handleRightMouseDown(event)
    }

    override func rightMouseDragged(with event: NSEvent) {
        eventSink?.handleRightMouseDragged(event)
    }

    override func rightMouseUp(with event: NSEvent) {
        eventSink?.handleRightMouseUp(event)
    }

    override func scrollWheel(with event: NSEvent) {
        eventSink?.handleScrollWheel(event)
    }
}

private final class MomentumScrollView<Content: View>: NSScrollView, MomentumEventHandling {
    private let hostingView: MomentumHostingView<Content>
    var axis: DockScrollAxis
    var onWheelInteractionChanged: ((Bool) -> Void)?
    private var didSetInitialOffset = false
    private var inertiaTimer: Timer?
    private var velocity: CGFloat = 0
    private var lastScrollDirection: CGFloat = 0
    private var lastEventTime: TimeInterval = 0
    private var lastInertiaStepTime: TimeInterval = 0
    private var lastPanTranslation: CGFloat = 0
    private var lastPanSampleTime: TimeInterval = 0
    private var rightDragStartWindowOrigin: NSPoint = .zero
    private var rightDragStartScreenLocation: NSPoint = .zero
    private var cursorTrackingArea: NSTrackingArea?
    private var isPanningPets = false
    private var isDraggingWindow = false
    private var isWheelInteracting = false

    init(axis: DockScrollAxis, rootView: Content) {
        self.axis = axis
        hostingView = MomentumHostingView(rootView: rootView)
        super.init(frame: .zero)

        drawsBackground = false
        borderType = .noBorder
        hasVerticalScroller = false
        hasHorizontalScroller = false
        autohidesScrollers = true
        scrollerStyle = .overlay
        verticalScrollElasticity = .none
        horizontalScrollElasticity = .none
        contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        automaticallyAdjustsContentInsets = false

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.setFrameSize(NSSize(width: 44, height: 286))
        hostingView.eventSink = self
        documentView = hostingView

        wantsLayer = true
        layer?.cornerRadius = DockMetrics.stripCornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = DockMetrics.stripCornerRadius
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.masksToBounds = true

        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.buttonMask = 0x1
        contentView.addGestureRecognizer(panGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        onWheelInteractionChanged?(false)
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    func update(rootView: Content) {
        hostingView.rootView = rootView
        needsLayout = true
        layoutSubtreeIfNeeded()
    }

    override func layout() {
        super.layout()
        syncHostingLayout()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let cursorTrackingArea {
            removeTrackingArea(cursorTrackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        cursorTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        updateCursorAppearance()
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }

    override func cursorUpdate(with event: NSEvent) {
        super.cursorUpdate(with: event)
        updateCursorAppearance()
    }

    override func scrollWheel(with event: NSEvent) {
        handleScrollWheel(event)
    }

    func handleScrollWheel(_ event: NSEvent) {
        activateWindowIfNeeded()
        syncHostingLayout()
        let maxOffset = currentMaxOffset()
        guard maxOffset > 0 else {
            setWheelInteraction(false)
            return
        }

        let rawDelta = dominantScrollDelta(for: event)
        let deviceDelta = event.hasPreciseScrollingDeltas
            ? rawDelta
            : (rawDelta * 10)
        let directionMultiplier: CGFloat = event.isDirectionInvertedFromDevice ? 1 : -1
        let delta = CGFloat(deviceDelta) * directionMultiplier

        guard abs(delta) > 0.1 else { return }
        setWheelInteraction(true)

        let lowerBound = safeLowerOffset(maxOffset: maxOffset)
        let upperBound = safeUpperOffset(maxOffset: maxOffset)
        let directStep = clamp(delta * 0.208, lower: -10.4, upper: 10.4)
        let immediateOffset = clamp(currentScrollOffset() + directStep, lower: lowerBound, upper: upperBound)

        setScrollOffset(immediateOffset)

        let direction: CGFloat = delta == 0 ? 0 : (delta.sign == .minus ? -1 : 1)
        let now = event.timestamp
        let timeGap = lastEventTime == 0 ? 0 : now - lastEventTime
        lastEventTime = now

        if direction != 0, direction != lastScrollDirection {
            velocity *= 0.28
        }

        let responsiveness: CGFloat = event.hasPreciseScrollingDeltas ? 2.34 : 3.38
        let burstBoost: CGFloat = timeGap > 0 && timeGap < 0.08 ? 1.08 : 1.0
        let injectedVelocity = clamp(delta * responsiveness * burstBoost * 60, lower: -936, upper: 936)
        velocity = clamp((velocity * 0.55) + injectedVelocity, lower: -1404, upper: 1404)
        lastScrollDirection = direction

        startInertiaIfNeeded()
    }

    override func rightMouseDown(with event: NSEvent) {
        handleRightMouseDown(event)
    }

    func handleRightMouseDown(_ event: NSEvent) {
        activateWindowIfNeeded()
        guard let window else { return }
        stopInertia()
        isDraggingWindow = true
        updateCursorAppearance()
        rightDragStartWindowOrigin = window.frame.origin
        rightDragStartScreenLocation = NSEvent.mouseLocation
    }

    override func rightMouseDragged(with event: NSEvent) {
        handleRightMouseDragged(event)
    }

    func handleRightMouseDragged(_ event: NSEvent) {
        activateWindowIfNeeded()
        guard let window else { return }

        let currentLocation = NSEvent.mouseLocation
        let deltaX = currentLocation.x - rightDragStartScreenLocation.x
        let deltaY = currentLocation.y - rightDragStartScreenLocation.y
        let nextOrigin = NSPoint(
            x: rightDragStartWindowOrigin.x + deltaX,
            y: rightDragStartWindowOrigin.y + deltaY
        )
        window.setFrameOrigin(nextOrigin)
    }

    override func rightMouseUp(with event: NSEvent) {
        handleRightMouseUp(event)
    }

    func handleRightMouseUp(_ event: NSEvent) {
        isDraggingWindow = false
        updateCursorAppearance()
    }

    @objc
    private func handlePan(_ recognizer: NSPanGestureRecognizer) {
        syncHostingLayout()
        let maxOffset = currentMaxOffset()
        guard maxOffset > 0 else { return }

        let lowerBound = safeLowerOffset(maxOffset: maxOffset)
        let upperBound = safeUpperOffset(maxOffset: maxOffset)
        let translation = dominantPanTranslation(for: recognizer.translation(in: contentView))
        let now = CACurrentMediaTime()

        switch recognizer.state {
        case .began:
            stopInertia()
            isPanningPets = true
            updateCursorAppearance()
            lastPanTranslation = translation
            lastPanSampleTime = now

        case .changed:
            let deltaStep = translation - lastPanTranslation
            let deltaTime = max(now - lastPanSampleTime, 1.0 / 240.0)
            lastPanTranslation = translation
            lastPanSampleTime = now

            let nextOffset = clamp(
                currentScrollOffset() - deltaStep,
                lower: lowerBound,
                upper: upperBound
            )

            setScrollOffset(nextOffset)

            let pointsPerSecond = (-deltaStep / deltaTime) * 2.34
            velocity = clamp((velocity * 0.35) + pointsPerSecond, lower: -1560, upper: 1560)

        case .ended:
            isPanningPets = false
            updateCursorAppearance()
            startInertiaIfNeeded()

        case .cancelled, .failed:
            isPanningPets = false
            updateCursorAppearance()
            stopInertia()

        default:
            break
        }
    }

    private func syncHostingLayout() {
        let fitting = hostingView.fittingSize
        let width: CGFloat
        let height: CGFloat
        switch axis {
        case .vertical:
            width = contentView.bounds.width
            height = max(fitting.height, contentView.bounds.height)
        case .horizontal:
            width = max(fitting.width, contentView.bounds.width)
            height = contentView.bounds.height
        }
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)

        let maxOffset = currentMaxOffset()
        let lowerBound = safeLowerOffset(maxOffset: maxOffset)
        let upperBound = safeUpperOffset(maxOffset: maxOffset)

        if !didSetInitialOffset {
            let initialOffset: CGFloat = 0
            setScrollOffset(initialOffset)
            didSetInitialOffset = true
        } else {
            let currentOffset = currentScrollOffset()
            let clamped = clamp(currentOffset, lower: lowerBound, upper: upperBound)
            if abs(clamped - currentOffset) > 0.5 {
                setScrollOffset(clamped)
            }
        }
    }

    private func startInertiaIfNeeded() {
        if inertiaTimer == nil {
            lastInertiaStepTime = CACurrentMediaTime()
            let timer = Timer(timeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
                self?.stepInertia()
            }
            inertiaTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopInertia() {
        inertiaTimer?.invalidate()
        inertiaTimer = nil
        velocity = 0
        lastInertiaStepTime = 0
        setWheelInteraction(false)
    }

    private func stepInertia() {
        syncHostingLayout()
        let maxOffset = currentMaxOffset()
        guard maxOffset > 0 else {
            stopInertia()
            return
        }

        let lowerBound = safeLowerOffset(maxOffset: maxOffset)
        let upperBound = safeUpperOffset(maxOffset: maxOffset)
        let currentOffset = currentScrollOffset()
        let now = CACurrentMediaTime()
        let deltaTime = max(min(now - lastInertiaStepTime, 1.0 / 30.0), 1.0 / 240.0)
        lastInertiaStepTime = now

        let projectedOffset = clamp(
            currentOffset + (velocity * deltaTime),
            lower: lowerBound,
            upper: upperBound
        )

        setScrollOffset(projectedOffset)

        if projectedOffset <= lowerBound + 0.1 || projectedOffset >= upperBound - 0.1 {
            velocity *= pow(0.08, deltaTime * 60)
        } else {
            velocity *= pow(0.87, deltaTime * 60)
        }

        if abs(velocity) < 8 {
            stopInertia()
        }
    }

    private func updateCursorAppearance() {
        if isPanningPets || isDraggingWindow {
            NSCursor.closedHand.set()
        } else {
            NSCursor.openHand.set()
        }
    }

    private func setWheelInteraction(_ isActive: Bool) {
        guard isWheelInteracting != isActive else { return }
        isWheelInteracting = isActive
        onWheelInteractionChanged?(isActive)
    }

    private func dominantScrollDelta(for event: NSEvent) -> CGFloat {
        switch axis {
        case .vertical:
            event.scrollingDeltaY
        case .horizontal:
            abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY)
                ? event.scrollingDeltaX
                : event.scrollingDeltaY
        }
    }

    private func dominantPanTranslation(for point: NSPoint) -> CGFloat {
        switch axis {
        case .vertical:
            point.y
        case .horizontal:
            point.x
        }
    }

    private func currentMaxOffset() -> CGFloat {
        switch axis {
        case .vertical:
            max(hostingView.frame.height - contentView.bounds.height, 0)
        case .horizontal:
            max(hostingView.frame.width - contentView.bounds.width, 0)
        }
    }

    private func currentScrollOffset() -> CGFloat {
        switch axis {
        case .vertical:
            contentView.bounds.origin.y
        case .horizontal:
            contentView.bounds.origin.x
        }
    }

    private func setScrollOffset(_ value: CGFloat) {
        let origin: NSPoint
        switch axis {
        case .vertical:
            origin = NSPoint(x: 0, y: value)
        case .horizontal:
            origin = NSPoint(x: value, y: 0)
        }
        contentView.setBoundsOrigin(origin)
        reflectScrolledClipView(contentView)
    }

    private func activateWindowIfNeeded() {
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }

    private func safeLowerOffset(maxOffset: CGFloat) -> CGFloat {
        0
    }

    private func safeUpperOffset(maxOffset: CGFloat) -> CGFloat {
        maxOffset
    }
}

private struct PetDockItem: View {
    let pet: PetRecord
    let isSelected: Bool
    let suppressHoverEffects: Bool
    let onSelect: () -> Void
    let onApply: () -> Void

    @State private var isHovered = false

    var body: some View {
        ZStack {
            PetPreviewView(pet: pet, animate: isHovered && !suppressHoverEffects)
                .frame(
                    width: DockMetrics.itemWidth * DockMetrics.itemRenderScale,
                    height: DockMetrics.itemHeight * DockMetrics.itemRenderScale
                )
        }
        .frame(width: DockMetrics.itemWidth, height: DockMetrics.itemHeight)
        .scaleEffect((isHovered && !suppressHoverEffects) ? 1.1 : 1.0)
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isHovered && !suppressHoverEffects)
        .contentShape(Rectangle())
        .onHover { hovering in
            if suppressHoverEffects {
                isHovered = false
                return
            }
            isHovered = hovering
        }
        .onChange(of: suppressHoverEffects) { _, newValue in
            if newValue {
                isHovered = false
            }
        }
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            onApply()
        }
        .help(pet.displayName)
    }
}
