import Foundation

final class HolidayService {

    static let shared = HolidayService()

    private var holidays: [String: [String: HolidayEntry]] = [:]  // [year: [dateKey: entry]]
    private let holidaysFileName = "holidays"

    private init() {
        loadHolidays()
    }

    // MARK: - Load Data

    private func loadHolidays() {
        guard let url = Bundle.main.url(forResource: holidaysFileName, withExtension: "json") else {
            print("⚠️ holidays.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            holidays = try JSONDecoder().decode([String: [String: HolidayEntry]].self, from: data)
        } catch {
            print("⚠️ Failed to load holidays.json: \(error)")
        }
    }

    // MARK: - Query

    /// 查询指定日期是否为节假日或调休日
    func holiday(for date: Date) -> Holiday? {
        let gregorian = Calendar(identifier: .gregorian)
        let year = gregorian.component(.year, from: date)
        let month = gregorian.component(.month, from: date)
        let day = gregorian.component(.day, from: date)

        let yearKey = "\(year)"
        let dateKey = String(format: "%02d-%02d", month, day)

        guard let yearData = holidays[yearKey],
              let entry = yearData[dateKey] else {
            return nil
        }

        let id = String(format: "%04d-%02d-%02d", year, month, day)
        let type: HolidayType = entry.type == "holiday" ? .holiday : .workday

        return Holiday(id: id, name: entry.name, type: type)
    }

    /// 查询指定月份所有节假日
    func holidays(in year: Int, month: Int) -> [String: Holiday] {
        let yearKey = "\(year)"
        let monthPrefix = String(format: "%02d-", month)

        guard let yearData = holidays[yearKey] else { return [:] }

        var result: [String: Holiday] = [:]
        for (dateKey, entry) in yearData {
            if dateKey.hasPrefix(monthPrefix) {
                let type: HolidayType = entry.type == "holiday" ? .holiday : .workday
                let id = "\(yearKey)-\(dateKey)"
                result[dateKey] = Holiday(id: id, name: entry.name, type: type)
            }
        }
        return result
    }
}
