// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

public struct StopwatchFields: DocketAPI.SelectionSet, Fragment {
  public static var fragmentDefinition: StaticString {
    #"fragment StopwatchFields on Stopwatch { __typename id title running seconds roundedMinutes ticket { __typename id number title project { __typename id pnr title } } }"#
  }

  public let __data: DataDict
  public init(_dataDict: DataDict) { __data = _dataDict }

  public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Stopwatch }
  public static var __selections: [ApolloAPI.Selection] { [
    .field("__typename", String.self),
    .field("id", DocketAPI.ID.self),
    .field("title", String.self),
    .field("running", Bool.self),
    .field("seconds", Int.self),
    .field("roundedMinutes", Int.self),
    .field("ticket", Ticket?.self),
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

  /// Ticket
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
      .field("project", Project.self),
    ] }

    public var id: DocketAPI.ID { __data["id"] }
    public var number: Int { __data["number"] }
    public var title: String { __data["title"] }
    public var project: Project { __data["project"] }

    /// Ticket.Project
    ///
    /// Parent Type: `Project`
    public struct Project: DocketAPI.SelectionSet {
      public let __data: DataDict
      public init(_dataDict: DataDict) { __data = _dataDict }

      public static var __parentType: any ApolloAPI.ParentType { DocketAPI.Objects.Project }
      public static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("id", DocketAPI.ID.self),
        .field("pnr", String.self),
        .field("title", String.self),
      ] }

      public var id: DocketAPI.ID { __data["id"] }
      public var pnr: String { __data["pnr"] }
      public var title: String { __data["title"] }
    }
  }
}
