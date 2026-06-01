import WidgetKit
import SwiftUI

// MARK: - Shared Models for Widget

struct WidgetCalendarDay: Codable {
    let day: Int
    let month: Int
    let year: Int
    let weekday: Int
    let lunarDayName: String
    let lunarMonthName: String
    let displayText: String
    let isToday: Bool
    let isSelected: Bool
    let isHoliday: Bool
    let isWorkday: Bool
    let holidayName: String?
}

struct WidgetEvent: Codable, Identifiable {
    let id: String
    let title: String
    let timeText: String
    let colorHex: String
}

// MARK: - Widget Entry

struct CalendarEntry: TimelineEntry {
    let date: Date
    let selectedDate: Date
    let calendarDays: [WidgetCalendarDay]
    let events: [WidgetEvent]
}

// MARK: - Timeline Provider

struct CalendarTimelineProvider: AppIntentTimelineProvider {
    typealias Intent = SelectDateIntent
    typealias Entry = CalendarEntry

    let appGroupIdentifier = "group.com.ogcalendar.shared"

    func placeholder(in context: Context) -> CalendarEntry {
        let today = Date()
        return CalendarEntry(
            date: today,
            selectedDate: today,
            calendarDays: generatePlaceholderDays(),
            events: []
        )
    }

    func snapshot(for configuration: SelectDateIntent, in context: Context) async -> CalendarEntry {
        let selectedDate = configuration.selectedDate?.date ?? Date()
        return await createEntry(for: selectedDate, context: context)
    }

    func timeline(for configuration: SelectDateIntent, in context: Context) async -> Timeline<CalendarEntry> {
        let selectedDate = configuration.selectedDate?.date ?? Date()
        let entry = await createEntry(for: selectedDate, context: context)

        // 每小时刷新一次
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: - Create Entry

    private func createEntry(for selectedDate: Date, context: Context) async -> CalendarEntry {
        let lunarService = LunarCalendarService.shared
        let holidayService = HolidayService.shared
        let solarTermService = SolarTermService.shared
        let appGroupManager = AppGroupManager.shared

        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let firstOfMonth = calendar.date(from: components) else {
            return CalendarEntry(date: Date(), selectedDate: selectedDate, calendarDays: [], events: [])
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = firstWeekday - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        var widgetDays: [WidgetCalendarDay] = []

        // 上月补齐
        if leadingDays > 0 {
            guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth) else { return CalendarEntry(date: Date(), selectedDate: selectedDate, calendarDays: [], events: []) }
            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonth)?.count ?? 30
            for i in (daysInPrevMonth - leadingDays + 1)...daysInPrevMonth {
                var comps = calendar.dateComponents([.year, .month], from: prevMonth)
                comps.day = i
                if let date = calendar.date(from: comps) {
                    widgetDays.append(makeWidgetDay(from: date, isSelected: false, lunarService: lunarService, holidayService: holidayService, solarTermService: solarTermService))
                }
            }
        }

        // 当月
        for day in 1...daysInMonth {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            if let date = calendar.date(from: comps) {
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                widgetDays.append(makeWidgetDay(from: date, isSelected: isSelected, lunarService: lunarService, holidayService: holidayService, solarTermService: solarTermService))
            }
        }

        // 下月补齐到 35
        let remaining = 35 - widgetDays.count
        if remaining > 0 {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) else { return CalendarEntry(date: Date(), selectedDate: selectedDate, calendarDays: widgetDays, events: []) }
            for day in 1...remaining {
                var comps = calendar.dateComponents([.year, .month], from: nextMonth)
                comps.day = day
                if let date = calendar.date(from: comps) {
                    widgetDays.append(makeWidgetDay(from: date, isSelected: false, lunarService: lunarService, holidayService: holidayService, solarTermService: solarTermService))
                }
            }
        }

        // 获取缓存事件
        let cachedEvents = appGroupManager.cachedEvents(for: selectedDate)

        let widgetEvents = cachedEvents.map { event in
            WidgetEvent(id: event.id, title: event.title, timeText: event.durationText, colorHex: event.calendarColorHex)
        }

        return CalendarEntry(date: Date(), selectedDate: selectedDate, calendarDays: widgetDays, events: widgetEvents)
    }

    private func makeWidgetDay(from date: Date, isSelected: Bool, lunarService: LunarCalendarService, holidayService: HolidayService, solarTermService: SolarTermService) -> WidgetCalendarDay {
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)

        let lunarInfo = lunarService.lunarInfo(from: date)
        let holiday = holidayService.holiday(for: date)
        let lunarFestival = lunarService.lunarFestival(month: lunarInfo.month, day: lunarInfo.day, isLeap: lunarInfo.isLeapMonth)
        let solarTerm = solarTermService.solarTerm(for: date)

        let displayText: String
        if let festival = lunarFestival { displayText = festival }
        else if let term = solarTerm { displayText = term }
        else if let h = holiday { displayText = h.name }
        else if lunarInfo.day == 1 { displayText = lunarInfo.monthName }
        else { displayText = lunarInfo.dayName }

        return WidgetCalendarDay(
            day: day, month: month, year: year, weekday: weekday,
            lunarDayName: lunarInfo.dayName, lunarMonthName: lunarInfo.monthName,
            displayText: displayText,
            isToday: calendar.isDateInToday(date),
            isSelected: isSelected,
            isHoliday: holiday?.isHoliday ?? false,
            isWorkday: holiday?.isWorkday ?? false,
            holidayName: holiday?.name
        )
    }

    private func generatePlaceholderDays() -> [WidgetCalendarDay] {
        let today = Date()
        let calendar = Calendar.current
        return (0..<35).map { offset in
            let date = calendar.date(byAdding: .day, value: offset - 15, to: today)!
            return WidgetCalendarDay(
                day: calendar.component(.day, from: date),
                month: calendar.component(.month, from: date),
                year: calendar.component(.year, from: date),
                weekday: calendar.component(.weekday, from: date),
                lunarDayName: "初一", lunarMonthName: "正月",
                displayText: "\(calendar.component(.day, from: date))",
                isToday: offset == 15, isSelected: offset == 15,
                isHoliday: false, isWorkday: false, holidayName: nil
            )
        }
    }
}
