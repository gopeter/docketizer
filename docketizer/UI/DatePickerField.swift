//
//  DatePickerField.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import SwiftUI

struct DatePickerField: View {
    @Binding var date: Date
    @State private var showCalendar = false

    @Environment(\.font) private var swiftUIFont
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            NativeDatePicker(date: $date, font: resolvedNSFont, color: .secondaryLabelColor)

            Button {
                showCalendar.toggle()
            } label: {
                Image(systemName: "calendar")
                    .padding(4)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .popover(isPresented: $showCalendar, arrowEdge: .bottom) {
                GraphicalDatePicker(date: $date, isPresented: $showCalendar)
                    .padding(12)
            }
        }
    }

    // Convert SwiftUI .callout + .bold to a matching NSFont
    private var resolvedNSFont: NSFont {
        let base = NSFont.preferredFont(forTextStyle: .callout)
        return NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask)
    }
}

// MARK: - NSDatePicker segment textfield

private struct NativeDatePicker: NSViewRepresentable {
    @Binding var date: Date
    var font: NSFont
    var color: NSColor

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .textField
        picker.datePickerElements = .yearMonthDay
        picker.locale = Locale.current
        picker.calendar = Calendar.current
        picker.dateValue = date
        picker.font = font
        picker.textColor = color
        picker.timeZone = .current
        picker.isBordered = false
        picker.isBezeled = false
        picker.drawsBackground = false
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        return picker
    }

    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        if !Calendar.current.isDate(nsView.dateValue, inSameDayAs: date) {
            nsView.dateValue = date
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSDatePicker, context: Context) -> CGSize? {
        nsView.fittingSize
    }

    class Coordinator: NSObject {
        var parent: NativeDatePicker
        init(_ parent: NativeDatePicker) { self.parent = parent }

        @objc func dateChanged(_ sender: NSDatePicker) {
            parent.date = sender.dateValue
        }
    }
}

// MARK: - Graphical calendar picker (shown in popover)

private struct GraphicalDatePicker: NSViewRepresentable {
    @Binding var date: Date
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .clockAndCalendar
        picker.datePickerElements = .yearMonthDay
        picker.dateValue = date
        picker.locale = Locale.current
        picker.calendar = Calendar.current
        picker.timeZone = .current
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        return picker
    }

    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        if !Calendar.current.isDate(nsView.dateValue, inSameDayAs: date) {
            nsView.dateValue = date
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSDatePicker, context: Context) -> CGSize? {
        nsView.fittingSize
    }

    class Coordinator: NSObject {
        var parent: GraphicalDatePicker
        init(_ parent: GraphicalDatePicker) { self.parent = parent }

        @objc func dateChanged(_ sender: NSDatePicker) {
            parent.date = sender.dateValue
            parent.isPresented = false
        }
    }
}
