import Foundation

struct Coordinate {
    var lng: Double = 0
    var lat: Double = 0
}

extension Coordinate {
    init?(_ text: String) {
        let components = text.split(separator: ",")
        if components.count != 2 { return nil }
        guard
            let lng = Double(components[0]),
            abs(lng) <= 180
        else {
            return nil
        }
        guard
            let lat = Double(components[1]),
            abs(lat) <= 90
        else {
            return nil
        }
        self.lng = lng
        self.lat = lat
    }
}

extension Coordinate: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lng = try container.decode(Double.self, forKey: .lng)
        guard abs(lng) <= 180 else {
            throw DecodingError.dataCorruptedError(
                forKey: .lng, in: container, debugDescription: "The lng is not in range of [-180, 180]."
            )
        }
        lat = try container.decode(Double.self, forKey: .lat)
        guard abs(lat) <= 180 else {
            throw DecodingError.dataCorruptedError(
                forKey: .lat, in: container, debugDescription: "The lat is not in range of [-90, 90]."
            )
        }
    }
}

extension Coordinate {

    private static let earthRadius = 6371008.8

    var theta: Double {
        lng * Double.pi / 180.0
    }

    var phi: Double {
        lat * Double.pi / 180.0
    }

    func distance(to other: Coordinate) -> Double {
        let sinT = sin((other.theta - theta) / 2)
        let sinP = sin((other.phi - phi) / 2)
        let a = sinP * sinP + sinT * sinT * cos(phi) * cos(other.phi)
        return atan2(sqrt(a), sqrt(1 - a)) * 2 * Self.earthRadius
    }

    func distance(to segment: (a: Coordinate, b: Coordinate)) -> Double {
        let c1 = (segment.b.lat - segment.a.lat) * (lat - segment.a.lat)
            + (segment.b.lng - segment.a.lng) * (lng - segment.a.lng)
        if c1 <= 0 {
            return distance(to: segment.a)
        }
        let c2 = (segment.b.lat - segment.a.lat) * (segment.b.lat - segment.a.lat)
            + (segment.b.lng - segment.a.lng) * (segment.b.lng - segment.a.lng)
        if c2 <= c1 {
            return distance(to: segment.b)
        }
        let ratio = c1 / c2;
        return distance(to:
            .init(
                lng: segment.a.lng + ratio * (segment.b.lng - segment.a.lng),
                lat: segment.a.lat + ratio * (segment.b.lat - segment.a.lat)
            )
        )
    }

    func closer(to a: Coordinate, than b: Coordinate) -> Bool {
        let dA = (lng - a.lng) * (lng - a.lng) + (lat - a.lat) * (lat - a.lat)
        let dB = (lng - b.lng) * (lng - b.lng) + (lat - b.lat) * (lat - b.lat)
        return dA < dB
    }
}