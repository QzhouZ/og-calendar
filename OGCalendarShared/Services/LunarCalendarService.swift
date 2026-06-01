import Foundation

final class LunarCalendarService: @unchecked Sendable {

    static let shared = LunarCalendarService()

    private let chineseCalendar: Calendar
    private let formatter: DateFormatter

    private init() {
        chineseCalendar = Calendar(identifier: .chinese)
        formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .chinese)
        formatter.locale = Locale(identifier: "zh_CN")
    }

    // MARK: - Lunar Conversion

    /// 获取农历月名称
    func lunarMonthName(month: Int, isLeap: Bool) -> String {
        let months = ["正月", "二月", "三月", "四月", "五月", "六月",
                      "七月", "八月", "九月", "十月", "冬月", "腊月"]
        let name = months[safe: month - 1] ?? ""
        return isLeap ? "闰\(name)" : name
    }

    /// 获取农历日名称
    func lunarDayName(day: Int) -> String {
        let days = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                    "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
        return days[safe: day - 1] ?? ""
    }

    /// 获取天干地支年
    func ganZhiYear(lunarYear: Int) -> String {
        let gan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
        let zhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
        let g = gan[(lunarYear - 4) % 10]
        let z = zhi[(lunarYear - 4) % 12]
        return "\(g)\(z)年"
    }

    /// 从公历日期获取完整农历信息
    func lunarInfo(from date: Date) -> (year: Int, month: Int, day: Int, isLeapMonth: Bool, monthName: String, dayName: String, ganZhi: String) {
        let components = chineseCalendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)

        let year = components.year ?? 1
        let month = components.month ?? 1
        let day = components.day ?? 1
        let isLeap = components.isLeapMonth ?? false

        return (
            year: year,
            month: month,
            day: day,
            isLeapMonth: isLeap,
            monthName: lunarMonthName(month: month, isLeap: isLeap),
            dayName: lunarDayName(day: day),
            ganZhi: ganZhiYear(lunarYear: year)
        )
    }

    /// 获取农历节日
    func lunarFestival(month: Int, day: Int, isLeap: Bool) -> String? {
        guard !isLeap else { return nil }
        let key = "\(month)-\(day)"
        let festivals: [String: String] = [
            "1-1": "春节",
            "1-15": "元宵节",
            "2-2": "龙抬头",
            "5-5": "端午节",
            "7-7": "七夕",
            "7-15": "中元节",
            "8-15": "中秋节",
            "9-9": "重阳节",
            "12-8": "腊八节",
            "12-23": "小年",
            "12-30": "除夕",
            "12-29": "除夕"  // 小月除夕
        ]
        return festivals[key]
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
