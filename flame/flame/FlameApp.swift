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
        AppScreen(
            store: Store(
                initialState: AppReducer.State(
                    availableFireplaces: [],
                    selectedFireplace: nil
                ),
                reducer: {
                    AppReducer()
                }
            )
        )
    }
}
