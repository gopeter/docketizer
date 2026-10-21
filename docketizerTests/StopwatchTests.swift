//
//  StopwatchTests.swift
//  docketizerTests
//

import ApolloAPI
import Foundation
import DocketAPI
import Testing
@testable import docketizer

struct StopwatchClockTests {
    @Test func formatsSecondsAsAClock() {
        #expect(TimeHelper.formatClock(4043) == "1:07:23")
        #expect(TimeHelper.formatClock(59) == "0:00:59")
        #expect(TimeHelper.formatClock(-5) == "0:00:00")
    }

    @Test func readsTypedTimes() {
        #expect(TimeHelper.parseClock("1:07:23") == 4043)
        #expect(TimeHelper.parseClock("1:07") == 4020)
        #expect(TimeHelper.parseClock(" 45 ") == 2700)
    }

    @Test func rejectsWhatIsNoTime() {
        #expect(TimeHelper.parseClock("") == nil)
        #expect(TimeHelper.parseClock("abc") == nil)
        #expect(TimeHelper.parseClock("1:") == nil)
        #expect(TimeHelper.parseClock("1:75") == nil)
        #expect(TimeHelper.parseClock("1:07:60") == nil)
        #expect(TimeHelper.parseClock("-5") == nil)
    }
}

struct MutationErrorsTests {
    /// docket answers a refused validation with an errors object; reading it as a String made the
    /// whole response fail to parse, so the app never saw the message.
    @Test func readsAValidationErrorObject() throws {
        let data = try UpdateStopwatchMutation.Data(data: [
            "updateStopwatch": [
                "__typename": "UpdateStopwatchPayload",
                "stopwatches": [] as [JSONValue],
                "errors": ["title": ["is too long"], "base": ["Try again"]] as JSONObject,
            ] as JSONObject,
        ])

        #expect(data.updateStopwatch?.errors?.messages == ["Try again", "title is too long"])
    }

    @Test func readsNoErrors() throws {
        let data = try UpdateStopwatchMutation.Data(data: [
            "updateStopwatch": [
                "__typename": "UpdateStopwatchPayload",
                "stopwatches": [] as [JSONValue],
                "errors": NSNull(),
            ] as JSONObject,
        ])

        #expect(data.updateStopwatch?.errors == nil)
    }
}
