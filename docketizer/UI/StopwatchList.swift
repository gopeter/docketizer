//
//  StopwatchList.swift
//  docketizer
//

import DocketAPI
import SwiftUI

/// The stopwatches above the day's time entries: start and pause them in parallel, click a title
/// to rename it, correct the time or discard it, and book one into the form on the left.
struct StopwatchList: View {
    @ObservedObject var store: StopwatchStore
    var book: (StopwatchFields) -> Void

    @State private var editing: DocketAPI.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Stopwatches")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    store.create()
                } label: {
                    Image(systemName: "plus")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("New stopwatch")
            }

            if let error = store.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !store.stopwatches.isEmpty {
                // Ticks once a second while one runs; otherwise there is nothing to redraw.
                TimelineView(.periodic(from: .now, by: store.hasRunning ? 1 : 3600)) { context in
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(store.stopwatches, id: \.id) { stopwatch in
                                row(stopwatch, now: context.date)
                            }
                        }
                    }
                    .frame(maxHeight: CGFloat(min(store.stopwatches.count, 3)) * 26)
                }
            }
        }
    }

    @ViewBuilder private func row(_ stopwatch: StopwatchFields, now: Date) -> some View {
        HStack(spacing: 8) {
            Button {
                editing = stopwatch.id
            } label: {
                Text(stopwatch.title)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Rename, correct the time or discard")
            .popover(
                isPresented: Binding(
                    get: { editing == stopwatch.id },
                    set: { if !$0 { editing = nil } }
                ),
                arrowEdge: .leading
            ) {
                StopwatchEditor(
                    store: store,
                    stopwatch: stopwatch,
                    book: {
                        editing = nil
                        book($0)
                    }
                )
            }

            Text(TimeHelper.formatClock(store.seconds(of: stopwatch, at: now)))
                .font(.callout.monospacedDigit())
                .foregroundStyle(stopwatch.running ? Color.accentColor : .secondary)

            Button {
                store.toggle(stopwatch)
            } label: {
                Image(systemName: stopwatch.running ? "pause.fill" : "play.fill")
                    .frame(width: 14)
            }
            .buttonStyle(.borderless)
            .help(stopwatch.running ? "Pause \(stopwatch.title)" : "Start \(stopwatch.title)")

            Button {
                book(stopwatch)
            } label: {
                Image(systemName: "checkmark.circle")
            }
            .buttonStyle(.borderless)
            .help("Book \(stopwatch.title)")
        }
        .frame(height: 24)
    }
}

/// Rename, correct the time, discard – or book.
struct StopwatchEditor: View {
    @ObservedObject var store: StopwatchStore
    let stopwatch: StopwatchFields
    var book: (StopwatchFields) -> Void

    @State private var title = ""
    @State private var time = ""
    @State private var initialTime = ""
    @State private var timeInvalid = false
    @State private var confirmDiscard = false
    @State private var booking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit { store.rename(stopwatch, to: title) }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Time", text: $time, prompt: Text("1:07:23"))
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospacedDigit())
                    .onSubmit(saveTime)

                if timeInvalid {
                    Text("Type a time like 1:07:23, 1:07 or 45 (minutes).")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text("Booking suggests \(TimeHelper.formatMinutesToHours(Double(stopwatch.roundedMinutes))) h")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                if confirmDiscard {
                    Button("Keep it") { confirmDiscard = false }
                    Button("Discard", role: .destructive) { store.discard(stopwatch) }
                } else {
                    Button("Discard…") { confirmDiscard = true }
                        .buttonStyle(.borderless)
                }

                Spacer()

                Button("Book…") {
                    booking = true
                    commit(then: book)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .frame(width: 240)
        .onAppear {
            title = stopwatch.title
            initialTime = TimeHelper.formatClock(store.seconds(of: stopwatch))
            time = initialTime
        }
        // Closing the popover keeps what was typed, like leaving a field in the web app.
        .onDisappear {
            if !booking { commit() }
        }
    }

    private func saveTime() {
        commit(renaming: false)
    }

    /// Saves the title and the time (in that order), then hands the updated stopwatch on.
    private func commit(renaming: Bool = true, then: StopwatchStore.Then? = nil) {
        var seconds: Int?
        if time != initialTime {
            guard let parsed = TimeHelper.parseClock(time) else {
                timeInvalid = true
                booking = false
                return
            }
            seconds = parsed
            timeInvalid = false
            initialTime = TimeHelper.formatClock(parsed)
            time = initialTime
        }

        let setTime: StopwatchStore.Then = { current in
            if let seconds {
                store.setSeconds(current, to: seconds, then: then)
            } else {
                then?(current)
            }
        }

        if renaming {
            store.rename(stopwatch, to: title, then: setTime)
        } else {
            setTime(stopwatch)
        }
    }
}
