//
//  ContentViewModel.swift
//  docketizer
//
//  Created by Peter Oesteritz on 02.04.25.
//

import Apollo
import Combine
import DocketAPI
import Foundation

enum TicketView {
    case recently
    case assigned
    case all
}

class ContentViewModel: ObservableObject {
    @Published var ticketView: TicketView = .recently

    @Published var selectedDate: Date = Date()

    @Published var duration: String = ""
    @Published var description: String = ""

    // we want to hold the state for all ticket selection options to not loose it if the user switches between recently, assigned and all
    @Published var ticketSelectionRecentlyId: String? = nil
    @Published var ticketSelectionRecentlyProjectId: String? = nil
    @Published var ticketSelectionRecentlyLabel: String? = nil

    @Published var ticketSelectionAssignedId: String? = nil
    @Published var ticketSelectionAssignedProjectId: String? = nil
    @Published var ticketSelectionAssignedLabel: String? = nil

    @Published var ticketSelectionAllProjectId: String? = nil
    @Published var ticketSelectionAllProjectLabel: String? = nil

    @Published var ticketSelectionAllTicketId: String? = nil
    @Published var ticketSelectionAllTicketLabel: String? = nil

    private var recentTickets: [ViewerQuery.Data.Viewer.RecentlyTrackedTicket] = []
    @Published var recentTicketsFiltered: [ViewerQuery.Data.Viewer.RecentlyTrackedTicket] = []

    @Published var timetrackings: [ViewerQuery.Data.Viewer.Timetrackings.Node] = []
    @Published var errorMessage: String?

    @Published var isSubmitEnabled: Bool = true

    private var currentUser: ViewerQuery.Data.Viewer? = nil
    private var cancellables = Set<AnyCancellable>()

    init() {
        queryTimetracking()

        // Watch for date changes and reload timetracking
        // Note: @Published fires with willSet semantics, so self.selectedDate is still
        // the OLD value inside the sink – we must use the new value passed as the argument.
        $selectedDate
            .dropFirst()  // Skip initial value
            .sink { [weak self] newDate in
                // Defer to next run loop cycle to avoid "publishing changes from within
                // view updates" – @Published fires synchronously during willSet, which
                // happens inside a SwiftUI view update when the binding is written.
                DispatchQueue.main.async {
                    self?.queryTimetracking(for: newDate)
                }
            }
            .store(in: &cancellables)
    }

    public func queryTimetracking(for date: Date? = nil) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date ?? selectedDate)
        let formattedDate = String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)

        guard let client = Apollo.shared.client() else {
            self.errorMessage = "Authentication missing. Please log in again."
            return
        }

        client.fetch(query: ViewerQuery(date: formattedDate)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }

                switch result {
                case .success(let graphQLResult):
                    if let viewer = graphQLResult.data?.viewer {
                        self.currentUser = viewer
                    }

                    if let timetrackingNodes = graphQLResult.data?.viewer.timetrackings.nodes {
                        self.timetrackings = []
                        self.timetrackings.append(contentsOf: timetrackingNodes.compactMap({ $0 }))
                    }

                    if let recentTickets = graphQLResult.data?.viewer.recentlyTrackedTickets {
                        self.recentTickets = []
                        self.recentTickets.append(contentsOf: recentTickets.compactMap({ $0 }))
                        self.filterRecentTickets(by: "")
                    }

                    if let errors = graphQLResult.errors {
                        self.errorMessage = errors.map { $0.message! }.joined(separator: ", ")
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    public func createTimetracking() {
        let ids = getSelectedTicketId()

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let formattedDate = String(format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)

        let createTimetrackingInput = CreateTimetrackingInput(
            duration: GraphQLNullable.some(Double(TimeHelper.formatHoursToMinutes(duration))),
            date: GraphQLNullable.some(formattedDate),
            description: GraphQLNullable.some(description),
            userId: currentUser?.id ?? nil,
            serviceId: currentUser?.expertise?.id ?? nil,
            projectId: GraphQLNullable.some(ids[1]!),
            ticketId: GraphQLNullable.some(ids[0]!)
        )

        guard let client = Apollo.shared.client() else {
            self.errorMessage = "Authentication missing. Please log in again."
            self.isSubmitEnabled = true
            return
        }

        client.perform(mutation: CreateTimetrackingMutation(input: createTimetrackingInput)) { [weak self] result in
            DispatchQueue.main.async {
                defer {
                    self?.isSubmitEnabled = true
                }

                switch result {
                case .success(let graphQLResult):
                    self?.queryTimetracking()

                    if let errors = graphQLResult.errors {
                        self?.errorMessage = errors.map { $0.message! }.joined(separator: ", ")
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    public func getSelectedTicketId() -> [String?] {
        if ticketView == .recently {
            return [ticketSelectionRecentlyId, ticketSelectionRecentlyProjectId]
        } else if ticketView == .assigned {
            return [ticketSelectionAssignedId, ticketSelectionAssignedProjectId]
        } else {
            return [ticketSelectionAllTicketId, ticketSelectionAllProjectId]
        }
    }

    public func filterRecentTickets(by searchText: String) {
        self.recentTicketsFiltered = self.recentTickets.enumerated().compactMap { index, element in
            let haystack = "\(element.project.pnr) \(element.project.title) \(element.title)"
            if searchText == "" || (searchText != "" && haystack.lowercased().contains(searchText.lowercased())) {
                return element
            } else {
                return nil
            }
        }
    }

    public func selectRecentTicket(ticket: ViewerQuery.Data.Viewer.RecentlyTrackedTicket) {
        ticketSelectionRecentlyId = ticket.id
        ticketSelectionRecentlyProjectId = ticket.project.id
        ticketSelectionRecentlyLabel = ticket.project.pnr + " / " + ticket.title
    }

}
