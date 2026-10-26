//
//  StopwatchStore.swift
//  docketizer
//

import Apollo
import DocketAPI
import Foundation

/// The user's stopwatches. They live on the server, so the web app, this app and AI connections
/// share them: a stopwatch started in the browser runs here too. There is no websocket in this app,
/// so the list is fetched when the popover opens and every 30 seconds while it stays open; the
/// clock itself ticks locally from the last fetch (`seconds(of:at:)`).
class StopwatchStore: ObservableObject {
    typealias Then = (StopwatchFields) -> Void

    static let shared = StopwatchStore()

    @Published private(set) var stopwatches: [StopwatchFields] = []
    @Published var errorMessage: String?

    /// When `stopwatches` came from the server – a running clock counts on from here.
    private var receivedAt = Date()
    private var pollTimer: Timer?

    var hasRunning: Bool { stopwatches.contains { $0.running } }

    /// The time on a stopwatch's clock at `now`.
    func seconds(of stopwatch: StopwatchFields, at now: Date = Date()) -> Int {
        guard stopwatch.running else { return stopwatch.seconds }
        return stopwatch.seconds + max(Int(now.timeIntervalSince(receivedAt)), 0)
    }

    // MARK: - Polling

    func startPolling() {
        refresh()
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func refresh() {
        guard let client = Apollo.shared.client() else { return }

        client.fetch(query: StopwatchesQuery(), cachePolicy: .fetchIgnoringCacheData) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let graphQLResult):
                    if let stopwatches = graphQLResult.data?.stopwatches {
                        self.replace(with: stopwatches.map(\.fragments.stopwatchFields))
                    }
                    if let errors = graphQLResult.errors {
                        self.errorMessage = errors.map { $0.message ?? "" }.joined(separator: ", ")
                    } else {
                        // A poll that gets through clears what an earlier one left behind, e.g. the
                        // offline message once the connection is back.
                        self.errorMessage = nil
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Mutations
    //
    // Each returns the user's full list, so the store simply replaces it.

    func create() {
        perform(CreateStopwatchMutation(input: CreateStopwatchInput())) {
            ($0.createStopwatch?.stopwatches.map(\.fragments.stopwatchFields), $0.createStopwatch?.errors?.messages)
        }
    }

    func toggle(_ stopwatch: StopwatchFields) {
        if stopwatch.running {
            perform(PauseStopwatchMutation(input: PauseStopwatchInput(id: stopwatch.id))) {
                ($0.pauseStopwatch?.stopwatches.map(\.fragments.stopwatchFields), $0.pauseStopwatch?.errors?.messages)
            }
        } else {
            perform(StartStopwatchMutation(input: StartStopwatchInput(id: stopwatch.id))) {
                ($0.startStopwatch?.stopwatches.map(\.fragments.stopwatchFields), $0.startStopwatch?.errors?.messages)
            }
        }
    }

    /// Pauses a running stopwatch – before booking, so the clock stops at what gets booked.
    func pause(_ stopwatch: StopwatchFields, then: Then? = nil) {
        guard stopwatch.running else { return finish(stopwatch, then) }

        perform(PauseStopwatchMutation(input: PauseStopwatchInput(id: stopwatch.id)), id: stopwatch.id, then: then) {
            ($0.pauseStopwatch?.stopwatches.map(\.fragments.stopwatchFields), $0.pauseStopwatch?.errors?.messages)
        }
    }

    func rename(_ stopwatch: StopwatchFields, to title: String, then: Then? = nil) {
        let title = title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, title != stopwatch.title else { return finish(stopwatch, then) }

        update(UpdateStopwatchInput(id: stopwatch.id, title: .some(title)), then: then)
    }

    func setSeconds(_ stopwatch: StopwatchFields, to seconds: Int, then: Then? = nil) {
        update(UpdateStopwatchInput(id: stopwatch.id, seconds: .some(seconds)), then: then)
    }

    func discard(_ stopwatch: StopwatchFields) {
        perform(DeleteStopwatchMutation(input: DeleteStopwatchInput(id: stopwatch.id))) {
            ($0.deleteStopwatch?.stopwatches.map(\.fragments.stopwatchFields), $0.deleteStopwatch?.errors?.messages)
        }
    }

    private func update(_ input: UpdateStopwatchInput, then: Then?) {
        perform(UpdateStopwatchMutation(input: input), id: input.id, then: then) {
            ($0.updateStopwatch?.stopwatches.map(\.fragments.stopwatchFields), $0.updateStopwatch?.errors?.messages)
        }
    }

    /// Hands the stopwatch as it is now on to the next step.
    private func finish(_ stopwatch: StopwatchFields, _ then: Then?) {
        then?(stopwatches.first { $0.id == stopwatch.id } ?? stopwatch)
    }

    /// Runs a mutation and takes the list it returns. `then` gets the stopwatch `id` from that
    /// list – so steps that depend on each other (rename, correct the time, pause, book) run in
    /// order instead of racing.
    private func perform<M: GraphQLMutation>(
        _ mutation: M,
        id: DocketAPI.ID? = nil,
        then: Then? = nil,
        payload: @escaping (M.Data) -> ([StopwatchFields]?, [String]?)
    ) {
        guard let client = Apollo.shared.client() else {
            errorMessage = "Authentication missing. Please log in again."
            return
        }

        client.perform(mutation: mutation) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let graphQLResult):
                    guard let data = graphQLResult.data else {
                        self.errorMessage = graphQLResult.errors?.map { $0.message ?? "" }.joined(separator: ", ")
                        return
                    }
                    let (stopwatches, errors) = payload(data)
                    if let errors, !errors.isEmpty {
                        self.errorMessage = errors.joined(separator: ", ")
                    } else if let stopwatches {
                        self.errorMessage = nil
                        self.replace(with: stopwatches)
                        if let then, let fresh = stopwatches.first(where: { $0.id == id }) {
                            then(fresh)
                        }
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func replace(with stopwatches: [StopwatchFields]) {
        receivedAt = Date()
        self.stopwatches = stopwatches
    }
}
