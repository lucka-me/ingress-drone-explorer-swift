import Foundation

class Explorer {

    typealias PortalSet = Set<Portal>
    typealias CellSet = Set<S2Cell>
    typealias CellPortalsDictionary = [ S2Cell : PortalSet ]

    static private let visibleRadius: Double = 500
    static private let reachableRadiusWithKey: Double = 1250

    var start = LngLat()
    var cells : CellPortalsDictionary = [ : ]
    var reachableCells : CellSet = [ ]
    var cellsContainingKeys : CellPortalsDictionary = [ : ]
}

extension Explorer {
    enum LoadError : Error {
        case invalidWildcard
    }

    func load(portalList filenames: [ String ]) throws {
        let startTime = Date()
        var portalCount = 0
        var urls : Set<URL> = [ ]

        print("⏳ Loading Portals...")
        defer {
            let endTime = Date()
            print(
                "📍 Loaded \(portalCount) Portal(s) in \(cells.count) cell(s) from \(urls.count) file(s),",
                "which took \(from: startTime, to: endTime) in total."
            )
        }

        // Resolve filenames
        let fileManager = FileManager()
        for filename in filenames {
            if !filename.contains("*") {
                urls.insert(.init(fileURLWithPath: filename))
                continue
            }
            // Resolve wildcard
            let url = URL(fileURLWithPath: filename)
            let directory = url.deletingLastPathComponent()
            if directory.absoluteString.contains("*") {
                // Wildcard in directory
                throw LoadError.invalidWildcard
            }
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            #if !os(Windows) && !os(Linux)
            let predicate = NSPredicate(format: "SELF like %@", url.lastPathComponent)
            #endif
            let matches = contents.filter { item in
                #if !os(Windows) && !os(Linux)
                predicate.evaluate(with: item.lastPathComponent)
                #else
                url.lastPathComponent.matches(wildcard: item.lastPathComponent)
                #endif
            }.map { item in
                // Replace the absolute path with argument path
                directory.appendingPathComponent(item.lastPathComponent)
            }
            urls.formUnion(matches)
        }

        // Load portals
        let decoder = JSONDecoder()
        for url in urls {
            let data = try Data(contentsOf: url)
            let portals = try decoder.decode([ Portal ].self, from: data)
            var fileAddPortalCount = 0
            var fileAddCellCount = 0
            for portal in portals {
                let cell = S2Cell(portal.lngLat)
                var list = cells[cell, default: [ ]]
                if list.isEmpty {
                    list.insert(portal)
                    fileAddCellCount += 1
                    fileAddPortalCount += 1
                } else {
                    if !list.contains(portal) {
                        list.insert(portal)
                        fileAddPortalCount += 1
                    } else if portal.title != nil {
                        // Prefer titled one
                        list.update(with: portal)
                    }
                }
                cells[cell] = list
            }
            portalCount += fileAddPortalCount
            print(
                "  📃 Added \(fileAddPortalCount, width: 5) portal(s) and \(fileAddCellCount, width: 4) cell(s)",
                "from \(url.relativeString)"
            )
        }
    }

    func load(keys filename: String) throws {
        print("⏳ Loading Keys from \(filename)...")
        let decoder = JSONDecoder()
        let url = URL(fileURLWithPath: filename)
        let data = try Data(contentsOf: url)
        var keys = try decoder
            .decode([ String ].self, from: data)
            .reduce(into: Set<Portal>()) { list, guid in
                list.insert(Portal(guid: guid))
            }
        let total = keys.count
        for (cell, portals) in cells {
            let keysInCell = portals.intersection(keys)
            guard !keysInCell.isEmpty else { continue }
            cellsContainingKeys[cell] = keysInCell
            keys.subtract(keysInCell)
        }
        print("🔑 Loaded \(total) Key(s) and matched \(total - keys.count) in \(cellsContainingKeys.count) cell(s).")
    }
}

extension Explorer {
    func explore(from start: LngLat) {
        self.start = start
        let startTime = Date()
        let startCell = S2Cell(start)
        print("⏳ Exploring...")
        // print("⏳ Explore from \(start) in cell \(startCell.id)...")
        defer {
            let endTime = Date()
            print("🔍 Exploration finished after \(from: startTime, to: endTime)")
        }

        var queue : CellSet = [ ]

        if cells.keys.contains(startCell) {
            queue.insert(startCell)
        } else {
            queue = startCell.queryNeighbouredCellsCoveringCap(of: start, radius: Self.visibleRadius)
        }

        var previousTime = startTime.timeIntervalSinceReferenceDate
        let progressDigitCount = cells.count.digitCount
        while let cell = queue.popFirst() {
            if reachableCells.contains(cell) { continue }
            guard let portals = cells[cell] else { continue }
            reachableCells.insert(cell)
            cellsContainingKeys.removeValue(forKey: cell)
            for portal in portals {
                queue.formUnion(cell.queryNeighbouredCellsCoveringCap(of: portal.lngLat, radius: Self.visibleRadius))
                cellsContainingKeys = cellsContainingKeys.filter { entry in
                    guard !queue.contains(entry.key) else { return false }
                    let reachable = entry.value.contains { target in
                        portal.lngLat.distance(to: target.lngLat) < Self.reachableRadiusWithKey
                    }
                    if reachable {
                        queue.insert(entry.key)
                    }
                    return !reachable
                }
            }
            let now = Date().timeIntervalSinceReferenceDate
            if now - previousTime >= 1 {
                print(
                    "  ⏳ Reached \(reachableCells.count, width: progressDigitCount) / \(cells.count) cell(s)"
                )
                previousTime = now
            }
        }
    }
}

