import Foundation
import EventKit

final class EventKitService: ObservableObject {

    static let shared = EventKitService()

    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    // MARK: - Permission

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                self.authorizationStatus = granted ? .fullAccess : .denied
            }
            return granted
        } catch {
            print("⚠️ EventKit access denied: \(error)")
            await MainActor.run {
                self.authorizationStatus = .denied
            }
            return false
        }
    }

    // MARK: - Fetch Events

    /// 获取指定日期的事件
    func fetchEvents(for date: Date) async -> [CalendarEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)
        return ekEvents.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier,
                title: ekEvent.title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                isAllDay: ekEvent.isAllDay,
                calendarColorHex: ekEvent.calendar.cgColor.hexString,
                calendarTitle: ekEvent.calendar.title
            )
        }
    }

    /// 获取指定月份范围的所有事件
    func fetchEvents(for year: Int, month: Int) async -> [Date: [CalendarEvent]] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return [:]
        }

        let endRange = calendar.date(byAdding: .day, value: 1, to: endOfMonth)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfMonth,
            end: endRange,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        var eventsByDate: [Date: [CalendarEvent]] = [:]
        for ekEvent in ekEvents {
            let dayStart = calendar.startOfDay(for: ekEvent.startDate)
            let event = CalendarEvent(
                id: ekEvent.eventIdentifier,
                title: ekEvent.title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                isAllDay: ekEvent.isAllDay,
                calendarColorHex: ekEvent.calendar.cgColor.hexString,
                calendarTitle: ekEvent.calendar.title
            )
            eventsByDate[dayStart, default: []].append(event)
        }
        return eventsByDate
    }
}

// MARK: - CGColor Hex Extension
extension CGColor {
    var hexString: String {
        guard let components = components, components.count >= 3 else {
            return "#3B7DD8"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
