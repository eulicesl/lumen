import Foundation

extension Date {
    enum ConversationGroup: String, CaseIterable {
        case today         = "Today"
        case yesterday     = "Yesterday"
        case lastSevenDays = "Previous 7 Days"
        case lastThirtyDays = "Previous 30 Days"
        case older         = "Older"
    }

    var conversationGroup: ConversationGroup {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return .today
        } else if calendar.isDateInYesterday(self) {
            return .yesterday
        } else if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
                  self >= sevenDaysAgo {
            return .lastSevenDays
        } else if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()),
                  self >= thirtyDaysAgo {
            return .lastThirtyDays
        } else {
            return .older
        }
    }

    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: self)
    }
}
