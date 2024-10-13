//
//  FlameApp.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

@main
struct FlameApp: App {
    @State var fireplaces: [Fireplace] = [
        Fireplace(ipAddress: "192.168.1.81", name: "Bedroom", status: .off),
        //    Fireplace(ipAddress: "192.168.1.82", name: "Bedroom", status: .off)
    ]
    var body: some Scene {
        WindowGroup {
            MainScreen<LiveFireplaceService>()
                .environmentObject(LiveFireplaceService(fireplaces: $fireplaces))
                .tint(Color.orange)
                .environment(\.colorScheme, .dark)
        }
    }
}
