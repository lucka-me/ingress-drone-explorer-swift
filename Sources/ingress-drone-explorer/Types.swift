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

struct Portal : Decodable {
    var guid = ""
    var title: String? = nil
    var coordinate = Coordinate()
}

extension Portal : Hashable {
    static func ==(lhs: Portal, rhs: Portal) -> Bool {
        lhs.guid == rhs.guid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(guid)
    }
}

extension Portal {
    enum CodingKeys: String, CodingKey {
        case guid, title
        case coordinate = "lngLat"
    }
}

struct DrawnItem : Encodable {
    var type: String
    var color: String
    var shape: [ Coordinate ]

    enum CodingKeys: String, CodingKey {
        case type, color
        case shape = "latLngs"
    }
}