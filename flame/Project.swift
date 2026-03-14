import ProjectDescription

let project = Project(
    name: "Flame",
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "T9G4KUKSVP",
        ]
    ),
    targets: [
        .target(
            name: "Flame",
            destinations: .iOS,
            product: .app,
            bundleId: "org.sillik.flame",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(with: [
                "ITSAppUsesNonExemptEncryption": false,
                "UILaunchScreen": .dictionary([:]),
            ]),
            sources: ["flame/**/*.swift"],
            resources: [
                "flame/Assets.xcassets",
                "flame/Preview Content/**",
            ],
            entitlements: .file(path: "flame/flame.entitlements"),
            dependencies: [
                .external(name: "ComposableArchitecture"),
            ]
        ),
    ]
)
