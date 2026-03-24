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
}

enum LumenAnimation {
    static let standard = Animation.spring(duration: 0.35, bounce: 0.15)
    static let snappy   = Animation.spring(duration: 0.25, bounce: 0.2)
    static let gentle   = Animation.spring(duration: 0.5, bounce: 0.1)
    static let fade     = Animation.easeOut(duration: 0.15)
}

enum LumenType {
    static let messageBody    = Font.body
    static let messageCaption = Font.caption
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
    static let messageBubbleMaxWidthPhone: CGFloat = 0.85
    static let messageBubbleMaxWidthPad: CGFloat   = 0.65
    static let minTouchTarget: CGFloat       = 44
    static let messageBubbleCornerRadius     = LumenRadius.lg
    static let messageBubblePaddingH: CGFloat = 12
    static let messageBubblePaddingV: CGFloat = 10
}
