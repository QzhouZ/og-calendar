import Foundation

final class AppGroupManager {

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

    // MARK: - Clear Cache

    func clearCache() {
        guard let defaults = defaults else { return }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("events_") {
            defaults.removeObject(forKey: key)
        }
    }
}
