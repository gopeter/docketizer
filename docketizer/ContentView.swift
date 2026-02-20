//
//  ContentView.swift
//  docketizer
//
//  Created by Peter Oesteritz on 01.04.25.
//

import DocketAPI
import Foundation
import SwiftDotenv
import SwiftUI

enum SidebarView {
    case list
    case recentTickets
    case assignedTickets
    case allProjects
    case projectTickets
}

enum FocusedField {
    case duration
    case ticket
    case description
}

struct ContentView: View {
    @State private var sidebarView: SidebarView = .list
    @State private var settings = Settings()

    @StateObject var viewModel: ContentViewModel

    @FocusState private var focusedField: FocusedField?

    init() {
        _viewModel = StateObject(wrappedValue: ContentViewModel())
    }

    var body: some View {
        let isSubmitButtonDisabled = viewModel.duration == "" || viewModel.getSelectedTicketId()[0] == nil

        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading) {
                Text("Add timetracking")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 5)

                Form {
                    TextField(
                        "Duration",
                        text: $viewModel.duration,
                        prompt: Text("2:30 or 2,5")
                    )
                    .textFieldStyle(.roundedBorder)
                    .padding(.bottom, 5)
                    .focused($focusedField, equals: .duration)

                    Picker("Ticket", selection: $viewModel.ticketView) {
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
                        Text("Foo")
                    } else {
                        Text("Bar")
                    }

                    TextField(
                        "Description",
                        text: $viewModel.description,
                        prompt: Text("What have you been working on?")
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .description)

                    Button("Add timetracking") {
                        viewModel.createTimetracking()
                        
                        viewModel.duration = ""
                        viewModel.description = ""
                        focusedField = .duration
                    }.buttonStyle(.borderedProminent).disabled(isSubmitButtonDisabled)
                }

                Spacer()

                Divider()

                HStack {
                    Button("Logout", systemImage: "door.left.hand.open") {
                        logout()
                    }.buttonStyle(.borderless)

                    Spacer()

                    Button("Quit", systemImage: "power") {
                        logout()
                    }.buttonStyle(.borderless)
                }
            }
            .padding(16)
            .frame(width: 340)

            VStack(alignment: .leading) {
                if sidebarView == .list {
                    timetrackingList
                } else if sidebarView == .recentTickets {
                    SearchableList(
                        items: viewModel.recentTicketsFiltered,
                        filter: viewModel.filterRecentTickets,
                        labelFormatter: ticketLabelFormatter,
                        select: selectRecentTicket,
                        close: close,
                        placeholder: "Search tickets",
                        defaultSelection: getSelectionIndex()
                    )
                }

                Spacer()
            }
            .padding(16)
            .frame(width: 300, alignment: .leading)
            .background(.black.opacity(0.2))
        }
        .onAppear {
            focusedField = .duration
        }
    }

    @ViewBuilder private func ticketLabelFormatter(for ticket: ViewerQuery.Data.Viewer.RecentlyTrackedTicket, isSelected: Bool) -> some View {
        Text("\(ticket.project.pnr) \(ticket.project.title)").font(.caption).foregroundStyle(.white.opacity(isSelected ? 0.7 : 0.5))
        Text(ticket.title).font(.callout)
    }
    
    private func getSelectionIndex() -> Int {
        for (index, ticket) in viewModel.recentTicketsFiltered.enumerated() where viewModel.ticketSelectionRecentlyId == ticket.id {
            return index
        }
        
        return 0
    }

    private func selectRecentTicket(ticket: ViewerQuery.Data.Viewer.RecentlyTrackedTicket) {
        viewModel.selectRecentTicket(ticket: ticket)
        sidebarView = .list
        focusedField = .description
    }

    private func close() {
        sidebarView = .list
        focusedField = .ticket
    }

    private func logout() {
        settings.apiKey = nil
        settings.tenant = nil
    }
}

extension ContentView {
    @ViewBuilder var timetrackingList: some View {
        if viewModel.timetrackings.count > 0 {
            HStack {
                Text("Timetrackings today")
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 5)

                Spacer()

                Text("\(TimeHelper.formatMinutesToHours(viewModel.timetrackings.reduce(0, { $0 + $1.duration }))) h").font(.callout)
                    .bold()
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 5)
                    .contentTransition(.numericText())
            }

            ScrollView {
                VStack {
                    ForEach(Array(viewModel.timetrackings.enumerated()), id: \.1.id) { index, timetracking in
                        HStack(alignment: .top) {
                            Text("#\(timetracking.ticket.number)")
                                .frame(width: 20, alignment: .leading)
                                .font(.callout)

                            VStack(alignment: .leading) {
                                Text("\(timetracking.project.pnr) \(timetracking.project.title)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(timetracking.ticket.title)
                                    .font(.callout)
                            }
                            
                            Spacer()
                            
                            Text("\(TimeHelper.formatMinutesToHours(timetracking.duration)) h")
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
                Text("Your tracked times for today will appear here")
            }
        }
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

        return ContentView().frame(width: 640, height: 300)
    }
}