extension Explorer {
    func report() {
        var portalsCount = 0
        var reachablePortalsCount = 0
        var furthestPortal = Portal(lngLat: start)
        for entry in cells {
            portalsCount += entry.value.count
            if !reachableCells.contains(entry.key) { continue }
            reachablePortalsCount += entry.value.count
            for portal in entry.value {
                if start.closer(to: furthestPortal.lngLat, than: portal.lngLat) {
                    furthestPortal = portal
                }
            }
        }
        guard reachablePortalsCount > 0 else {
            print("⛔️ There is no reachable portal in \(portalsCount) portal(s) from \(start).")
            return
        }
        let totalDigitCount = portalsCount.digitCount
        let reachableDigitCount = reachablePortalsCount.digitCount
        let unreachableDigitCount = (portalsCount - reachablePortalsCount).digitCount
        print(
            "⬜️ In \(cells.count, width: totalDigitCount)   cell(s),",
            "\(reachableCells.count, width: reachableDigitCount) are ✅ reachable,",
            "\(cells.count - reachableCells.count, width: unreachableDigitCount) are ⛔️ not."
        )
        print(
            "📍 In \(portalsCount, width: totalDigitCount) Portal(s),",
            "\(reachablePortalsCount, width: reachableDigitCount) are ✅ reachable,",
            "\(portalsCount - reachablePortalsCount, width: unreachableDigitCount) are ⛔️ not."
        )
        print(
            "🛬 The furthest Portal is \(furthestPortal.title ?? "Untitled").",
            "  📍 It's located at \(furthestPortal.lngLat)",
            "  📏 Where is \(start.distance(to: furthestPortal.lngLat) / 1000) km away",
            "  🔗 Check it out: https://intel.ingress.com/?pll=\(furthestPortal.lngLat.lat),\(furthestPortal.lngLat.lng)",
            separator: "\n"
        )
    }
}

extension Explorer {
    func saveDrawnItems(to filename: String) throws {
        let items = cells.map { entry in
            DrawnItem(
                type: "polygon",
                color: reachableCells.contains(entry.key) ? "#783cbd" : "#404040",
                latLngs: entry.key.shape
            )
        }
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        try data.write(to: .init(fileURLWithPath: filename))
        print("💾 Saved drawn items to \(filename)")
    }
}

fileprivate extension Int {
    var digitCount: Int {
        var number = self
        var result = number < 0 ? 1 : 0;
        while (number != 0) {
            number /= 10
            result += 1
        }
        return result
    }
}

fileprivate extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: Int, width: Int) {
        appendLiteral(.init(format: "%\(width)d", value))
    }

    mutating func appendInterpolation(_ value: LngLat) {
        appendLiteral("\(value.lng),\(value.lat)")
    }

    mutating func appendInterpolation(from: Date, to: Date) {
        appendLiteral("\(to.timeIntervalSinceReferenceDate - from.timeIntervalSinceReferenceDate) second(s)")
    }
}

#if os(Windows) || os(Linux)
fileprivate extension String {
    func matches(wildcard pattern: String) -> Bool {
        var posT = startIndex
        var posP = pattern.startIndex
        let endT = endIndex
        let endP = endIndex

        // Match till first *
        while posT <= endT && posP <= endP && pattern[posP] != "*" {
            if self[posT] != pattern[posP] && pattern[posP] != "?" {
                return false
            }
            posT = index(after: posT)
            posP = pattern.index(after: posP)
        }
        var startT = posT
        var startP: Index? = nil
        while posT <= endT {
            if pattern[posP] == "*" {
                posP = pattern.index(after: posP)
                // End with *
                if endP < posP {
                    break
                }
                startT = posT;
                startP = posP;
            } else if self[posT] == pattern[posP] || pattern[posP] == "?" {
                posT = index(after: posT)
                posP = pattern.index(after: posP)
            } else if let startP = startP {
                // Cover the segment with * and retry
                startT = index(after: startT)
                posP = startP;
                posT = startT;
            } else {
                // Can not retry
                return false;
            }
        }
        while posP <= endP && pattern[posP] == "*" {
            posP = pattern.index(after: posP)
        }
        return endP < posP;
    }
}
#endif