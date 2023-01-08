//
//  Fireplace.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Foundation

struct Fireplace: Identifiable, Equatable {
  var id: UUID
  var name: String
  var status: Status

  enum Status: Equatable {
    case off, on(timeRequested: Int, timeRemaining: TimeInterval)
  }
}
