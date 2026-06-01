import SwiftUI

struct DayCell: View {
    let day: CalendarDay

    private var isCurrentMonth: Bool {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        // 通过比较日期是否在当前显示月份来判断
        return day.month == currentMonth || day.isSelected
    }

    var body: some View {
        VStack(spacing: 2) {
            // 公历日期
            Text("\(day.day)")
                .font(.system(size: 18, weight: day.isSelected ? .600 : .400))
                .foregroundColor(dayTextColor)

            // 农历/节假日/节气文本
            Text(day.displayText)
                .font(.system(size: 9, weight: .400))
                .foregroundColor(subTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(dayBackground)
        .clipShape(Circle())
        .overlay(
            Group {
                if day.isToday && !day.isSelected {
                    Circle()
                        .stroke(Color(.3B7DD8), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                }
            }
        )
    }

    // MARK: - Colors

    private var dayTextColor: Color {
        if day.isSelected {
            return .white
        }
        if !isCurrentMonth {
            return Color(.C0C4CC)
        }
        if day.holiday?.isHoliday == true {
            return Color(.E8743A)
        }
        if day.holiday?.isWorkday == true && day.isWeekend {
            return Color(.555555)
        }
        if day.isWeekend {
            return Color(.E8743A)
        }
        return Color(.1A1A1A)
    }

    private var subTextColor: Color {
        if day.holiday?.isHoliday == true {
            return Color(.E8743A)
        }
        if day.lunarFestival != nil || day.solarTerm != nil {
            return Color(.3B7DD8)
        }
        if day.holiday?.isWorkday == true {
            return Color(.999999)
        }
        return isCurrentMonth ? Color(.999999) : Color(.C0C4CC).opacity(0.5)
    }

    private var dayBackground: Color {
        if day.isSelected {
            return Color(.3B7DD8)
        }
        return .clear
    }
}
