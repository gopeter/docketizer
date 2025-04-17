//
//  ContentViewModel.swift
//  docketizer
//
//  Created by Peter Oesteritz on 02.04.25.
//

import Apollo
import DocketAPI
import Foundation

enum TicketView {
    case recently
    case assigned
    case all
}

class ContentViewModel: ObservableObject {
    @Published var ticketView: TicketView = .recently

    @Published var duration: String = ""
    @Published var description: String = ""

    // we want to hold the state for all ticket selection options to not loose it if the user switches between recently, assigned and all
    @Published private var ticketSelectionRecentlyId: String? = nil
    @Published private var ticketSelectionRecentlyProjectId: String? = nil
    @Published var ticketSelectionRecentlyLabel: String? = nil

    @Published private var ticketSelectionAssignedId: String? = nil
    @Published private var ticketSelectionAssignedProjectId: String? = nil
    @Published var ticketSelectionAssignedLabel: String? = nil

    @Published private var ticketSelectionAllProjectId: String? = nil
    @Published var ticketSelectionAllProjectLabel: String? = nil

    @Published private var ticketSelectionAllTicketId: String? = nil
    @Published var ticketSelectionAllTicketLabel: String? = nil

    private var recentTickets: [ViewerQuery.Data.Viewer.RecentlyTrackedTicket] = []
    @Published var recentTicketsFiltered: [ViewerQuery.Data.Viewer.RecentlyTrackedTicket] = []

    @Published var timetrackings: [ViewerQuery.Data.Viewer.Timetrackings.Node] = []
    @Published var errorMessage: String?

    @Published var isSubmitEnabled: Bool = true

    private var currentUser: ViewerQuery.Data.Viewer? = nil

    init() {
        queryTimetracking()
    }

    public func queryTimetracking() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let currentDate = Date()
        let formattedDate = dateFormatter.string(from: currentDate)

        Apollo.shared.client().fetch(query: ViewerQuery(date: formattedDate)) { [weak self] result in
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

    public func createTimetracking() {
        let ids = getSelectedTicketId()
        let createTimetrackingInput = CreateTimetrackingInput(
            duration: GraphQLNullable.some(Double(TimeHelper.formatHoursToMinutes(duration))),
            date: "2025-04-17",
            description: GraphQLNullable.some(description),
            userId: currentUser?.id ?? nil,
            serviceId: currentUser?.expertise?.id ?? nil,
            projectId: GraphQLNullable.some(ids[1]!),
            ticketId: GraphQLNullable.some(ids[0]!)
        )

        Apollo.shared.client().perform(mutation: CreateTimetrackingMutation(input: createTimetrackingInput)) { [weak self] result in
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
