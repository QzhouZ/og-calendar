import SwiftUI

struct EventListView: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 选中日期信息
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedDateString)
                        .font(.system(size: 16, weight: .600))
                        .foregroundColor(Color(.1A1A1A))
                    Text(viewModel.selectedLunarString)
                        .font(.system(size: 13, weight: .400))
                        .foregroundColor(Color(.999999))
                }

                Spacer()

                Button {
                    viewModel.goToToday()
                } label: {
                    Text("今天")
                        .font(.system(size: 13, weight: .500))
                        .foregroundColor(Color(.3B7DD8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.3B7DD8).opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // 事件列表
            if viewModel.events.isEmpty {
                // 空状态
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28))
                        .foregroundColor(Color(.C0C4CC))
                    Text("暂无安排")
                        .font(.system(size: 14, weight: .400))
                        .foregroundColor(Color(.999999))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.events) { event in
                            EventCardView(event: event)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // 左侧色条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.calendarColorHex))
                .frame(width: 4, height: 40)

            // 事件信息
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 15, weight: .500))
                    .foregroundColor(Color(.1A1A1A))
                    .lineLimit(1)

                Text(event.durationText)
                    .font(.system(size: 12, weight: .400))
                    .foregroundColor(Color(.999999))
            }

            Spacer()

            // 日历名称
            Text(event.calendarTitle)
                .font(.system(size: 11, weight: .400))
                .foregroundColor(Color(.C0C4CC))
        }
        .padding(12)
        .background(Color(.F7F8FA))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
