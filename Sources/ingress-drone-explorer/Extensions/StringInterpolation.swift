import Foundation

extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Int, width: Int) {
        appendLiteral(.init(format: "%\(width)d", value))
    }

    mutating func appendInterpolation(_ value: Coordinate) {
        appendLiteral("\(value.lng),\(value.lat)")
    }

    mutating func appendInterpolation(from: Date, to: Date) {
        appendLiteral("\(to.timeIntervalSinceReferenceDate - from.timeIntervalSinceReferenceDate) second(s)")
    }
}