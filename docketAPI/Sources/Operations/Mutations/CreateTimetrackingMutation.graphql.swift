// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public class CreateTimetrackingMutation: GraphQLMutation {
  public static let operationName: String = "CreateTimetracking"
  public static let operationDocument: ApolloAPI.OperationDocument = .init(
    definition: .init(
      #"mutation CreateTimetracking($input: CreateTimetrackingInput!) { createTimetracking(input: $input) { __typename timetracking { __typename id } errors } }"#
    ))

  public var input: CreateTimetrackingInput

  public init(input: CreateTimetrackingInput) {
    self.input = input
  }

  public var __variables: Variables? { ["input": input] }

  public struct Data: DocketAPI.SelectionSet {
    public let __data: DataDict
    public init(_dataDict: DataDict) { __data = _dataDict }

    public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Mutation }
    public static var __selections: [ApolloAPI.Selection] { [
      .field("createTimetracking", CreateTimetracking?.self, arguments: ["input": .variable("input")]),
    ] }

    public var createTimetracking: CreateTimetracking? { __data["createTimetracking"] }

    /// CreateTimetracking
    ///
    /// Parent Type: `CreateTimetrackingPayload`
    public struct CreateTimetracking: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.CreateTimetrackingPayload }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("timetracking", Timetracking?.self),
        .field("errors", DocketAPI.Json?.self),
      ] }

      public var timetracking: Timetracking? { __data["timetracking"] }
      public var errors: DocketAPI.Json? { __data["errors"] }

      /// CreateTimetracking.Timetracking
      ///
      /// Parent Type: `Timetracking`
      public struct Timetracking: DocketAPI.SelectionSet {
        public let __data: DataDict
        public init(_dataDict: DataDict) { __data = _dataDict }

        public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Timetracking }
        public static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DocketAPI.ID.self),
        ] }

        public var id: DocketAPI.ID { __data["id"] }
      }
    }
  }
}
