import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 月份导航
                MonthNavigationView()

                Divider()
                    .padding(.vertical, 4)

                // 星期标题
                WeekdayHeaderView()

                // 日历网格
                CalendarGridView()

                Divider()
                    .padding(.vertical, 4)

                // 事件列表
                EventListView()
            }
            .background(Color(.F7F8FA))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Weekday Header

struct WeekdayHeaderView: View {
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 13, weight: .500))
                    .foregroundColor(Color(.999999))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CalendarView()
        .environmentObject(CalendarViewModel())
}
