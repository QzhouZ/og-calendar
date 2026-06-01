import WidgetKit
import SwiftUI

@main
struct CalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalendarWidgetSmall()
        CalendarWidgetMedium()
    }
}
