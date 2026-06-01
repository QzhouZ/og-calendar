import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class CalendarViewModel: ObservableObject {

    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date = Date()
    @Published var calendarDays: [CalendarDay] = []
    @Published var events: [CalendarEvent] = []
    @Published var isAuthorized: Bool = false

    /// 整月事件按日期 key (yyyy-MM-dd) 分组
    private var eventsByDay: [String: [CalendarEvent]] = [:]

    private let lunarService = LunarCalendarService.shared
    private let holidayService = HolidayService.shared
    private let solarTermService = SolarTermService.shared
    private let eventKitService = EventKitService.shared
    private let appGroupManager = AppGroupManager.shared

    private let calendar = Calendar(identifier: .gregorian)

    init() {
        generateCalendarDays()
        Task {
            await requestCalendarAccess()
            await loadEventsForCurrentMonth()
            await loadEventsForSelectedDate()
        }
    }

    // MARK: - Permission

    func requestCalendarAccess() async {
        let granted = await eventKitService.requestAccess()
        isAuthorized = granted
    }

    // MARK: - Month Navigation

    func goToPreviousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = newMonth
            generateCalendarDays()
        }
        Task { await loadEventsForCurrentMonth() }
    }

    func goToNextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = newMonth
            generateCalendarDays()
        }
        Task { await loadEventsForCurrentMonth() }
    }

    func goToToday() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = Date()
            selectedDate = Date()
            generateCalendarDays()
        }
        Task {
            await loadEventsForCurrentMonth()
            await loadEventsForSelectedDate()
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        appGroupManager.selectedDate = date
        generateCalendarDays()
        Task { await loadEventsForSelectedDate() }
    }

    // MARK: - Generate Calendar

    func generateCalendarDays() {
        var days: [CalendarDay] = []

        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstOfMonth = calendar.date(from: components) else { return }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = firstWeekday - 1

        // 上月最后几天
        if leadingDays > 0 {
            guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth) else { return }
            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonth)?.count ?? 30
            for i in (daysInPrevMonth - leadingDays + 1)...daysInPrevMonth {
                var comps = calendar.dateComponents([.year, .month], from: prevMonth)
                comps.day = i
                if let date = calendar.date(from: comps) {
                    days.append(makeCalendarDay(from: date))
                }
            }
        }

        // 当月所有日期
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        for day in 1...daysInMonth {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            if let date = calendar.date(from: comps) {
                days.append(makeCalendarDay(from: date))
            }
        }

        // 补齐末尾至 42 天 (6 行)
        let remaining = 42 - days.count
        if remaining > 0 {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) else { return }
            for day in 1...remaining {
                var comps = calendar.dateComponents([.year, .month], from: nextMonth)
                comps.day = day
                if let date = calendar.date(from: comps) {
                    days.append(makeCalendarDay(from: date))
                }
            }
        }

        calendarDays = days
    }

    // MARK: - Private Helpers

    private func makeCalendarDay(from date: Date) -> CalendarDay {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)

        let lunarInfo = lunarService.lunarInfo(from: date)
        let holiday = holidayService.holiday(for: date)
        let lunarFestival = lunarService.lunarFestival(month: lunarInfo.month, day: lunarInfo.day, isLeap: lunarInfo.isLeapMonth)
        let solarTerm = solarTermService.solarTerm(for: date)

        let id = String(format: "%04d-%02d-%02d", year, month, day)

        // 查询该天是否有事件
        let dayEvents = eventsByDay[id] ?? []

        var calendarDay = CalendarDay(
            id: id,
            date: date,
            year: year,
            month: month,
            day: day,
            weekday: weekday,
            lunarYear: lunarInfo.year,
            lunarMonth: lunarInfo.month,
            lunarDay: lunarInfo.day,
            lunarMonthName: lunarInfo.monthName,
            lunarDayName: lunarInfo.dayName,
            lunarYearGanZhi: lunarInfo.ganZhi,
            isLeapMonth: lunarInfo.isLeapMonth,
            holiday: holiday,
            lunarFestival: lunarFestival,
            solarTerm: solarTerm
        )
        calendarDay.isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        calendarDay.hasEvents = !dayEvents.isEmpty
        calendarDay.eventCount = dayEvents.count
        return calendarDay
    }

    // MARK: - Load Events

    /// 加载整月事件（用于日历网格显示事件圆点）
    func loadEventsForCurrentMonth() async {
        guard isAuthorized else { return }

        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)

        let monthEvents = await eventKitService.fetchEvents(for: year, month: month)

        // 将 [Date: [CalendarEvent]] 转为 [String: [CalendarEvent]]
        var byDay: [String: [CalendarEvent]] = [:]
        var countByDay: [String: Int] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for (date, events) in monthEvents {
            let key = formatter.string(from: date)
            byDay[key] = events
            countByDay[key] = events.count
        }
        eventsByDay = byDay

        // 缓存到 AppGroup 供 Widget 使用
        appGroupManager.cacheMonthEvents(countByDay, year: year, month: month)

        // 重新生成日历天数以更新事件标记
        generateCalendarDays()

        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadEventsForSelectedDate() async {
        guard isAuthorized else {
            events = []
            return
        }
        let loadedEvents = await eventKitService.fetchEvents(for: selectedDate)
        events = loadedEvents.sorted { !$0.isAllDay && $1.isAllDay ? false : ($0.startDate < $1.startDate) }

        // 缓存到 App Group 供 Widget 使用
        appGroupManager.cacheEvents(events, for: selectedDate)
        appGroupManager.selectedDate = selectedDate

        // 刷新 Widget
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Formatted Strings

    var currentYearMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: currentMonth)
    }

    var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: selectedDate)
    }

    var selectedLunarString: String {
        let info = lunarService.lunarInfo(from: selectedDate)
        return "\(info.ganZhi) \(info.monthName)\(info.dayName)"
    }
}
