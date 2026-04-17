import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#endif

enum PlatformPasteboard {
    static func copy(_ string: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}

extension PlatformColor {
    var swiftUIColor: Color {
        #if canImport(UIKit)
        Color(uiColor: self)
        #else
        Color(nsColor: self)
        #endif
    }

    static var lumenLabel: PlatformColor {
        #if canImport(UIKit)
        .label
        #else
        .labelColor
        #endif
    }

    static var lumenSecondaryLabel: PlatformColor {
        #if canImport(UIKit)
        .secondaryLabel
        #else
        .secondaryLabelColor
        #endif
    }

    static var lumenTertiaryLabel: PlatformColor {
        #if canImport(UIKit)
        .tertiaryLabel
        #else
        .tertiaryLabelColor
        #endif
    }

    static var lumenQuaternaryLabel: PlatformColor {
        #if canImport(UIKit)
        .quaternaryLabel
        #else
        .quaternaryLabelColor
        #endif
    }

    static var lumenPlaceholderText: PlatformColor {
        #if canImport(UIKit)
        .placeholderText
        #else
        .placeholderTextColor
        #endif
    }

    static var lumenSystemBackground: PlatformColor {
        #if canImport(UIKit)
        .systemBackground
        #else
        .windowBackgroundColor
        #endif
    }

    static var lumenSecondarySystemBackground: PlatformColor {
        #if canImport(UIKit)
        .secondarySystemBackground
        #else
        .underPageBackgroundColor
        #endif
    }

    static var lumenGroupedBackground: PlatformColor {
        #if canImport(UIKit)
        .systemGroupedBackground
        #else
        .windowBackgroundColor
        #endif
    }

    static var lumenSecondaryGroupedBackground: PlatformColor {
        #if canImport(UIKit)
        .secondarySystemGroupedBackground
        #else
        .underPageBackgroundColor
        #endif
    }

    static var lumenTertiaryGroupedBackground: PlatformColor {
        #if canImport(UIKit)
        .tertiarySystemGroupedBackground
        #else
        .controlBackgroundColor
        #endif
    }

    static var lumenCodeBackground: PlatformColor {
        #if canImport(UIKit)
        .systemGray6
        #else
        .controlBackgroundColor
        #endif
    }

    static var lumenSeparator: PlatformColor {
        #if canImport(UIKit)
        .separator
        #else
        .separatorColor
        #endif
    }

    static var lumenTertiarySystemFill: PlatformColor {
        #if canImport(UIKit)
        .tertiarySystemFill
        #else
        .tertiaryLabelColor.withAlphaComponent(0.18)
        #endif
    }
}

enum LumenColor {

    // MARK: - Text
    static let primaryText     = PlatformColor.lumenLabel.swiftUIColor
    static let secondaryText   = PlatformColor.lumenSecondaryLabel.swiftUIColor
    static let tertiaryText    = PlatformColor.lumenTertiaryLabel.swiftUIColor
    static let placeholderText = PlatformColor.lumenPlaceholderText.swiftUIColor

    // MARK: - Backgrounds
    static let primaryBackground   = PlatformColor.lumenSystemBackground.swiftUIColor
    static let secondaryBackground = PlatformColor.lumenSecondarySystemBackground.swiftUIColor
    static let groupedBackground   = PlatformColor.lumenGroupedBackground.swiftUIColor
    static let groupedSecondary    = PlatformColor.lumenSecondaryGroupedBackground.swiftUIColor
    static let groupedTertiary     = PlatformColor.lumenTertiaryGroupedBackground.swiftUIColor

    // MARK: - Chat Bubbles
    static let userBubble      = Color.accentColor.opacity(0.15)
    static let assistantBubble = PlatformColor.lumenSecondaryGroupedBackground.swiftUIColor
    static let systemBubble    = PlatformColor.lumenTertiaryGroupedBackground.swiftUIColor

    // MARK: - Code Blocks
    static let codeBackground = PlatformColor.lumenCodeBackground.swiftUIColor

    // MARK: - Status
    static let success = Color.green
    static let warning = Color.orange
    static let error   = Color.red
    static let info    = Color.blue

    // MARK: - Interactive
    static let tint        = Color.accentColor
    static let destructive = Color.red
    static let disabled    = PlatformColor.lumenQuaternaryLabel.swiftUIColor
    static let separator   = PlatformColor.lumenSeparator.swiftUIColor
    static let tertiaryFill = PlatformColor.lumenTertiarySystemFill.swiftUIColor
}
