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
        var selectedFireplace: Fireplace? = nil
        var currentTime: UInt16 = 30
        var isOn: Bool {
            if case .on = selectedFireplace?.status {
                return true
            } else {
                return false
            }
        }
    }
    
    enum Action {
        case didLoad
        case fireplaceStatusUpdated([Fireplace])
        case selectFireplace(Fireplace?)
        case turnOffFireplace(Fireplace)
        case turnOnFireplace(Fireplace)
        case incrementTime(Int16)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didLoad:
                if state.selectedFireplace == nil {
                    state.selectedFireplace = state.availableFireplaces.first
                }
                
                return .run { send in
                    let fireplaces = await fireplaceService.fireplaces
                    await send(.fireplaceStatusUpdated(fireplaces))
                    for await fireplaces in await fireplaceService.fireplaceUpdates() {
                        await send(.fireplaceStatusUpdated(fireplaces))
                    }
                }
            case .fireplaceStatusUpdated(let fireplaces):
                state.availableFireplaces = fireplaces
                if let updated = fireplaces.first(where: { $0.id == state.selectedFireplace?.id }) {
                    state.selectedFireplace = updated
                }

                return .none
            case .selectFireplace(let fireplace):
                guard let fireplace else { return .none }
                state.selectedFireplace = fireplace
                return .none
            case .turnOffFireplace(let fireplace):
                let fireplace = fireplace
                return .run { _ in
                    await fireplaceService.turnOffFireplace(fireplace)
                }
            case .turnOnFireplace(let fireplace):
                let currentTime = state.currentTime
                return .run { _ in
                    await fireplaceService.turnOnFireplace(fireplace, minutes: currentTime)
                }
            case .incrementTime(let minutes):
                state.currentTime = UInt16(max(min(Int16(state.currentTime) + minutes, 120), 0))
                return .none
            }
        }
    }
}
