//
//  MomentFormatUseCase.swift
//  Opal
//
//  Created by Jamie Le Souef on 28/10/2026.
//

import Foundation

public enum MomentFormatUseCase {
    // MARK: - Constants

    private static let tokens = ["YYYY", "MMMM", "dddd", "MMM", "ddd", "YY", "MM", "DD", "HH", "hh", "mm", "ss", "M", "D", "H", "h", "A", "a"]

    // MARK: - Format

    public static func string(from date: Date, format: String, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let parts = calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute, .second], from: date)
        var result = ""
        var rest = Substring(format)
        while let first = rest.first {
            if first == "[" {
                let closing = rest.dropFirst().firstIndex(of: "]") ?? rest.endIndex
                result += rest.dropFirst()[..<closing]
                rest = closing < rest.endIndex ? rest[rest.index(after: closing)...] : ""
                continue
            }

            guard let token = tokens.first(where: { rest.hasPrefix($0) }) else {
                result.append(first)
                rest = rest.dropFirst()
                continue
            }

            result += value(of: token, parts: parts, calendar: calendar)
            rest = rest.dropFirst(token.count)
        }
        return result
    }

    // MARK: - Private

    private static func value(of token: String, parts: DateComponents, calendar: Calendar) -> String {
        let year = parts.year ?? 0
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        let weekday = (parts.weekday ?? 1) - 1
        let hour = parts.hour ?? 0
        switch token {
        case "YYYY":
            return String(format: "%04d", year)
        case "YY":
            return String(format: "%02d", year % 100)
        case "MMMM":
            return calendar.monthSymbols[month - 1]
        case "MMM":
            return calendar.shortMonthSymbols[month - 1]
        case "MM":
            return String(format: "%02d", month)
        case "M":
            return String(month)
        case "DD":
            return String(format: "%02d", day)
        case "D":
            return String(day)
        case "dddd":
            return calendar.weekdaySymbols[weekday]
        case "ddd":
            return calendar.shortWeekdaySymbols[weekday]
        case "HH":
            return String(format: "%02d", hour)
        case "H":
            return String(hour)
        case "hh":
            return String(format: "%02d", hour % 12 == 0 ? 12 : hour % 12)
        case "h":
            return String(hour % 12 == 0 ? 12 : hour % 12)
        case "mm":
            return String(format: "%02d", parts.minute ?? 0)
        case "ss":
            return String(format: "%02d", parts.second ?? 0)
        case "A":
            return hour < 12 ? "AM" : "PM"
        default:
            return hour < 12 ? "am" : "pm"
        }
    }
}
