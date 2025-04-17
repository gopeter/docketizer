//
//  Time.swift
//  docketizer
//
//  Created by Peter Oesteritz on 17.04.25.
//

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
}
