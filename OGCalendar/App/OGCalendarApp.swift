import SwiftUI

@main
struct OGCalendarApp: App {
    @StateObject private var calendarViewModel = CalendarViewModel()

    var body: some Scene {
        WindowGroup {
            CalendarView()
                .environmentObject(calendarViewModel)
        }
    }
}
