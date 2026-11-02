//
//  ContentView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import AppKit
import DocketAPI
import Foundation
import SwiftDotenv
import SwiftUI

enum SidebarView {
    case list
    case recentTickets
    case assignedTickets
    case allProjects
    case allProjectTickets
}

enum FocusedField {
    case duration
    case ticket
    case description
}

struct ContentView: View {
    @State private var sidebarView: SidebarView = .list
    @State private var showDatePicker = false

    @Environment(\.openSettings) private var openSettings
    @ObservedObject private var updateReminder = UpdateReminder.shared
    @ObservedObject private var stopwatchStore = StopwatchStore.shared

    @StateObject var viewModel: ContentViewModel

    @FocusState private var focusedField: FocusedField?

    init() {
        _viewModel = StateObject(wrappedValue: ContentViewModel())
    }

    var body: some View {
        let isSubmitButtonDisabled = viewModel.duration == "" || viewModel.getSelectedTicketId()[0] == nil

        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                WeekNavigator(
                    selectedDate: $viewModel.selectedDate,
                    weekDayProgress: viewModel.weekDayProgress,
                    onWeekChange: { viewModel.queryWeekProgress(weekStart: $0) }
                )
                    .padding(.bottom, 16)

                Form {
                    TextField(
                        "Duration",
                        text: $viewModel.duration,
                        prompt: Text("2:30 or 2,5")
                    )
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 5)
                    .focused($focusedField, equals: .duration)

                    Picker("Ticket", selection: $viewModel.ticketView.deferred()) {
                        Text("Recently").tag(TicketView.recently)
                        Text("Assigned").tag(TicketView.assigned)
                        Text("All").tag(TicketView.all)
                    }.pickerStyle(.segmented)

                    if viewModel.ticketView.hashValue == TicketView.recently.hashValue {
                        Button {
                            if sidebarView == .recentTickets {
                                sidebarView = .list
                            } else {
                                sidebarView = .recentTickets
                            }
                        } label: {
                            HStack {
                                Text(viewModel.ticketSelectionRecentlyLabel ?? "Select ticket")
                                Spacer()
                                Image(systemName: "chevron.right.square.fill").symbolRenderingMode(.hierarchical)
                            }
                        }
                        .overlay(
                            sidebarView == .recentTickets ? RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor, lineWidth: 2) : nil
                        )
                        .focused($focusedField, equals: .ticket)

                    } else if viewModel.ticketView.hashValue == TicketView.assigned.hashValue {
                        Button {
                            if sidebarView == .assignedTickets {
                                sidebarView = .list
                            } else {
                                sidebarView = .assignedTickets
                            }
                        } label: {
                            HStack {
                                Text(viewModel.ticketSelectionAssignedLabel ?? "Select ticket")
                                Spacer()
                                Image(systemName: "chevron.right.square.fill").symbolRenderingMode(.hierarchical)
                            }
                        }
                        .overlay(
                            sidebarView == .assignedTickets ? RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor, lineWidth: 2) : nil
                        )
                        .focused($focusedField, equals: .ticket)

                    } else {
                        // All: two-step – project first, then ticket
                        VStack(spacing: 6) {
                            Button {
                                if sidebarView == .allProjects {
                                    sidebarView = .list
                                } else {
                                    sidebarView = .allProjects
                                    // reset to project list when re-opening
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.ticketSelectionAllProjectLabel ?? "Select project")
                                    Spacer()
                                    Image(systemName: "chevron.right.square.fill").symbolRenderingMode(.hierarchical)
                                }
                            }
                            .overlay(
                                sidebarView == .allProjects ? RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor, lineWidth: 2) : nil
                            )

                            Button {
                                guard viewModel.ticketSelectionAllProjectId != nil else { return }
                                if sidebarView == .allProjectTickets {
                                    sidebarView = .list
                                } else {
                                    sidebarView = .allProjectTickets
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.ticketSelectionAllTicketLabel ?? "Select ticket")
                                        .foregroundStyle(viewModel.ticketSelectionAllProjectId == nil ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.right.square.fill")
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundStyle(viewModel.ticketSelectionAllProjectId == nil ? .secondary : .primary)
                                }
                            }
                            .disabled(viewModel.ticketSelectionAllProjectId == nil)
                            .overlay(
                                sidebarView == .allProjectTickets ? RoundedRectangle(cornerRadius: 4).stroke(Color.accentColor, lineWidth: 2) : nil
                            )
                            .focused($focusedField, equals: .ticket)
                        }
                    }

                    TextField(
                        "Description",
                        text: $viewModel.description,
                        prompt: Text("What have you been working on?")
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .description)

                    if let stopwatch = viewModel.bookingStopwatch {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(stopwatch.title) ran \(TimeHelper.formatClock(stopwatch.seconds)), rounded up to the next quarter hour")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                viewModel.cancelBooking()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Don't book the stopwatch")
                        }
                    }

                    Button(viewModel.bookingStopwatch == nil ? "Add timetracking" : "Book stopwatch") {
                        viewModel.createTimetracking()

                        viewModel.duration = ""
                        viewModel.description = ""
                        focusedField = .duration
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSubmitButtonDisabled)
                }

                Spacer()

                Divider()

                HStack {

                    Button("Logout", systemImage: "door.left.hand.open") {
                        logout()
                    }.buttonStyle(.borderless)

                    Spacer()

                    if let version = updateReminder.pendingUpdateVersion {
                        Button("Update \(version)", systemImage: "arrow.down.circle.fill") {
                            updateReminder.showUpdate()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(Color.accentColor)
                        .help("A new version of docketizer is available")
                    }

                    Button {
                        openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                    }.buttonStyle(.borderless)

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Image(systemName: "power")
                    }.buttonStyle(.borderless)
                }.padding(.top, 10)

            }
            .padding(16)
            .frame(width: 340, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading) {
                if sidebarView == .list {
                    StopwatchList(store: stopwatchStore, book: book)
                        .padding(.bottom, 12)

                    timetrackingList

                } else if sidebarView == .recentTickets {
                    SearchableList(
                        items: viewModel.recentTicketsFiltered,
                        filter: viewModel.filterRecentTickets,
                        labelFormatter: recentTicketLabelFormatter,
                        select: selectRecentTicket,
                        close: close,
                        placeholder: "Search tickets",
                        defaultSelection: getRecentSelectionIndex()
                    )

                } else if sidebarView == .assignedTickets {
                    SearchableList(
                        items: viewModel.assignedTicketsFiltered,
                        filter: viewModel.filterAssignedTickets,
                        labelFormatter: assignedTicketLabelFormatter,
                        select: selectAssignedTicket,
                        close: close,
                        placeholder: "Search tickets",
                        defaultSelection: getAssignedSelectionIndex()
                    )

                } else if sidebarView == .allProjects {
                    SearchableList(
                        items: viewModel.projectsFiltered,
                        filter: viewModel.filterProjects,
                        labelFormatter: projectLabelFormatter,
                        select: selectProject,
                        close: close,
                        placeholder: "Search projects",
                        defaultSelection: getAllProjectSelectionIndex()
                    )

                } else if sidebarView == .allProjectTickets {
                    SearchableList(
                        items: viewModel.projectTicketsFiltered,
                        filter: viewModel.filterProjectTickets,
                        labelFormatter: projectTicketLabelFormatter,
                        select: selectProjectTicket,
                        close: close,
                        placeholder: "Search tickets",
                        defaultSelection: getAllTicketSelectionIndex()
                    )
                }

                Spacer()
            }
            .padding(16)
            .frame(width: 300, alignment: .leading)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(.black.opacity(0.2))
        }
        .frame(maxHeight: .infinity)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            focusedField = .duration
            viewModel.queryTimetracking()
            viewModel.queryProjects()
            stopwatchStore.startPolling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            stopwatchStore.stopPolling()
        }
        .onCalendarDayChanged {
            viewModel.selectedDate = Date()
        }
    }

    // MARK: - Label Formatters

    @ViewBuilder private func recentTicketLabelFormatter(for ticket: ViewerQuery.Data.Viewer.RecentlyTrackedTicket, isSelected: Bool) -> some View {
        Text("\(ticket.project.pnr) \(ticket.project.title)").font(.caption).foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.5))
        Text(ticket.title).font(.callout)
    }

    @ViewBuilder private func assignedTicketLabelFormatter(for ticket: ViewerQuery.Data.Viewer.AssignedTickets.Node, isSelected: Bool) -> some View {
        Text("\(ticket.project.pnr) \(ticket.project.title)").font(.caption).foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.5))
        Text(ticket.title).font(.callout)
    }

    @ViewBuilder private func projectLabelFormatter(for project: ProjectsQuery.Data.Projects.Node, isSelected: Bool) -> some View {
        Text(project.pnr).font(.caption).foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.5))
        Text(project.title).font(.callout)
    }

    @ViewBuilder private func projectTicketLabelFormatter(for ticket: ProjectTicketsQuery.Data.Tickets.Node, isSelected: Bool) -> some View {
        Text("\(ticket.project.pnr) \(ticket.project.title)").font(.caption).foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.5))
        Text(ticket.title).font(.callout)
    }

    // MARK: - Default Selection Indices

    private func getRecentSelectionIndex() -> Int {
        for (index, ticket) in viewModel.recentTicketsFiltered.enumerated() where viewModel.ticketSelectionRecentlyId == ticket.id {
            return index
        }
        return 0
    }

    private func getAssignedSelectionIndex() -> Int {
        for (index, ticket) in viewModel.assignedTicketsFiltered.enumerated() where viewModel.ticketSelectionAssignedId == ticket.id {
            return index
        }
        return 0
    }

    private func getAllProjectSelectionIndex() -> Int {
        for (index, project) in viewModel.projectsFiltered.enumerated() where viewModel.ticketSelectionAllProjectId == project.id {
            return index
        }
        return 0
    }

    private func getAllTicketSelectionIndex() -> Int {
        for (index, ticket) in viewModel.projectTicketsFiltered.enumerated() where viewModel.ticketSelectionAllTicketId == ticket.id {
            return index
        }
        return 0
    }

    // MARK: - Selection Handlers

    private func selectRecentTicket(ticket: ViewerQuery.Data.Viewer.RecentlyTrackedTicket) {
        viewModel.selectRecentTicket(ticket: ticket)
        sidebarView = .list
        focusedField = .description
    }

    private func selectAssignedTicket(ticket: ViewerQuery.Data.Viewer.AssignedTickets.Node) {
        viewModel.selectAssignedTicket(ticket: ticket)
        sidebarView = .list
        focusedField = .description
    }

    private func selectProject(project: ProjectsQuery.Data.Projects.Node) {
        viewModel.selectProject(project: project)
        sidebarView = .allProjectTickets
        focusedField = nil
    }

    private func selectProjectTicket(ticket: ProjectTicketsQuery.Data.Tickets.Node) {
        viewModel.selectProjectTicket(ticket: ticket)
        sidebarView = .list
        focusedField = .description
    }

    /// Pauses the stopwatch, then fills the form with it – the ticket can still be picked there.
    private func book(_ stopwatch: StopwatchFields) {
        stopwatchStore.pause(stopwatch) { paused in
            viewModel.prefill(from: paused)
            sidebarView = .list
            focusedField = paused.ticket == nil ? .ticket : .description
        }
    }

    private func close() {
        sidebarView = .list
        focusedField = .ticket
    }

    private func logout() {
        AuthManager.shared.logout()
    }
}

