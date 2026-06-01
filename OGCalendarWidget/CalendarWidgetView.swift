import SwiftUI
import WidgetKit

// MARK: - Small Widget

struct CalendarWidgetSmall: Widget {
    let kind: String = "CalendarWidgetSmall"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectDateIntent.self,
            provider: CalendarTimelineProvider()
        ) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("日历")
        .description("显示日期和农历")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium Widget

struct CalendarWidgetMedium: Widget {
    let kind: String = "CalendarWidgetMedium"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectDateIntent.self,
            provider: CalendarTimelineProvider()
        ) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("日历与事件")
        .description("显示月历和当日事件")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Large Widget (月度视图)

struct CalendarWidgetLarge: Widget {
    let kind: String = "CalendarWidgetLarge"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectDateIntent.self,
            provider: CalendarTimelineProvider()
        ) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("月度日历")
        .description("完整月历视图，显示事件标记")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: CalendarEntry

    var body: some View {
        VStack(spacing: 4) {
            // 选中日期
            if let day = entry.calendarDays.first(where: { $0.isSelected }) {
                Text("\(day.day)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1A1A1A"))

                Text(day.displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "3B7DD8"))

                // 节假日标签
                if let name = day.holidayName, day.isHoliday {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "E8743A"))
                        .clipShape(Capsule())
                }
            }

            // 事件数量
            if !entry.events.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 10))
                    Text("\(entry.events.count)个事件")
                        .font(.system(size: 11, weight: .regular))
                }
                .foregroundColor(Color(hex: "999999"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: CalendarEntry

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        HStack(spacing: 12) {
            // 左侧迷你月历
            VStack(spacing: 2) {
                // 月份标题
                Text(monthTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))

                // 星期标题
                HStack(spacing: 0) {
                    ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { w in
                        Text(w)
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "999999"))
                            .frame(maxWidth: .infinity)
                    }
                }

                // 日期网格
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(Array(entry.calendarDays.prefix(35).enumerated()), id: \.offset) { _, day in
                        VStack(spacing: 0) {
                            Text("\(day.day)")
                                .font(.system(size: 9, weight: day.isSelected ? .bold : .regular))
                                .foregroundColor(widgetDayColor(day))
                                .frame(width: 16, height: 14)
                                .background(day.isSelected ? Color(hex: "3B7DD8") : Color.clear)
                                .clipShape(Circle())

                            // 事件圆点
                            Circle()
                                .fill(day.hasEvents ? Color(hex: "3B7DD8") : Color.clear)
                                .frame(width: 3, height: 3)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // 分隔线
            Rectangle()
                .fill(Color(hex: "EEF1F5"))
                .frame(width: 1)
                .padding(.vertical, 8)

            // 右侧事件列表
            VStack(alignment: .leading, spacing: 4) {
                if entry.events.isEmpty {
                    Text("暂无安排")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "999999"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(entry.events.prefix(3)) { event in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: event.colorHex))
                                .frame(width: 3, height: 24)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(event.title)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                    .lineLimit(1)

                                Text(event.timeText)
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(hex: "999999"))
                            }
                        }
                    }

                    if entry.events.count > 3 {
                        Text("还有\(entry.events.count - 3)个...")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "999999"))
                    }
                }

                Spacer()

                // 日期切换按钮
                HStack {
                    Button(intent: PreviousDayIntent()) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "555555"))
                    }
                    Spacer()
                    Button(intent: NextDayIntent()) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "555555"))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter.string(from: entry.displayMonth)
    }

    private func widgetDayColor(_ day: WidgetCalendarDay) -> Color {
        if day.isSelected { return .white }
        if !day.isCurrentMonth { return Color(hex: "C0C4CC") }
        if day.isHoliday { return Color(hex: "E8743A") }
        if day.isWorkday { return Color(hex: "555555") }
        return Color(hex: "1A1A1A")
    }
}

// MARK: - Large Widget View (月度视图)

struct LargeWidgetView: View {
    let entry: CalendarEntry

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            // 顶部导航栏
            HStack {
                Button(intent: PreviousMonthIntent()) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "3B7DD8"))
                }

                Spacer()

                Text(monthYearTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))

                Spacer()

                Button(intent: NextMonthIntent()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "3B7DD8"))
                }
            }
            .padding(.horizontal, 4)

            // 星期标题
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { w in
                    Text(w)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "999999"))
                        .frame(maxWidth: .infinity)
                }
            }

            // 月历网格
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(Array(entry.calendarDays.prefix(42).enumerated()), id: \.offset) { _, day in
                    Button(intent: SelectWidgetDateIntent(year: day.year, month: day.month, day: day.day)) {
                        VStack(spacing: 1) {
                            // 日期数字
                            Text("\(day.day)")
                                .font(.system(size: 15, weight: day.isSelected ? .bold : (day.isToday ? .semibold : .regular)))
                                .foregroundColor(largeDayTextColor(day))
                                .frame(width: 28, height: 28)
                                .background(largeDayBackground(day))
                                .clipShape(Circle())

                            // 农历文本
                            Text(day.displayText)
                                .font(.system(size: 8))
                                .foregroundColor(largeDaySubTextColor(day))
                                .lineLimit(1)

                            // 事件圆点
                            Circle()
                                .fill(day.hasEvents ? Color(hex: "3B7DD8") : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }

            // 底部事件区域
            Divider()
                .background(Color(hex: "EEF1F5"))

            if let selectedDay = entry.calendarDays.first(where: { $0.isSelected }) {
                HStack(spacing: 4) {
                    Text("\(selectedDay.month)月\(selectedDay.day)日")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text(selectedDay.displayText)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "3B7DD8"))
                    Spacer()
                    if !entry.events.isEmpty {
                        Text("\(entry.events.count)个事件")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "999999"))
                    }
                }
            }

            if entry.events.isEmpty {
                Text("暂无安排")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "999999"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 4) {
                    ForEach(entry.events.prefix(3)) { event in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Color(hex: event.colorHex))
                                .frame(width: 3, height: 20)

                            Text(event.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "1A1A1A"))
                                .lineLimit(1)

                            Spacer()

                            Text(event.timeText)
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "999999"))
                        }
                    }

                    if entry.events.count > 3 {
                        Text("还有\(entry.events.count - 3)个事件")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "999999"))
                    }
                }
            }
        }
        .padding(12)
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: entry.displayMonth)
    }

    private func largeDayTextColor(_ day: WidgetCalendarDay) -> Color {
        if day.isSelected { return .white }
        if !day.isCurrentMonth { return Color(hex: "C0C4CC") }
        if day.isToday { return Color(hex: "3B7DD8") }
        if day.isHoliday { return Color(hex: "E8743A") }
        if day.isWorkday { return Color(hex: "555555") }
        if day.weekday == 1 || day.weekday == 7 { return Color(hex: "E8743A") }
        return Color(hex: "1A1A1A")
    }

    private func largeDaySubTextColor(_ day: WidgetCalendarDay) -> Color {
        if day.isSelected { return .white.opacity(0.8) }
        if !day.isCurrentMonth { return Color(hex: "C0C4CC").opacity(0.6) }
        return Color(hex: "999999")
    }

    private func largeDayBackground(_ day: WidgetCalendarDay) -> Color {
        if day.isSelected { return Color(hex: "3B7DD8") }
        if day.isToday { return Color(hex: "3B7DD8").opacity(0.1) }
        return .clear
    }
}
