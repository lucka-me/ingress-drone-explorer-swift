import Foundation

class Explorer {

    typealias PortalSet = Set<Portal>
    typealias CellSet = Set<S2Cell>
    typealias CellPortalsDictionary = [ S2Cell : PortalSet ]

    static let visibleRadius: Double = 500
    static let reachableRadiusWithKey: Double = 1250

    var start = Coordinate()
    var cells : CellPortalsDictionary = [ : ]
    var reachableCells : CellSet = [ ]
    var cellsContainingKeys : CellPortalsDictionary = [ : ]
}