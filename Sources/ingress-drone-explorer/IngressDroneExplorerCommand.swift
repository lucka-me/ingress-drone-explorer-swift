import ArgumentParser

@main
struct IngressDroneExplorerCommand : ParsableCommand {

    static var configuration = CommandConfiguration(
        commandName: "ingress-drone-explorer",
        abstract: "Analyze reachable Portals for Ingress Drone Mark I.",
        discussion: """
        GitHub: https://github.com/lucka-me/ingress-drone-explorer-swift
        Licensed under MIT.
        """
    )

    @Argument(
        help: ArgumentHelp(
            "Paths of portal list file.",
            discussion: "Supports wildcards in filename.",
            valueName: "portal-list-file"
        ),
        completion: .file(extensions: [ ".json" ])
    )
    var portalListFilenames: [ String ]

    @Option(
        name: [ .short, .long ],
        help: ArgumentHelp("The starting point.", valueName: "longitude,latitude"),
        transform: { text in
            guard let lngLat = LngLat(text) else {
                throw ValidationError("It should be formated as longitude,latitude.")
            }
            return lngLat
        }
    )
    var start: LngLat

    @Option(
        name: [ .short, .customLong("key-list") ],
        help: ArgumentHelp("Path of key list file.", valueName: "path")
    )
    var keyListFilename: String?

    @Option(
        name: .customLong("output-drawn-items"),
        help: ArgumentHelp("Path of drawn items file to output.", valueName: "path")
    )
    var outputDrawnItemsFilename: String?

    mutating func run() throws {
        let explorer = Explorer()
        try explorer.load(portalList: portalListFilenames)
        if let keyListFilename = keyListFilename {
            try explorer.load(keys: keyListFilename)
        }
        explorer.explore(from: start)
        explorer.report()
        if let outputDrawnItemsFilename = outputDrawnItemsFilename {
            try explorer.saveDrawnItems(to: outputDrawnItemsFilename)
        }
    }
}