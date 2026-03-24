// LumenWidget target — Add this file to the "LumenWidget" extension target in Xcode.
// File → New Target → Widget Extension → named "LumenWidget"
// Do NOT add this file to the main Lumen target.

import WidgetKit
import SwiftUI

@main
struct LumenWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickAskWidget()
        RecentConversationWidget()
    }
}
