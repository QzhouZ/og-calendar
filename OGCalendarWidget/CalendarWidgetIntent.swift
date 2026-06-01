import AppIntents
import WidgetKit

// MARK: - Select Date Intent

struct SelectDateIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择日期"
    static var description = IntentDescription("选择日历小组件显示的日期")

    @Parameter(title: "选择日期", default: Calendar.current.dateComponents([.year, .month, .day], from: Date()))
    var selectedDate: DateComponents?

    static var parameterSummary: some ParameterSummary {
        Summary("显示日历")
    }
}

// MARK: - Navigation Intents

struct PreviousDayIntent: AppIntent {
    static var title: LocalizedStringResource = "前一天"
    static var description = IntentDescription("切换到前一天")

    func perform() async throws -> some IntentResult {
        let appGroup = AppGroupManager.shared
        if let current = appGroup.selectedDate {
            let newDate = Calendar.current.date(byAdding: .day, value: -1, to: current) ?? Date()
            appGroup.selectedDate = newDate
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct NextDayIntent: AppIntent {
    static var title: LocalizedStringResource = "后一天"
    static var description = IntentDescription("切换到后一天")

    func perform() async throws -> some IntentResult {
        let appGroup = AppGroupManager.shared
        if let current = appGroup.selectedDate {
            let newDate = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? Date()
            appGroup.selectedDate = newDate
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
