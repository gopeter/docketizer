// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class WeekTimetrackingsQuery: GraphQLQuery {
  public static let operationName: String = "WeekTimetrackings"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query WeekTimetrackings($dates: [String!]!) { viewer { __typename id timetrackings(filter: { dates: $dates }) { __typename nodes { __typename id duration date } } } }"#
    ))

  public var dates: [String]

  public init(dates: [String]) {
    self.dates = dates
  }

  public var __variables: Variables? { ["dates": dates] }

  public struct Data: DocketAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("viewer", Viewer.self),
    ] }

    public var viewer: Viewer { __data["viewer"] }

    /// Viewer
    ///
    /// Parent Type: `Viewer`
    public struct Viewer: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Viewer }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", DocketAPI.ID.self),
        .field("timetrackings", Timetrackings.self, arguments: ["filter": ["dates": .variable("dates")]]),
      ] }

      public var id: DocketAPI.ID { __data["id"] }
      public var timetrackings: Timetrackings { __data["timetrackings"] }

      /// Viewer.Timetrackings
      ///
      /// Parent Type: `TimetrackingConnection`
      public struct Timetrackings: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.TimetrackingConnection }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("nodes", [Node].self),
        ] }

        /// A list of nodes.
        public var nodes: [Node] { __data["nodes"] }

        /// Viewer.Timetrackings.Node
        ///
        /// Parent Type: `Timetracking`
        public struct Node: DocketAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Timetracking }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", DocketAPI.ID.self),
            .field("duration", Double.self),
            .field("date", DocketAPI.ISO8601Date.self),
          ] }

          public var id: DocketAPI.ID { __data["id"] }
          public var duration: Double { __data["duration"] }
          public var date: DocketAPI.ISO8601Date { __data["date"] }
        }
      }
    }
  }
}
