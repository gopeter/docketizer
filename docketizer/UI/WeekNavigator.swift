//
//  WeekNavigator.swift
//  docketizer
//
//  Created by Peter Oesteritz on 23.05.25.
//

import SwiftUI

struct WeekNavigator: View {
    @Binding var selectedDate: Date
    @State private var displayedWeekStart: Date
    @FocusState private var isFocused: Bool
    @FocusState private var isPrevFocused: Bool
    @FocusState private var isNextFocused: Bool

    private let calendar = Calendar.current

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._displayedWeekStart = State(initialValue: Self.weekStart(for: selectedDate.wrappedValue))
    }

    private var weekDates: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: displayedWeekStart) }
    }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                displayedWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedWeekStart)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 16, height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .focused($isPrevFocused)
            .focusEffectDisabled()
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.accentColor.opacity(isPrevFocused ? 0.8 : 0), lineWidth: 1.5)
            )

            HStack(spacing: 3) {
                ForEach(weekDates, id: \.self) { date in
                    DayBar(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        showFocusRing: isFocused && calendar.isDate(date, inSameDayAs: selectedDate)
                    )
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        selectedDate = date
                        displayedWeekStart = Self.weekStart(for: date)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .focusable()
            .focused($isFocused)
            .focusEffectDisabled()
            .onKeyPress(.leftArrow) {
                let newDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                selectedDate = newDate
                displayedWeekStart = Self.weekStart(for: newDate)
                return .handled
            }
            .onKeyPress(.rightArrow) {
                let newDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                selectedDate = newDate
                displayedWeekStart = Self.weekStart(for: newDate)
                return .handled
            }

            Button {
                displayedWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedWeekStart)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 16, height: 46)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .focused($isNextFocused)
            .focusEffectDisabled()
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.accentColor.opacity(isNextFocused ? 0.8 : 0), lineWidth: 1.5)
            )
        }
        .onChange(of: selectedDate) { _, newDate in
            // Sync the display when selectedDate changes externally (e.g. onCalendarDayChanged)
            let newWeekStart = Self.weekStart(for: newDate)
            if !calendar.isDate(newWeekStart, inSameDayAs: displayedWeekStart) {
                displayedWeekStart = newWeekStart
            }
        }
    }

    static func weekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromFirst = (weekday - calendar.firstWeekday + 7) % 7
        let startOfDay = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: -daysFromFirst, to: startOfDay)!
    }
}

// MARK: - Day bar

private struct DayBar: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    var showFocusRing: Bool = false

    private let dayAbbrevFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEEEE"
        return f
    }()

    private let dayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d.M"
        return f
    }()

    var body: some View {
        VStack(spacing: 3) {
            Text(dayAbbrevFormatter.string(from: date))
                .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .lineLimit(1)

            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(barFill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)

                if showFocusRing {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.primary.opacity(0.55), lineWidth: 1.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                }

                if isToday && !isSelected {
                    Circle()
                        .fill(Color.accentColor.opacity(0.7))
                        .frame(width: 4, height: 4)
                }
            }

            Text(dayMonthFormatter.string(from: date))
                .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var barFill: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor)
        } else if isToday {
            return AnyShapeStyle(Color.accentColor.opacity(0.18))
        } else {
            return AnyShapeStyle(Color.primary.opacity(0.07))
        }
    }
}
