import Foundation

// MARK: - Holiday Types
enum HolidayType: String, Codable {
    case holiday  // 法定放假
    case workday   // 调休上班
}

// MARK: - Holiday Model
struct Holiday: Codable, Identifiable {
    let id: String      // 格式: "2025-01-01"
    let name: String    // 节假日名称
    let type: HolidayType

    var isHoliday: Bool { type == .holiday }
    var isWorkday: Bool { type == .workday }
}

// MARK: - Holiday Collection (from JSON)
struct HolidayYearData: Codable {
    let holidays: [String: HolidayEntry]  // key: "01-01"
}

struct HolidayEntry: Codable {
    let name: String
    let type: String  // "holiday" or "workday"
}
