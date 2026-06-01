import Foundation

struct CalendarDay: Identifiable, Sendable {
    let id: String          // 格式: "yyyy-MM-dd"
    let date: Date           // 公历日期
    let year: Int
    let month: Int
    let day: Int
    let weekday: Int         // 1=周日 ... 7=周六

    // 农历信息
    let lunarYear: Int
    let lunarMonth: Int
    let lunarDay: Int
    let lunarMonthName: String   // "正月", "二月"...
    let lunarDayName: String     // "初一", "初二"...
    let lunarYearGanZhi: String  // 天干地支年
    let isLeapMonth: Bool

    // 节假日信息
    var holiday: Holiday?
    var isWeekend: Bool { weekday == 1 || weekday == 7 }

    // 农历节日或节气
    var lunarFestival: String?   // "春节", "中秋"等
    var solarTerm: String?       // "立春", "雨水"等

    // 显示优先级：农历节日/节气 > 节假日 > 农历日期
    var displayText: String {
        if let festival = lunarFestival { return festival }
        if let term = solarTerm { return term }
        if let holiday = holiday { return holiday.name }
        if lunarDay == 1 { return lunarMonthName }  // 初一显示月份
        return lunarDayName
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var isSelected: Bool = false
}
