// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ProjectTicketsQuery: GraphQLQuery {
  public static let operationName: String = "ProjectTickets"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query ProjectTickets($projectId: ID!) { tickets(filter: { projectIds: [$projectId], bookable: true }) { __typename nodes { __typename id title number project { __typename id title pnr } } } }"#
    ))

  public var projectId: ID

  public init(projectId: ID) {
    self.projectId = projectId
  }

  public var __variables: Variables? { ["projectId": projectId] }

  public struct Data: DocketAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("tickets", Tickets.self, arguments: ["filter": [
        "projectIds": [.variable("projectId")],
        "bookable": true
      ]]),
    ] }

    public var tickets: Tickets { __data["tickets"] }

    /// Tickets
    ///
    /// Parent Type: `TicketConnection`
    public struct Tickets: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.TicketConnection }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("nodes", [Node].self),
      ] }

      /// A list of nodes.
      public var nodes: [Node] { __data["nodes"] }

      /// Tickets.Node
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

        /// Tickets.Node.Project
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
