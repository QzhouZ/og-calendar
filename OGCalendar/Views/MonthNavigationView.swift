import SwiftUI

struct MonthNavigationView: View {
    @EnvironmentObject var viewModel: CalendarViewModel

    var body: some View {
        HStack {
            // 上月
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "555555"))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // 年月标题
            Text(viewModel.currentYearMonthString)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "1A1A1A"))

            Spacer()

            // 下月
            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "555555"))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
