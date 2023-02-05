//
//  Fireplace.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Foundation

struct Fireplace: Identifiable, Equatable, Hashable {

  static func ==(lhs: Fireplace, rhs: Fireplace) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  var id: String {
    return ipAddress
  }
  var ipAddress: String
  var name: String
  var status: Status

  enum Status: Equatable, Hashable {
    case off, on(timeRemaining: TimeInterval), unknown

    static func fromServerValue(_ value: UInt16) -> Self {
      if value >> 14 == 0 {
        return .off
      } else if value & 0x8000 != 0 {
        let timeInt = value & 0x3FFF
        let time = TimeInterval(timeInt)
        return .on(timeRemaining: time)
      }
      return .unknown
    }
  }
}
