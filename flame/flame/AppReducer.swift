//
//  AppReducer.swift
//  Flame
//
//  Created by Nick Sillik on 3/9/26.
//

import ComposableArchitecture

@Reducer
struct AppReducer {
    @Dependency(\.fireplaceService) var fireplaceService
    
    @ObservableState
    struct State {
        var availableFireplaces: [Fireplace] = []
        var selectedFireplace: Fireplace = .init(ipAddress: "", name: "", status: .unknown)
        var currentTime: UInt16 = 30
        var isOn = false
    }
    
    enum Action {
        case didLoad
        case selectFireplace(Fireplace?)
        case turnOffFireplace(Fireplace)
        case turnOnFireplace(Fireplace)
        case incrementTime(Int16)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didLoad:
                state.availableFireplaces = fireplaceService.fireplaces
                state.selectedFireplace = fireplaceService.fireplaces.first!
                return .publisher {
                    fireplaceService.fireplaces.publisher
                        .removeDuplicates()
                        .map { _ in
                                .didLoad
                        }
                }
            case .selectFireplace(let fireplace):
                guard let fireplace else { return .none }
                state.selectedFireplace = fireplace
                return .none
            case .turnOffFireplace(let fireplace):
                let fireplace = fireplace
                return .run { send in
                    await fireplaceService.turnOffFireplace(fireplace)
                }
            case .turnOnFireplace(let fireplace):
                let currentTime = state.currentTime
                return .run { end in
                    await fireplaceService.turnOnFireplace(fireplace, minutes: currentTime)
                }
            case .incrementTime(let minutes):
                state.currentTime = UInt16(max(min(Int16(state.currentTime) + minutes, 120), 0))
                return .none
            }
        }
    }
}
