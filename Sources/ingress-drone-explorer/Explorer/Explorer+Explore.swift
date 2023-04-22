import Foundation

extension Explorer {
    func explore(from start: Coordinate) {
        self.start = start
        let startTime = Date()
        let startCell = S2Cell(start)
        print("⏳ Exploring...")
        defer {
            let endTime = Date()
            print("🔍 Exploration finished after \(from: startTime, to: endTime)")
        }

        var queue : Set<S2Cell> = [ ]

        if cells.keys.contains(startCell) {
            queue.insert(startCell)
        } else {
            queue = startCell
                .neighboredCellsCoveringCap(of: start, radius: Self.visibleRadius)
                .intersection(cells.keys)
        }

        var previousTime = startTime.timeIntervalSinceReferenceDate
        let progressDigitCount = cells.count.digitCount
        while let cell = queue.popFirst() {
            guard let portals = cells[cell] else { continue }
            reachableCells.insert(cell)

            // Get all neighbors in the visible range (also the possible ones), filter the empty/pending/reached ones
            // and search for reachable ones
            let neighbors = cell.neighboredCells(in: Int(Self.visibleRadius / 80.0) + 1)
            for neighbor in neighbors {
                guard
                    !queue.contains(neighbor),
                    !reachableCells.contains(neighbor),
                    cells.keys.contains(neighbor)
                else {
                    continue
                }
                for portal in portals {
                    if neighbor.intersectsWithCap(of: portal.coordinate, radius: Self.visibleRadius) {
                        queue.insert(neighbor)
                        break
                    }
                }
            }

            // Find keys
            /// TODO: Consider to use cell.neighboured_cells_in instead?
            if !cellsContainingKeys.isEmpty {
                for portal in portals {
                    cellsContainingKeys = cellsContainingKeys.filter { entry in
                        guard !queue.contains(entry.key) else { return false }
                        for target in entry.value {
                            if portal.coordinate.distance(to: target.coordinate) < Self.reachableRadiusWithKey {
                                queue.insert(entry.key)
                                return false
                            }
                        }
                        return true
                    }
                    if cellsContainingKeys.isEmpty {
                        break
                    }
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