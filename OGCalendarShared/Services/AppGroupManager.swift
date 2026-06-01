import Foundation

final class AppGroupManager: @unchecked Sendable {

    static let shared = AppGroupManager()

    // App Group Identifier - 需要与 Xcode 配置中的一致
    let appGroupIdentifier = "group.com.ogcalendar.shared"

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Selected Date

    var selectedDate: Date? {
        get {
            guard let timeInterval = defaults?.object(forKey: "selectedDate") as? Double else { return nil }
            return Date(timeIntervalSince1970: timeInterval)
        }
        set {
            if let date = newValue {
                defaults?.set(date.timeIntervalSince1970, forKey: "selectedDate")
            } else {
                defaults?.removeObject(forKey: "selectedDate")
            }
        }
    }

    // MARK: - Display Month (Widget 月度视图当前显示月份)

    var displayMonth: Date? {
        get {
            guard let timeInterval = defaults?.object(forKey: "displayMonth") as? Double else { return nil }
            return Date(timeIntervalSince1970: timeInterval)
        }
        set {
            if let date = newValue {
                defaults?.set(date.timeIntervalSince1970, forKey: "displayMonth")
            } else {
                defaults?.removeObject(forKey: "displayMonth")
            }
        }
    }

    // MARK: - Events Cache

    func cacheEvents(_ events: [CalendarEvent], for date: Date) {
        let key = "events_\(Int(date.timeIntervalSince1970 / 86400))"
        do {
            let data = try JSONEncoder().encode(events)
            defaults?.set(data, forKey: key)
        } catch {
            print("⚠️ Failed to cache events: \(error)")
        }
    }

    func cachedEvents(for date: Date) -> [CalendarEvent] {
        let key = "events_\(Int(date.timeIntervalSince1970 / 86400))"
        guard let data = defaults?.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([CalendarEvent].self, from: data)
        } catch {
            return []
        }
    }

    // MARK: - Month Events Cache

    /// 缓存整月事件分布（每天的事件数量）
    func cacheMonthEvents(_ eventsByDay: [String: Int], year: Int, month: Int) {
        let key = String(format: "monthEventCounts_%04d-%02d", year, month)
        do {
            let data = try JSONEncoder().encode(eventsByDay)
            defaults?.set(data, forKey: key)
        } catch {
            print("⚠️ Failed to cache month events: \(error)")
        }
    }

    /// 读取整月事件分布缓存
    func cachedMonthEvents(year: Int, month: Int) -> [String: Int] {
        let key = String(format: "monthEventCounts_%04d-%02d", year, month)
        guard let data = defaults?.data(forKey: key) else { return [:] }
        do {
            return try JSONDecoder().decode([String: Int].self, from: data)
        } catch {
            return [:]
        }
    }

    // MARK: - Clear Cache

    func clearCache() {
        guard let defaults = defaults else { return }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("events_") || key.hasPrefix("monthEventCounts_") {
            defaults.removeObject(forKey: key)
        }
    }
}
