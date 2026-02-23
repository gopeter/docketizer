// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ViewerQuery: GraphQLQuery {
  public static let operationName: String = "Viewer"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query Viewer($date: String!) { viewer { __typename id expertise { __typename id } timetrackings(filter: { dates: [$date] }) { __typename nodes { __typename id duration ticket { __typename id number title } project { __typename id title pnr } } } recentlyTrackedTickets(count: 30) { __typename id title number project { __typename id title pnr } } assignedTickets(first: 30) { __typename nodes { __typename id title number project { __typename id title pnr } } } } }"#
    ))

  public var date: String

  public init(date: String) {
    self.date = date
  }

  public var __variables: Variables? { ["date": date] }

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
        .field("expertise", Expertise?.self),
        .field("timetrackings", Timetrackings.self, arguments: ["filter": ["dates": [.variable("date")]]]),
        .field("recentlyTrackedTickets", [RecentlyTrackedTicket].self, arguments: ["count": 30]),
        .field("assignedTickets", AssignedTickets.self, arguments: ["first": 30]),
      ] }

      public var id: DocketAPI.ID { __data["id"] }
      public var expertise: Expertise? { __data["expertise"] }
      public var timetrackings: Timetrackings { __data["timetrackings"] }
      public var recentlyTrackedTickets: [RecentlyTrackedTicket] { __data["recentlyTrackedTickets"] }
      public var assignedTickets: AssignedTickets { __data["assignedTickets"] }

      /// Viewer.Expertise
      ///
      /// Parent Type: `Service`
      public struct Expertise: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Service }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DocketAPI.ID.self),
        ] }

        public var id: DocketAPI.ID { __data["id"] }
      }

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
            .field("ticket", Ticket.self),
            .field("project", Project.self),
          ] }

          public var id: DocketAPI.ID { __data["id"] }
          public var duration: Double { __data["duration"] }
          public var ticket: Ticket { __data["ticket"] }
          public var project: Project { __data["project"] }

          /// Viewer.Timetrackings.Node.Ticket
          ///
          /// Parent Type: `Ticket`
          public struct Ticket: DocketAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Ticket }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", DocketAPI.ID.self),
              .field("number", Int.self),
              .field("title", String.self),
            ] }

            public var id: DocketAPI.ID { __data["id"] }
            public var number: Int { __data["number"] }
            public var title: String { __data["title"] }
          }

          /// Viewer.Timetrackings.Node.Project
          ///
          /// Parent Type: `Project`
          public struct Project: DocketAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Project }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", DocketAPI.ID.self),
              .field("title", String.self),
              .field("pnr", String.self),
            ] }

            public var id: DocketAPI.ID { __data["id"] }
            public var title: String { __data["title"] }
            public var pnr: String { __data["pnr"] }
          }
        }
      }

      /// Viewer.RecentlyTrackedTicket
      ///
      /// Parent Type: `Ticket`
      public struct RecentlyTrackedTicket: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Ticket }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DocketAPI.ID.self),
          .field("title", String.self),
          .field("number", Int.self),
          .field("project", Project.self),
        ] }

        public var id: DocketAPI.ID { __data["id"] }
        public var title: String { __data["title"] }
        public var number: Int { __data["number"] }
        public var project: Project { __data["project"] }

        /// Viewer.RecentlyTrackedTicket.Project
        ///
        /// Parent Type: `Project`
        public struct Project: DocketAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Project }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", DocketAPI.ID.self),
            .field("title", String.self),
            .field("pnr", String.self),
          ] }

          public var id: DocketAPI.ID { __data["id"] }
          public var title: String { __data["title"] }
          public var pnr: String { __data["pnr"] }
        }
      }

      /// Viewer.AssignedTickets
      ///
      /// Parent Type: `TicketConnection`
      public struct AssignedTickets: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.TicketConnection }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("nodes", [Node].self),
        ] }

        /// A list of nodes.
        public var nodes: [Node] { __data["nodes"] }

        /// Viewer.AssignedTickets.Node
        ///
        /// Parent Type: `Ticket`
        public struct Node: DocketAPI.SelectionSet {
          public let __data: DataDict
          public init(_dataDict: DataDict) { __data = _dataDict }

          public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Ticket }
          public static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", DocketAPI.ID.self),
            .field("title", String.self),
            .field("number", Int.self),
            .field("project", Project.self),
          ] }

          public var id: DocketAPI.ID { __data["id"] }
          public var title: String { __data["title"] }
          public var number: Int { __data["number"] }
          public var project: Project { __data["project"] }

          /// Viewer.AssignedTickets.Node.Project
          ///
          /// Parent Type: `Project`
          public struct Project: DocketAPI.SelectionSet {
            public let __data: DataDict
            public init(_dataDict: DataDict) { __data = _dataDict }

            public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Project }
            public static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("id", DocketAPI.ID.self),
              .field("title", String.self),
              .field("pnr", String.self),
            ] }

            public var id: DocketAPI.ID { __data["id"] }
            public var title: String { __data["title"] }
            public var pnr: String { __data["pnr"] }
          }
        }
      }
    }
  }
}
