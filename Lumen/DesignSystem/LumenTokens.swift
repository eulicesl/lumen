import SwiftUI

enum LumenSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat  = 4
    static let xs: CGFloat   = 8
    static let sm: CGFloat   = 12
    static let md: CGFloat   = 16
    static let lg: CGFloat   = 20
    static let xl: CGFloat   = 24
    static let xxl: CGFloat  = 32
    static let xxxl: CGFloat = 48
}

enum LumenRadius {
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 8
    static let md: CGFloat   = 12
    static let lg: CGFloat   = 16
    static let xl: CGFloat   = 20
    static let xxl: CGFloat  = 24
    static let full: CGFloat = 9999
    static let bubble: CGFloat = 18
}

enum LumenAnimation {
    static let standard    = Animation.spring(duration: 0.35, bounce: 0.15)
    static let snappy      = Animation.spring(duration: 0.25, bounce: 0.2)
    static let gentle      = Animation.spring(duration: 0.5, bounce: 0.1)
    static let fade        = Animation.easeOut(duration: 0.15)
    static let interactive = Animation.spring(duration: 0.2, bounce: 0.1)
}

enum LumenMotion {
    static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    static func perform(
        _ animation: Animation = LumenAnimation.standard,
        reduceMotion: Bool,
        _ updates: () -> Void
    ) {
        if reduceMotion {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction, updates)
        } else {
            withAnimation(animation, updates)
        }
    }

    static func moveTransition(edge: Edge, reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge).combined(with: .opacity)
    }

    static func scaleTransition(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .scale.combined(with: .opacity)
    }
}

enum LumenType {
    static let messageBody    = Font.body
    static let messageCaption = Font.caption
    static let body           = Font.body
    static let caption        = Font.caption
    static let codeBlock      = Font.system(.body, design: .monospaced)
    static let largeTitle     = Font.largeTitle
    static let title          = Font.title3
    static let headline       = Font.headline
    static let buttonLabel    = Font.body
    static let footnote       = Font.footnote
    static let caption2       = Font.caption2
}

enum LumenLayout {
    static let iPhoneEdgePadding: CGFloat    = 16
    static let iPadEdgePadding: CGFloat      = 20
    static let macEdgePadding: CGFloat       = 24
    static let sidebarWidthiPad: CGFloat     = 320
    static let sidebarWidthMac: CGFloat      = 280
    static let maxContentWidthiPad: CGFloat  = 720
    static let maxContentWidthMac: CGFloat   = 800
    static let minTouchTarget: CGFloat       = 44
    static let messageBubbleCornerRadius     = LumenRadius.lg
    static let messageBubblePaddingH: CGFloat = 12
    static let messageBubblePaddingV: CGFloat = 10

    enum Bubble {
        #if os(iOS)
        static let userMinWidth: CGFloat      = 180
        static let userMaxWidth: CGFloat      = 340
        static let assistantMinWidth: CGFloat = 240
        static let assistantMaxWidth: CGFloat = 800
        #else
        static let userMinWidth: CGFloat      = 260
        static let userMaxWidth: CGFloat      = 400
        static let assistantMinWidth: CGFloat = 320
        static let assistantMaxWidth: CGFloat = 1000
        #endif
        static let userWidthRatio: CGFloat      = 0.75
        static let assistantWidthRatio: CGFloat = 0.92
    }
}
