import Foundation

extension Explorer {
    func report() {
        var portalsCount = 0
        var reachablePortalsCount = 0
        var furthestPortal = Portal(coordinate: start)
        for entry in cells {
            portalsCount += entry.value.count
            if !reachableCells.contains(entry.key) { continue }
            reachablePortalsCount += entry.value.count
            for portal in entry.value {
                if start.closer(to: furthestPortal.coordinate, than: portal.coordinate) {
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
            "  📍 It's located at \(furthestPortal.coordinate)",
            "  📏 Where is \(start.distance(to: furthestPortal.coordinate) / 1000) km away",
            "  🔗 Check it out: https://intel.ingress.com/?pll=\(furthestPortal.coordinate.lat),\(furthestPortal.coordinate.lng)",
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
                shape: entry.key.shape
            )
        }
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        try data.write(to: .init(fileURLWithPath: filename))
        print("💾 Saved drawn items to \(filename)")
    }
}