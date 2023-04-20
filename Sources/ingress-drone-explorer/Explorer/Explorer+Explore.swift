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

        var queue : CellSet = [ ]

        if cells.keys.contains(startCell) {
            queue.insert(startCell)
        } else {
            queue = startCell.neighboredCellsCoveringCap(of: start, radius: Self.visibleRadius)
        }

        var previousTime = startTime.timeIntervalSinceReferenceDate
        let progressDigitCount = cells.count.digitCount
        while let cell = queue.popFirst() {
            if reachableCells.contains(cell) { continue }
            guard let portals = cells[cell] else { continue }
            reachableCells.insert(cell)
            cellsContainingKeys.removeValue(forKey: cell)
            for portal in portals {
                queue.formUnion(cell.neighboredCellsCoveringCap(of: portal.coordinate, radius: Self.visibleRadius))
                cellsContainingKeys = cellsContainingKeys.filter { entry in
                    guard !queue.contains(entry.key) else { return false }
                    let reachable = entry.value.contains { target in
                        portal.coordinate.distance(to: target.coordinate) < Self.reachableRadiusWithKey
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