// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class WorkTimesQuery: GraphQLQuery {
  public static let operationName: String = "WorkTimes"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query WorkTimes($userId: ID!, $date: ISO8601Date!) { users(filter: { ids: [$userId] }) { __typename nodes { __typename workTimes(first: 1, filter: { date: $date }) { __typename nodes { __typename mon tue wed thu fri sat sun } } } } }"#
    ))

  public var userId: ID
  public var date: ISO8601Date

  public init(
    userId: ID,
    date: ISO8601Date
  ) {
    self.userId = userId
    self.date = date
  }

  public var __variables: Variables? { [
    "userId": userId,
    "date": date
  ] }

  public struct Data: DocketAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("users", Users.self, arguments: ["filter": ["ids": [.variable("userId")]]]),
    ] }

    public var users: Users { __data["users"] }

    /// Users
    ///
    /// Parent Type: `UserConnection`
    public struct Users: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.UserConnection }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("nodes", [Node].self),
      ] }

      /// A list of nodes.
      public var nodes: [Node] { __data["nodes"] }

      /// Users.Node
      ///
      /// Parent Type: `User`
      public struct Node: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.User }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("workTimes", WorkTimes.self, arguments: [
            "first": 1,
            "filter": ["date": .variable("date")]
          ]),
        ] }

        public var workTimes: WorkTimes { __data["workTimes"] }

        /// Users.Node.WorkTimes
        ///
        /// Parent Type: `UserWorkTimeConnection`
        public struct WorkTimes: DocketAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.UserWorkTimeConnection }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("nodes", [Node].self),
          ] }

          /// A list of nodes.
          public var nodes: [Node] { __data["nodes"] }

          /// Users.Node.WorkTimes.Node
          ///
          /// Parent Type: `UserWorkTime`
          public struct Node: DocketAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.UserWorkTime }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("mon", Double.self),
              .field("tue", Double.self),
              .field("wed", Double.self),
              .field("thu", Double.self),
              .field("fri", Double.self),
              .field("sat", Double.self),
              .field("sun", Double.self),
            ] }

            public var mon: Double { __data["mon"] }
            public var tue: Double { __data["tue"] }
            public var wed: Double { __data["wed"] }
            public var thu: Double { __data["thu"] }
            public var fri: Double { __data["fri"] }
            public var sat: Double { __data["sat"] }
            public var sun: Double { __data["sun"] }
          }
        }
      }
    }
  }
}
