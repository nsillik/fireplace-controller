//
//  FireplaceService.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Foundation
import SwiftUI

struct FireplaceService {
  let listFireplaces: (() async -> ([Fireplace]))
  let turnOffFireplace: ((Fireplace) async -> ())
  let turnOnFireplace: ((Fireplace, Int) async -> ())

  static var mock: FireplaceService {
    return .init {
      return [
        Fireplace(id: .init(), name: "Living Room", status: .off),
        Fireplace(id: .init(), name: "Bedroom", status: .on(timeRequested: 30, timeRemaining: 60*24.3))
      ]
    } turnOffFireplace: { _ in
      return
    } turnOnFireplace: { _, _ in
      return
    }
  }
  
  static var live: FireplaceService {
    return .init {
      assertionFailure("Not implemented")
      return []
    } turnOffFireplace: { _ in
      assertionFailure("Not implemented")
      return
    } turnOnFireplace: { _, _ in
      assertionFailure("Not implemented")
      return
    }
  }
  
  static var unconfigured: FireplaceService {
    return .init {
      assertionFailure("Not implemented")
      return []
    } turnOffFireplace: { _ in
      assertionFailure("Not implemented")
      return
    } turnOnFireplace: { _, _ in
      assertionFailure("Not implemented")
      return
    }
  }
}

struct FireplaceServiceEnvironmentKey: EnvironmentKey {
  static var defaultValue: FireplaceService = .unconfigured
}

extension EnvironmentValues {
  var fireplaceService: FireplaceService {
    get { self[FireplaceServiceEnvironmentKey.self] }
    set { self[FireplaceServiceEnvironmentKey.self] = newValue }
  }
}
