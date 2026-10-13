//
//  WeekNavigator.swift
//  docketizer
//
//  Created by Peter Oesteritz on 23.05.25.
//

import SwiftUI

struct WeekNavigator: View {
    @Binding var selectedDate: Date
    var weekDayProgress: [String: DayProgress] = [:]
    // Called with the first day of the shown week whenever it changes (incl. initially)
    var onWeekChange: ((Date) -> Void)? = nil
    @State private var displayedWeekStart: Date
    @FocusState private var isFocused: Bool
    @FocusState private var isPrevFocused: Bool
    @FocusState private var isNextFocused: Bool

    private let calendar = Calendar.current

    init(
        selectedDate: Binding<Date>,
        weekDayProgress: [String: DayProgress] = [:],
        onWeekChange: ((Date) -> Void)? = nil
    ) {
        self._selectedDate = selectedDate
        self._displayedWeekStart = State(initialValue: Self.weekStart(for: selectedDate.wrappedValue))
        self.weekDayProgress = weekDayProgress
        self.onWeekChange = onWeekChange
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
                    let dateKey = Self.dateString(from: date)
                    DayBar(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        showFocusRing: isFocused && calendar.isDate(date, inSameDayAs: selectedDate),
                        progress: weekDayProgress[dateKey]
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
        .onChange(of: displayedWeekStart, initial: true) { _, newWeekStart in
            onWeekChange?(newWeekStart)
        }
    }

    static func dateString(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
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
    // nil while work times are unknown – no progress is shown then
    var progress: DayProgress? = nil

    private var fraction: Double { progress?.fraction ?? 0 }
    private var isWorkFree: Bool { progress?.isWorkFree ?? false }
    private var isComplete: Bool { fraction >= 1 }

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
                // Base background
                RoundedRectangle(cornerRadius: 3)
                    .fill(barFill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)

                // Progress fill – grows from the bottom, capped at 100%
                if fraction > 0 {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressFill)
                            .frame(height: 22 * fraction)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }

                if showFocusRing {
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.primary.opacity(0.55), lineWidth: 1.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 22)
                }

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                } else if isToday && !isSelected {
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
            return AnyShapeStyle(Color.accentColor.opacity(isWorkFree ? 0.08 : 0.18))
        } else {
            // Work-free days (0h required) are rendered more subtle
            return AnyShapeStyle(Color.primary.opacity(isWorkFree ? 0.03 : 0.07))
        }
    }

    private var progressFill: AnyShapeStyle {
        if isComplete {
            // Required hours reached
            return AnyShapeStyle(Color.green.opacity(isSelected ? 0.85 : 0.7))
        } else if isSelected {
            return AnyShapeStyle(Color.white.opacity(0.35))
        } else {
            return AnyShapeStyle(Color.accentColor.opacity(0.5))
        }
    }
}
