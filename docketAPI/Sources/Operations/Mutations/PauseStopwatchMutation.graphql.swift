// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class PauseStopwatchMutation: GraphQLMutation {
  public static let operationName: String = "PauseStopwatch"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation PauseStopwatch($input: PauseStopwatchInput!) { pauseStopwatch(input: $input) { __typename stopwatches { __typename ...StopwatchFields } errors } }"#,
      fragments: [StopwatchFields.self]
    ))

  public var input: PauseStopwatchInput

  public init(input: PauseStopwatchInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: DocketAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("pauseStopwatch", PauseStopwatch?.self, arguments: ["input": .variable("input")]),
    ] }

    public var pauseStopwatch: PauseStopwatch? { __data["pauseStopwatch"] }

    /// PauseStopwatch
    ///
    /// Parent Type: `PauseStopwatchPayload`
    public struct PauseStopwatch: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.PauseStopwatchPayload }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("stopwatches", [Stopwatch].self),
        .field("errors", DocketAPI.Json?.self),
      ] }

      public var stopwatches: [Stopwatch] { __data["stopwatches"] }
      public var errors: DocketAPI.Json? { __data["errors"] }

      /// PauseStopwatch.Stopwatch
      ///
      /// Parent Type: `Stopwatch`
      public struct Stopwatch: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Stopwatch }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(StopwatchFields.self),
        ] }

        public var id: DocketAPI.ID { __data["id"] }
        public var title: String { __data["title"] }
        public var running: Bool { __data["running"] }
        /// Time on the clock right now, in seconds
        public var seconds: Int { __data["seconds"] }
        /// What booking it suggests: rounded up to the next full 15 minutes
        public var roundedMinutes: Int { __data["roundedMinutes"] }
        /// Optional — can also be picked when booking
        public var ticket: Ticket? { __data["ticket"] }

        public struct Fragments: FragmentContainer {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public var stopwatchFields: StopwatchFields { _toFragment() }
        }

        public typealias Ticket = StopwatchFields.Ticket
      }
    }
  }
}
