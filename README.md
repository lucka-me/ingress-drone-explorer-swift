# Ingress Drone Explorer - Swift

[![CI](https://github.com/lucka-me/ingress-drone-explorer-swift/actions/workflows/ci.yml/badge.svg)](https://github.com/lucka-me/ingress-drone-explorer-swift/actions/workflows/ci.yml "CI Workflow")
[![Lines of code][swift-loc]][swift-repo]

An offline CLI tool to analyze reachable Portals for Ingress Drone Mark I.

Implementations in different languages are listed and compared in [Benchmark](#benchmark).

The CI workflow builds universal binary for macOS and x86_64 binary for Linux, the file is available as artifact.

The code itself is ready for Windows, but the compiler doesn't link Swift runtime statically. So the exe is not able to run without Swift dlls, and the workflow to build for Windows is disabled.

## Build from Source

### Requirements

- Swift 5.8 (Backporting should be possible and easy)

### Build

```sh
$ swift package resolve
$ swift build
```

## Exploration Guide

### Prepare Files

All the files should be JSON.

1. Portal list file(s), should be an array of:
    ```jsonc
    {
        "guid": "GUID of Portal",
        "title": "Title of Portal",
        "lngLat": {
            "lng": 90.0,    // Longitude
            "lat": 45.0     // Latitude
        }
    }
    ```
2. Portal Key list file, should be an array of GUID (Not required but strongly recommended)

Maybe an IITC plugin like [this](https://github.com/lucka-me/toolkit/tree/master/Ingress/Portal-List-Exporter) helps.

### Usage

```
$ ingress-drone-explorer <portal-list-files> -s <longitude,latitude> [options...]
```

#### Options

Explore with key list:
```
$ ... -k <key-list-file>
```

Output cells JSON for IITC Draw tools:
```
$ ... --output-drawn-items <output-file>
```

Help information:
```
$ ingress-drone-explorer -h
```

## Benchmark

### Sample Data

- Area: Shenzhen downtown and Hong Kong
- Portals: 34,041 Portals in 13,451 cells
- Keys: 11 matched
- Start Point: Shenzhen Bay Sports Center
- Result: 30,462 Portals and 11,342 cells are reachable

### Result

Average exploration time consumed of 100 executions on MacBook Air (M2).

|                        | Lines           |  Commit                              | Consumed
| ---------------------: | :-------------: | :----------------------------------: | :---
|    [Swift][swift-repo] | ![][swift-loc]  | `Current`                            | 0.722 s
|        [C++][cpp-repo] | ![][cpp-loc]    | [`db5a976`][cpp-benchmark-commit]    | 0.583 s
| [Node.js][nodejs-repo] | ![][nodejs-loc] | [`7ad90e9`][nodejs-benchmark-commit] | 1.295 s
|  [Python][python-repo] | ![][python-loc] | [`841b9f0`][python-benchmark-commit] | 2.813 s

The results of other implementations may be outdated, please check their repositories for latest results.

[swift-repo]: https://github.com/lucka-me/ingress-drone-explorer-swift
[swift-loc]: https://img.shields.io/tokei/lines/github/lucka-me/ingress-drone-explorer-swift

[cpp-repo]: https://github.com/lucka-me/ingress-drone-explorer-cpp
[cpp-loc]: https://img.shields.io/tokei/lines/github/lucka-me/ingress-drone-explorer-cpp
[cpp-benchmark-commit]: https://github.com/lucka-me/ingress-drone-explorer-cpp/commit/db5a976

[nodejs-repo]: https://github.com/lucka-me/ingress-drone-explorer-nodejs
[nodejs-loc]: https://img.shields.io/tokei/lines/github/lucka-me/ingress-drone-explorer-nodejs
[nodejs-benchmark-commit]: https://github.com/lucka-me/ingress-drone-explorer-nodejs/commit/7ad90e9

[python-repo]: https://github.com/lucka-me/ingress-drone-explorer-python
[python-loc]: https://img.shields.io/tokei/lines/github/lucka-me/ingress-drone-explorer-python
[python-benchmark-commit]: https://github.com/lucka-me/ingress-drone-explorer-python/commit/841b9f0