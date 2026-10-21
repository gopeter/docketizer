// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

public protocol SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == DocketAPI.SchemaMetadata {}

public protocol InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == DocketAPI.SchemaMetadata {}

public protocol MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == DocketAPI.SchemaMetadata {}

public protocol MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == DocketAPI.SchemaMetadata {}

public enum SchemaMetadata: ApolloAPI.SchemaMetadata {
  public static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

  public static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
    switch typename {
    case "Account": return DocketAPI.Objects.Account
    case "Accounting": return DocketAPI.Objects.Accounting
    case "AccountingCustomField": return DocketAPI.Objects.AccountingCustomField
    case "AccountingCustomFieldValue": return DocketAPI.Objects.AccountingCustomFieldValue
    case "Attachment": return DocketAPI.Objects.Attachment
    case "Board": return DocketAPI.Objects.Board
    case "Contact": return DocketAPI.Objects.Contact
    case "CreateStopwatchPayload": return DocketAPI.Objects.CreateStopwatchPayload
    case "CreateTimetrackingPayload": return DocketAPI.Objects.CreateTimetrackingPayload
    case "CustomField": return DocketAPI.Objects.CustomField
    case "Customer": return DocketAPI.Objects.Customer
    case "CustomerAddress": return DocketAPI.Objects.CustomerAddress
    case "DeleteStopwatchPayload": return DocketAPI.Objects.DeleteStopwatchPayload
    case "DeliveryNote": return DocketAPI.Objects.DeliveryNote
    case "DeliveryNoteComment": return DocketAPI.Objects.DeliveryNoteComment
    case "Event": return DocketAPI.Objects.Event
    case "ExternalCost": return DocketAPI.Objects.ExternalCost
    case "ExternalCostAssignment": return DocketAPI.Objects.ExternalCostAssignment
    case "Invoice": return DocketAPI.Objects.Invoice
    case "InvoiceComment": return DocketAPI.Objects.InvoiceComment
    case "JiraProjectLink": return DocketAPI.Objects.JiraProjectLink
    case "JiraSite": return DocketAPI.Objects.JiraSite
    case "JiraUserCredential": return DocketAPI.Objects.JiraUserCredential
    case "JiraUserMapping": return DocketAPI.Objects.JiraUserMapping
    case "Mention": return DocketAPI.Objects.Mention
    case "Mutation": return DocketAPI.Objects.Mutation
    case "OrderConfirmation": return DocketAPI.Objects.OrderConfirmation
    case "OrderConfirmationComment": return DocketAPI.Objects.OrderConfirmationComment
    case "PauseStopwatchPayload": return DocketAPI.Objects.PauseStopwatchPayload
    case "Phase": return DocketAPI.Objects.Phase
    case "Project": return DocketAPI.Objects.Project
    case "ProjectConnection": return DocketAPI.Objects.ProjectConnection
    case "ProjectLabel": return DocketAPI.Objects.ProjectLabel
    case "Query": return DocketAPI.Objects.Query
    case "Quotation": return DocketAPI.Objects.Quotation
    case "QuotationComment": return DocketAPI.Objects.QuotationComment
    case "Service": return DocketAPI.Objects.Service
    case "ServiceCategory": return DocketAPI.Objects.ServiceCategory
    case "ServiceRate": return DocketAPI.Objects.ServiceRate
    case "SharedProjectReport": return DocketAPI.Objects.SharedProjectReport
    case "StartStopwatchPayload": return DocketAPI.Objects.StartStopwatchPayload
    case "Stopwatch": return DocketAPI.Objects.Stopwatch
    case "Stripe": return DocketAPI.Objects.Stripe
    case "StripeCreditCard": return DocketAPI.Objects.StripeCreditCard
    case "StripeInvoice": return DocketAPI.Objects.StripeInvoice
    case "StripePayment": return DocketAPI.Objects.StripePayment
    case "StripePlan": return DocketAPI.Objects.StripePlan
    case "StripeSubscription": return DocketAPI.Objects.StripeSubscription
    case "Supplier": return DocketAPI.Objects.Supplier
    case "Ticket": return DocketAPI.Objects.Ticket
    case "TicketAssignment": return DocketAPI.Objects.TicketAssignment
    case "TicketComment": return DocketAPI.Objects.TicketComment
    case "TicketConnection": return DocketAPI.Objects.TicketConnection
    case "Timetracking": return DocketAPI.Objects.Timetracking
    case "TimetrackingConnection": return DocketAPI.Objects.TimetrackingConnection
    case "UpdateStopwatchPayload": return DocketAPI.Objects.UpdateStopwatchPayload
    case "User": return DocketAPI.Objects.User
    case "UserConnection": return DocketAPI.Objects.UserConnection
    case "UserWorkTime": return DocketAPI.Objects.UserWorkTime
    case "UserWorkTimeConnection": return DocketAPI.Objects.UserWorkTimeConnection
    case "Viewer": return DocketAPI.Objects.Viewer
    default: return nil
    }
  }
}

public enum Objects {}
public enum Interfaces {}
public enum Unions {}
