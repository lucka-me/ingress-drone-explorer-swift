import Foundation

struct S2Cell : Hashable {

    let face: UInt8
    let level: UInt8

    let i: Int
    let j: Int

    init(face: UInt8, i: Int, j: Int, level: UInt8 = 16) {
        self.face = face
        self.level = level
        self.i = i
        self.j = j
    }

    init(_ coordinate: Coordinate, level: UInt8 = 16) {
        self.level = level
        let (face, s, t) = ECEFCoordinate(coordinate).faceST
        self.face = face
        let max = 1 << level
        let range  = 0 ... max - 1
        i = Int(floor(s * Double(max))).clamp(to: range)
        j = Int(floor(t * Double(max))).clamp(to: range)
    }
}

extension S2Cell {
    var center: Coordinate {
        coordinate(dI: 0.5, dJ: 0.5)
    }

    var shape: [ Coordinate ] {
        [
            coordinate(dI: 0, dJ: 0),
            coordinate(dI: 0, dJ: 1),
            coordinate(dI: 1, dJ: 1),
            coordinate(dI: 1, dJ: 0)
        ]
    }

    func coordinate(dI : Double, dJ: Double) -> Coordinate {
        let max = Double(1 << level)
        return ECEFCoordinate(face: face, s: (Double(i) + dI) / max, t: (Double(j) + dJ) / max).coordinate
    }
}

extension S2Cell {
    private static func wrap(face: UInt8, i: Int, j: Int, level: UInt8 = 16) -> S2Cell {
        let max = 1 << level
        if i >= 0 && j >= 0 && i < max && j < max {
            return .init(face: face, i: i, j: j, level: level)
        }
        let (wrappedFace, wrappedS, wrappedT) =
            ECEFCoordinate(face: face, s: (Double(i) + 0.5) / Double(max), t: (Double(j) + 0.5) / Double(max)).faceST
        let range  = 0 ... max - 1
        return .init(
            face: wrappedFace,
            i: Int(floor(wrappedS * Double(max))).clamp(to: range),
            j: Int(floor(wrappedT * Double(max))).clamp(to: range),
            level: level
        )
    }

    func neighboredCellsCoveringCap(of center: Coordinate, radius: Double) -> Set<S2Cell> {
        var result : Set<S2Cell> = [ ]
        var outsides : Set<S2Cell> = [ ]
        var queue : Set = [ self ]
        while let cell = queue.popFirst() {
            if result.contains(cell) || outsides.contains(cell) { continue }
            if (cell.intersectsWithCap(of: center, radius: radius)) {
                result.insert(cell)
                queue.formUnion(cell.neighbors)
            } else {
                outsides.insert(cell)
            }
        }
        result.remove(self)
        return result
    }

    func neighboredCells(in rounds: Int) -> Set<S2Cell> {
        var result : Set<S2Cell> = [ ]
        for round in 0 ..< rounds {
            for step in 0 ..< (round + 1) * 2 {
                result.insert(.init(face: face, i: i - round - 1   , j: j - round + step, level: level)); // Left, upward
                result.insert(.init(face: face, i: i - round + step, j: j + round + 1   , level: level)); // Top, rightward
                result.insert(.init(face: face, i: i + round + 1   , j: j + round - step, level: level)); // Right, downward
                result.insert(.init(face: face, i: i + round - step, j: j - round - 1   , level: level)); // Bottom, leftward
            }
        }
        return result
    }

    func intersectsWithCap(of center: Coordinate, radius: Double) -> Bool {
        let corners = shape.sorted { a, b in center.closer(to: a, than: b) }
        return center.distance(to: corners[0]) < radius
            || center.distance(to: (corners[0], corners[1])) < radius
    }

    private var neighbors : Set<S2Cell> {
        [
            .wrap(face: face, i: i - 1  , j: j      , level: level),
            .wrap(face: face, i: i      , j: j - 1  , level: level),
            .wrap(face: face, i: i + 1  , j: j      , level: level),
            .wrap(face: face, i: i      , j: j + 1  , level: level),
        ]
    }
}

fileprivate struct ECEFCoordinate {
    var x : Double
    var y : Double
    var z : Double
}

fileprivate extension ECEFCoordinate {
    init(_ coordinate: Coordinate) {
        let theta = coordinate.theta
        let phi = coordinate.phi
        let cosPhi = cos(phi)
        x = cos(theta) * cosPhi
        y = sin(theta) * cosPhi
        z = sin(phi)
    }

    var coordinate: Coordinate {
        .init(
            lng: atan2(y, x) / Double.pi * 180.0,
            lat: atan2(z, sqrt(x * x + y * y)) / Double.pi * 180.0
        )
    }
}

fileprivate extension ECEFCoordinate {
    init(face: UInt8, s: Double, t: Double) {
        let u =  (1 / 3.0) * (s >= 0.5 ? (4 * s * s - 1) : (1 - (4 * (1 - s) * (1 - s))))
        let v =  (1 / 3.0) * (t >= 0.5 ? (4 * t * t - 1) : (1 - (4 * (1 - t) * (1 - t))))

        switch face {
        case 0:
            x = 1
            y = u
            z = v
        case 1:
            x = -u
            y = 1
            z = v
        case 2:
            x = -u
            y = -v
            z = 1
        case 3:
            x = -1
            y = -v
            z = -u
        case 4:
            x = v
            y = -1
            z = -u
        default:
            x = v
            y = u
            z = -1
        }
    }

    var faceST : (face: UInt8, s: Double, t: Double) {
        let absX = fabs(x)
        let absY = fabs(y)
        var face: UInt8 = absX > absY ? (absX > fabs(z) ? 0 : 2) : (absY > fabs(z) ? 1 : 2)
        if (face == 0 && x < 0) || (face == 1 && y < 0) || (face == 2 && z < 0) {
            face += 3
        }
        var u, v : Double
        switch face {
        case 0:
            u = y / x
            v = z / x
        case 1:
            u = -x / y
            v = z / y
        case 2:
            u = -x / z
            v = -y / z
        case 3:
            u = z / x
            v = y / x
        case 4:
            u = z / y
            v = -x / y
        default:
            u = -y / z
            v = -x / z
        }
        return (
            face,
            u >= 0 ? (0.5 * sqrt(1 + 3 * u)) : (1 - 0.5 * sqrt(1 - 3 * u)),
            v >= 0 ? (0.5 * sqrt(1 + 3 * v)) : (1 - 0.5 * sqrt(1 - 3 * v))
        )
    }
}

fileprivate extension Comparable {
    func clamp(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}