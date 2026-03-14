//
//  FlameApp.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct FlameApp: App {
    var body: some Scene {
        WindowGroup {
            screen
        }
    }
    
    var screen: some View {
//         MainScreen<LiveFireplaceService>()
//        .environmentObject(LiveFireplaceService(fireplaces: $fireplaces))
//        .tint(Color.orange)
//        .environment(\.colorScheme, .dark)
        AppScreen(
            store: Store(
                initialState: AppReducer.State(
                    availableFireplaces: [],
                    selectedFireplace: .init(ipAddress: "", name: "", status: .unknown)
                ),
                reducer: {
                    AppReducer()
                }
            )
        )
    }
}
