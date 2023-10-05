//
//  flameApp.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

@main
struct FlameApp: App {
    var body: some Scene {
        WindowGroup {
            MainScreen<LiveFireplaceService>()
            .environmentObject(LiveFireplaceService())
            .tint(Color.orange)
        }
    }
}