extension ContentView {
    @ViewBuilder var timetrackingList: some View {
        if viewModel.timetrackings.count > 0 {
            HStack {
                Text("Timetrackings")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 5)

                Button {
                    openWebInterface()
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 5)

                Spacer()

                Text("\(TimeHelper.formatMinutesToHours(viewModel.timetrackings.reduce(0, { $0 + $1.duration }))) h").font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 5)
                    .contentTransition(.numericText())
            }

            ScrollView {
                VStack {
                    ForEach(Array(viewModel.timetrackings.enumerated()), id: \.1.id) { index, timetracking in
                        HStack(alignment: .top) {
                            // Never wraps ("#12" broke into "#1"/"2" at a fixed 20pt); the minimum
                            // width keeps the titles aligned for numbers up to three digits.
                            Text("#\(timetracking.ticket.number)")
                                .font(.callout)
                                .monospacedDigit()
                                .lineLimit(1)
                                .fixedSize()
                                .frame(minWidth: 34, alignment: .leading)

                            VStack(alignment: .leading) {
                                Text("\(timetracking.project.pnr) \(timetracking.project.title)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(timetracking.ticket.title)
                                    .font(.callout)
                                if let description = timetracking.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }

                            Spacer()

                            Text("\(TimeHelper.formatMinutesToHours(timetracking.duration)) h")
                                .font(.callout)
                        }

                        if index < viewModel.timetrackings.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(.quinary)
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
        } else {
            Spacer()

            ContentUnavailableView {
                Label("No Trackings", systemImage: "tray.fill").font(.title3)
            } description: {
                Text("No tracked times for this date")
            }
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func openWebInterface() {
        let domain = DocketServer.domain
        guard
            let tenant = UserDefaults.standard.string(forKey: "tenant"),
            let url = URL(string: "https://\(tenant).\(domain)/timetracking")
        else { return }

        NSWorkspace.shared.open(url)
    }
}

#Preview {
    do {
        guard let envFile = Bundle.main.url(forResource: "development", withExtension: "env") else {
            return Text("Please create an development.env file")
        }

        try Dotenv.configure(atPath: envFile.path(), overwrite: false)
    } catch let error {
        print(error.localizedDescription)
    }

    if Dotenv["DOCKET_API_KEY"]?.stringValue == nil || Dotenv["DOCKET_TENANT"]?.stringValue == nil {
        return Text("Please add DOCKET_API_KEY and DOCKET_TENANT to your development.env")
    } else {
        UserDefaults.standard.set(Dotenv["DOCKET_API_KEY"]!.stringValue, forKey: "apiKey")
        UserDefaults.standard.set(Dotenv["DOCKET_TENANT"]!.stringValue, forKey: "tenant")

        return ContentView().frame(width: 640, height: 340)
    }
}
