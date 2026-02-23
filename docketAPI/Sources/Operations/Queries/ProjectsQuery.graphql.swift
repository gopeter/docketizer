// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class ProjectsQuery: GraphQLQuery {
  public static let operationName: String = "Projects"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"query Projects { projects { __typename nodes { __typename id title pnr } } }"#
    ))

  public init() {}

  public struct Data: DocketAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Query }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("projects", Projects.self),
    ] }

    public var projects: Projects { __data["projects"] }

    /// Projects
    ///
    /// Parent Type: `ProjectConnection`
    public struct Projects: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.ProjectConnection }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("nodes", [Node].self),
      ] }

      /// A list of nodes.
      public var nodes: [Node] { __data["nodes"] }

      /// Projects.Node
      ///
      /// Parent Type: `Project`
      public struct Node: DocketAPI.SelectionSet {
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
