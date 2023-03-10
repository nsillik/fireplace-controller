//
//  flameApp.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI

@main
struct flameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView<LiveFireplaceService>()
            .environmentObject(LiveFireplaceService())
            .tint(Color.orange)
        }
    }
}
