import SwiftUI
import AppKit
import CoreText

enum AppFont {
    private static let menuCandidates = [
        "ChiKareGo",
        "ChiKareGo2",
        "Chicago",
        "ChicagoFLF",
    ]

    private static let pixelCandidates = [
        "Habbo",
        "dogica",
        "Dogica",
    ]

    static func menu(_ size: CGFloat) -> Font {
        resolvedFont(candidates: menuCandidates, size: size)
            .map(Font.init)
            ?? .system(size: size, weight: .bold, design: .default)
    }

    static func pixel(_ size: CGFloat) -> Font {
        if let bundleFont = bundleFont(named: "Habbo", ext: "ttf", size: size) {
            return Font(bundleFont)
        }
        return resolvedFont(candidates: pixelCandidates, size: size)
            .map(Font.init)
            ?? .system(size: size, weight: .regular, design: .monospaced)
    }

    static func ui(_ size: CGFloat) -> Font {
        menu(size)
    }

    private static func resolvedFont(candidates: [String], size: CGFloat) -> NSFont? {
        for candidate in candidates {
            if let font = NSFont(name: candidate, size: size) {
                return font
            }
        }
        return nil
    }

    private static func bundleFont(named resource: String, ext: String, size: CGFloat) -> NSFont? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Fonts"),
              let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first,
              let postScriptName = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String else {
            return nil
        }
        return NSFont(name: postScriptName, size: size)
    }
}
