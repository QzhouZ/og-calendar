import AppIntents
import WidgetKit

// MARK: - Select Date Intent (Widget Configuration)

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

// MARK: - Month Navigation Intents

struct PreviousMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "上一个月"
    static var description = IntentDescription("切换到上一个月")

    func perform() async throws -> some IntentResult {
        let appGroup = AppGroupManager.shared
        let current = appGroup.displayMonth ?? Date()
        let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: current) ?? Date()
        appGroup.displayMonth = newMonth
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

struct NextMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "下一个月"
    static var description = IntentDescription("切换到下一个月")

    func perform() async throws -> some IntentResult {
        let appGroup = AppGroupManager.shared
        let current = appGroup.displayMonth ?? Date()
        let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: current) ?? Date()
        appGroup.displayMonth = newMonth
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Select Widget Date Intent

struct SelectWidgetDateIntent: AppIntent {
    static var title: LocalizedStringResource = "选择日期"
    static var description = IntentDescription("选择小组件中的日期")

    @Parameter(title: "年")
    var year: Int

    @Parameter(title: "月")
    var month: Int

    @Parameter(title: "日")
    var day: Int

    init() {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        self.year = comps.year ?? 2026
        self.month = comps.month ?? 1
        self.day = comps.day ?? 1
    }

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    func perform() async throws -> some IntentResult {
        let appGroup = AppGroupManager.shared
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        if let date = Calendar.current.date(from: comps) {
            appGroup.selectedDate = date
            // 同步更新 displayMonth 到该日期所在月
            appGroup.displayMonth = date
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
