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