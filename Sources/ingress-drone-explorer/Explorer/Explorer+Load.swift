import Foundation

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
                let cell = S2Cell(portal.coordinate)
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