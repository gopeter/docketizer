//
//  Time.swift
//  docketizer
//
//  Created by Peter Oesteritz on 17.04.25.
//

import Foundation

class TimeHelper {
    static func formatMinutesToHours(_ duration: Double) -> String {
        let totalMinutes = Int(duration.rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        return String(format: "%d:%02d", hours, minutes)
    }
    
    static func formatHoursToMinutes(_ duration: String) -> Int {
        if duration.contains(",") {
            let normalized = duration.replacingOccurrences(of: ",", with: ".")
            if let value = Double(normalized) {
                return Int(value * 60)
            }
        }

        if duration.contains(":") {
            let parts = duration.split(separator: ":")
            if parts.count == 2,
               let hours = Int(parts[0]),
               let minutes = Int(parts[1]) {
                return hours * 60 + minutes
            }
        }

        if let intVal = Int(duration) {
            return intVal * 60
        }

        return 0
    }

    /// "1:07:23" – a stopwatch's time on the clock.
    static func formatClock(_ seconds: Int) -> String {
        let s = max(seconds, 0)
        return String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
    }

    /// Reads a typed stopwatch time: "1:07:23", "1:07" (hours and minutes) or "45" (minutes).
    /// nil for anything else.
    static func parseClock(_ input: String) -> Int? {
        let parts = input.trimmingCharacters(in: .whitespaces).split(separator: ":", omittingEmptySubsequences: false)
        let numbers = parts.compactMap { Int($0) }
        guard !parts.isEmpty, numbers.count == parts.count, numbers.allSatisfy({ $0 >= 0 }) else { return nil }

        switch numbers.count {
        case 1:
            return numbers[0] * 60
        case 2 where numbers[1] < 60:
            return numbers[0] * 3600 + numbers[1] * 60
        case 3 where numbers[1] < 60 && numbers[2] < 60:
            return numbers[0] * 3600 + numbers[1] * 60 + numbers[2]
        default:
            return nil
        }
    }
}
