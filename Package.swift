// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChipUI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ChipUI",
            targets: ["ChipUI"]
        )
    ],
    targets: [
        .target(
            name: "ChipUI",
            path: "ChipUI",
            exclude: [
                "AppDelegate.swift",
                "SceneDelegate.swift",
                "ViewController.swift",
                "CountriesListCollectionViewController.swift",
                "Info.plist",
                "Assets.xcassets",
                "Base.lproj"
            ],
            sources: [
                "ChipInputView.swift",
                "ChipCells.swift",
                "CollectionViewHelpers.swift",
                "AutocompleteOverlayView.swift"
            ]
        )
    ]
)
