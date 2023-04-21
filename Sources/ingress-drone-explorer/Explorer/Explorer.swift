import Foundation

class Explorer {
    static let visibleRadius: Double = 500
    static let reachableRadiusWithKey: Double = 1250

    var start = Coordinate()
    var cells : [ S2Cell : Set<Portal> ] = [ : ]
    var reachableCells : Set<S2Cell> = [ ]
    var cellsContainingKeys : [ S2Cell : Set<Portal> ] = [ : ]
}