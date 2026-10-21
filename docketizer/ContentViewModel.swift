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

// Keyed by "YYYY-MM-DD" → tracked minutes for that day
typealias DayDurations = [String: Double]

/// Tracked vs. required time for a single day.
struct DayProgress: Equatable {
    let trackedMinutes: Double
    let targetMinutes: Double

    /// A day without required hours (e.g. weekend, part-time day off).
    var isWorkFree: Bool { targetMinutes <= 0 }

    /// Fill level 0.0–1.0. On work-free days any tracked time counts as fully done.
    var fraction: Double {
        if isWorkFree {
            return trackedMinutes > 0 ? 1 : 0
        }
        return min(max(trackedMinutes / targetMinutes, 0), 1)
    }
}

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

    // Recently
    private var recentTickets: [ViewerQuery.Data.Viewer.RecentlyTrackedTicket] = []
    @Published var recentTicketsFiltered: [ViewerQuery.Data.Viewer.RecentlyTrackedTicket] = []

    // Assigned
    private var assignedTickets: [ViewerQuery.Data.Viewer.AssignedTickets.Node] = []
    @Published var assignedTicketsFiltered: [ViewerQuery.Data.Viewer.AssignedTickets.Node] = []

    // All – Projects
    private var projects: [ProjectsQuery.Data.Projects.Node] = []
    @Published var projectsFiltered: [ProjectsQuery.Data.Projects.Node] = []

    // All – Project Tickets
    private var projectTickets: [ProjectTicketsQuery.Data.Tickets.Node] = []
    @Published var projectTicketsFiltered: [ProjectTicketsQuery.Data.Tickets.Node] = []

    @Published var timetrackings: [ViewerQuery.Data.Viewer.Timetrackings.Node] = []
    @Published var errorMessage: String?

    @Published var isSubmitEnabled: Bool = true

    /// The stopwatch being booked through the form: saving the entry removes it on the server.
    @Published var bookingStopwatch: StopwatchFields? = nil

    // Weekly progress: "YYYY-MM-DD" → tracked vs. required time
    @Published var weekDayProgress: [String: DayProgress] = [:]

    private var currentUser: ViewerQuery.Data.Viewer? = nil
    private var weekDayDurations: DayDurations = [:]
    private var currentWeekDates: [String] = []
    // Week currently shown in the WeekNavigator
    private var displayedWeekStart: Date? = nil
    // "mon"/"tue"/… → hours; nil while not loaded or if the user has no work times configured
    private var workTimesPerDay: [String: Double]? = nil
    // Week start ("YYYY-MM-DD") the work times were requested for, to refetch on week change
    private var workTimesWeekKey: String? = nil
    private var cancellables = Set<AnyCancellable>()

    init() {
        queryTimetracking()
        queryProjects()

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

    // MARK: - Week progress helpers

    private func weekDates(for date: Date) -> [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromFirst = (weekday - calendar.firstWeekday + 7) % 7
        let weekStart = calendar.date(byAdding: .day, value: -daysFromFirst, to: calendar.startOfDay(for: date))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func weekDateStrings(for date: Date) -> [String] {
        weekDates(for: date).map { dateString(from: $0) }
    }

    private static let weekdayKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]

    private func workHours(for date: Date, in workTimes: [String: Double]) -> Double {
        let calendar = Calendar.current
        // Calendar.weekday: 1=Sun, 2=Mon, …, 7=Sat
        let weekday = calendar.component(.weekday, from: date)
        let key = Self.weekdayKeys[weekday - 1]
        return workTimes[key] ?? 0
    }

    private func recalculateWeekProgress() {
        // Without work times we can't tell work-free days from untracked ones – show nothing
        guard let workTimes = workTimesPerDay else {
            weekDayProgress = [:]
            return
        }

        var progress: [String: DayProgress] = [:]
        // Iterate the whole week (not only days with entries) so 0h days are known to the UI
        for dateStr in currentWeekDates {
            guard let date = date(from: dateStr) else { continue }
            progress[dateStr] = DayProgress(
                trackedMinutes: weekDayDurations[dateStr] ?? 0,
                targetMinutes: workHours(for: date, in: workTimes) * 60
            )
        }
        weekDayProgress = progress
    }

    private func dateString(from date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    private func date(from string: String) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var c = DateComponents()
        c.year = parts[0]
        c.month = parts[1]
        c.day = parts[2]
        return Calendar.current.date(from: c)
    }

    public func queryTimetracking(for date: Date? = nil) {
        let targetDate = date ?? selectedDate
        let formattedDate = dateString(from: targetDate)

        guard let client = Apollo.shared.client() else {
            self.errorMessage = "Authentication missing. Please log in again."
            return
        }

        client.fetch(query: ViewerQuery(date: formattedDate), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

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

                    if let assignedTicketNodes = graphQLResult.data?.viewer.assignedTickets.nodes {
                        self.assignedTickets = []
                        self.assignedTickets.append(contentsOf: assignedTicketNodes.compactMap({ $0 }))
                        self.filterAssignedTickets(by: "")
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

    /// Loads tracked durations (and work times) for the week starting at `weekStart`.
    /// Driven by the week shown in the WeekNavigator, independent of the selected day.
    public func queryWeekProgress(weekStart: Date) {
        let weekDates = weekDateStrings(for: weekStart)
        guard let firstDay = weekDates.first, let lastDay = weekDates.last else { return }
        displayedWeekStart = weekStart

        // The API ANDs all entries of the `dates` filter, so a list of single days matches nothing.
        // A range has to be expressed with comparison operators instead.
        let rangeFilter = [">=\(firstDay)", "<=\(lastDay)"]

        guard let client = Apollo.shared.client() else {
            self.errorMessage = "Authentication missing. Please log in again."
            return
        }

        client.fetch(query: WeekTimetrackingsQuery(dates: rangeFilter), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                // Ignore stale responses if the user already navigated to another week
                guard let shownWeek = self.displayedWeekStart, self.dateString(from: shownWeek) == self.dateString(from: weekStart)
                else { return }

                switch result {
                case .success(let graphQLResult):
                    if let viewer = graphQLResult.data?.viewer {
                        // Work times can differ over time (activeFrom), so fetch them per week
                        if self.workTimesWeekKey != firstDay {
                            self.workTimesWeekKey = firstDay
                            self.queryWorkTimes(userId: viewer.id, date: firstDay)
                        }

                        // Accumulate durations per day
                        var durations: DayDurations = [:]
                        for node in viewer.timetrackings.nodes {
                            durations[node.date, default: 0] += node.duration
                        }
                        self.weekDayDurations = durations
                        self.currentWeekDates = weekDates
                        self.recalculateWeekProgress()
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

    public func queryWorkTimes(userId: String, date: String) {
        guard let client = Apollo.shared.client() else { return }

        client.fetch(query: WorkTimesQuery(userId: userId, date: date), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                // Ignore stale responses if the week changed in the meantime
                guard self.workTimesWeekKey == date else { return }

                switch result {
                case .success(let graphQLResult):
                    if let workTime = graphQLResult.data?.users.nodes.first?.workTimes.nodes.first {
                        self.workTimesPerDay = [
                            "mon": workTime.mon,
                            "tue": workTime.tue,
                            "wed": workTime.wed,
                            "thu": workTime.thu,
                            "fri": workTime.fri,
                            "sat": workTime.sat,
                            "sun": workTime.sun,
                        ]
                    } else {
                        // No work times configured for this user/week
                        self.workTimesPerDay = nil
                    }
                    self.recalculateWeekProgress()

                    if let errors = graphQLResult.errors {
                        self.errorMessage = errors.map { $0.message! }.joined(separator: ", ")
                    }
                case .failure(let error):
                    // Allow a retry on the next week fetch
                    self.workTimesWeekKey = nil
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    public func queryProjects() {
        guard let client = Apollo.shared.client() else {
            self.errorMessage = "Authentication missing. Please log in again."
            return
        }

        client.fetch(query: ProjectsQuery(), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let graphQLResult):
                    if let projectNodes = graphQLResult.data?.projects.nodes {
                        self.projects = []
                        self.projects.append(contentsOf: projectNodes.compactMap({ $0 }))
                        self.filterProjects(by: "")
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

    public func queryProjectTickets(for projectId: String) {
        guard let client = Apollo.shared.client() else {
            self.errorMessage = "Authentication missing. Please log in again."
            return
        }

        client.fetch(query: ProjectTicketsQuery(projectId: projectId)) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let graphQLResult):
                    if let ticketNodes = graphQLResult.data?.tickets.nodes {
                        self.projectTickets = []
                        self.projectTickets.append(contentsOf: ticketNodes.compactMap({ $0 }))
                        self.filterProjectTickets(by: "")
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
            ticketId: GraphQLNullable.some(ids[0]!),
            stopwatchId: bookingStopwatch.map { GraphQLNullable.some($0.id) } ?? .none
        )
        let booksStopwatch = bookingStopwatch != nil

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
                    if booksStopwatch {
                        if let errors = graphQLResult.data?.createTimetracking?.errors?.messages, !errors.isEmpty {
                            self?.errorMessage = errors.joined(separator: ", ")
                        } else if graphQLResult.errors == nil {
                            self?.bookingStopwatch = nil
                        }
                        StopwatchStore.shared.refresh()
                    }
                    if let weekStart = self?.displayedWeekStart {
                        self?.queryWeekProgress(weekStart: weekStart)
                    }

                    if let errors = graphQLResult.errors {
                        self?.errorMessage = errors.map { $0.message! }.joined(separator: ", ")
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Stopwatch booking

    /// Fills the form from a stopwatch: its time rounded up to the next quarter hour, its title as
    /// the description (unless it's still a default "Stopwatch 3"), its ticket if it has one.
    public func prefill(from stopwatch: StopwatchFields) {
        bookingStopwatch = stopwatch
        duration = TimeHelper.formatMinutesToHours(Double(stopwatch.roundedMinutes))
        let isDefaultTitle = stopwatch.title.range(of: #"^Stopwatch \d+$"#, options: .regularExpression) != nil
        description = isDefaultTitle ? "" : stopwatch.title

        guard let ticket = stopwatch.ticket else { return }

        ticketView = .all
        if ticketSelectionAllProjectId != ticket.project.id {
            projectTickets = []
            projectTicketsFiltered = []
            queryProjectTickets(for: ticket.project.id)
        }
        ticketSelectionAllProjectId = ticket.project.id
        ticketSelectionAllProjectLabel = ticket.project.pnr + " " + ticket.project.title
        ticketSelectionAllTicketId = ticket.id
        ticketSelectionAllTicketLabel = ticket.project.pnr + " / " + ticket.title
    }

    public func cancelBooking() {
        bookingStopwatch = nil
        duration = ""
        description = ""
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

    // MARK: - Recently

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

    // MARK: - Assigned

    public func filterAssignedTickets(by searchText: String) {
        self.assignedTicketsFiltered = self.assignedTickets.compactMap { element in
            let haystack = "\(element.project.pnr) \(element.project.title) \(element.title)"
            if searchText == "" || haystack.lowercased().contains(searchText.lowercased()) {
                return element
            } else {
                return nil
            }
        }
    }

    public func selectAssignedTicket(ticket: ViewerQuery.Data.Viewer.AssignedTickets.Node) {
        ticketSelectionAssignedId = ticket.id
        ticketSelectionAssignedProjectId = ticket.project.id
        ticketSelectionAssignedLabel = ticket.project.pnr + " / " + ticket.title
    }

    // MARK: - All (Projects)

    public func filterProjects(by searchText: String) {
        self.projectsFiltered = self.projects.compactMap { element in
            let haystack = "\(element.pnr) \(element.title)"
            if searchText == "" || haystack.lowercased().contains(searchText.lowercased()) {
                return element
            } else {
                return nil
            }
        }
    }

    public func selectProject(project: ProjectsQuery.Data.Projects.Node) {
        // Reset ticket selection when project changes
        if ticketSelectionAllProjectId != project.id {
            ticketSelectionAllTicketId = nil
            ticketSelectionAllTicketLabel = nil
            projectTickets = []
            projectTicketsFiltered = []
        }

        ticketSelectionAllProjectId = project.id
        ticketSelectionAllProjectLabel = project.pnr + " " + project.title

        queryProjectTickets(for: project.id)

    }

    // MARK: - All (Project Tickets)

    public func filterProjectTickets(by searchText: String) {
        self.projectTicketsFiltered = self.projectTickets.compactMap { element in
            let haystack = "\(element.project.pnr) \(element.project.title) \(element.title)"
            if searchText == "" || haystack.lowercased().contains(searchText.lowercased()) {
                return element
            } else {
                return nil
            }
        }
    }

    public func selectProjectTicket(ticket: ProjectTicketsQuery.Data.Tickets.Node) {
        ticketSelectionAllTicketId = ticket.id
        ticketSelectionAllProjectId = ticket.project.id
        ticketSelectionAllTicketLabel = ticket.project.pnr + " / " + ticket.title
    }
}
