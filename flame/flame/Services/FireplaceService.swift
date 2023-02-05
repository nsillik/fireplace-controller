//
//  FireplaceService.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Foundation
import SwiftUI
import Network
import Combine

enum Command {
  case turnOff, getStatus, turnOn(minutes: UInt16)
  
  var commandValue: UInt16 {
    switch self {
    case .turnOff:
      return 0x0000
    case .getStatus:
      return 0x4000
    case .turnOn(let minutes):
      return 0x8000 | (0x3FFF & (minutes * 60))
    }
  }
}

protocol FireplaceService: ObservableObject {
  var fireplaces: [Fireplace] { get }
  func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async -> Fireplace
  func turnOffFireplace(_ fireplace: Fireplace) async -> Fireplace
}

class LiveFireplaceService: FireplaceService {
  @Published var fireplaces: [Fireplace] = [
    Fireplace(ipAddress: "192.168.1.81", name: "Bedroom", status: .off),
    //    Fireplace(ipAddress: "192.168.1.82", name: "Bedroom", status: .off)
  ]
  var cancellables = [AnyCancellable]()
  var fireplaceToConnection = [Fireplace: NWConnection]()
  
  init() {
    self.fireplaces.forEach { fireplace in
      self.connectTo(fireplace)
    }
    
    self.fireplaceToConnection.forEach { fireplace, connection in
      self.receive(fireplace: fireplace, connection: connection)
    }
    
    Timer.publish(every: 0.333, on: .main, in: .default)
      .autoconnect()
      .sink { _ in
        self.fireplaceToConnection.forEach { (fireplace: Fireplace, connection: NWConnection) in
          self.requestStatus(fireplace: fireplace, connection: connection)
          self.receive(fireplace: fireplace, connection: connection)
        }
      }
      .store(in: &cancellables)
  }
  
  func connectTo(_ fireplace: Fireplace) {
    let connection = NWConnection(host: .ipv4(.init(fireplace.ipAddress)!), port: .init(integerLiteral: 42069), using: .udp)
    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        print("ready")
        self.requestStatus(fireplace: fireplace, connection: connection)
        self.receive(fireplace: fireplace, connection: connection)
      case .setup:
        print("setup")
      case .cancelled:
        self.fireplaceToConnection.removeValue(forKey: fireplace)
        connection.cancel()
        self.connectTo(fireplace)
      case .preparing:
        print("Preparing")
      case .failed(let error):
        print("Failed: \(error)")
        self.connectTo(fireplace)
      case .waiting(let error):
        print("waiting: \(error)")
      @unknown default:
        print("unknown: \(state)")
      }
    }
    connection.start(queue: .global())
    self.fireplaceToConnection[fireplace] = connection
  }
  
  func requestStatus(fireplace: Fireplace, connection: NWConnection) {
    var message: Int16 = 0x4000 // Status
    connection.send(content: Data(bytes: &message, count: 2), completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
      print("sent: \(String(format: "0x%04x", message))")
    })))
  }
  
  func receive(fireplace: Fireplace, connection: NWConnection) {
    connection.receiveMessage { (data, context, isComplete, error) in
      guard let data = data else { return }
      print("Got \(data.count) bytes")
      guard data.count == 2 else { return }
      
      let returnedStatus = UInt16(data[1]) << 8 | UInt16(data[0])
      let status = Fireplace.Status.fromServerValue(returnedStatus)
      Task {
        await MainActor.run {
          self.fireplaces = self.fireplaces.map({ fireplace in
            var fireplace = fireplace
            if fireplace == fireplace {
              fireplace.status = status
            }
            return fireplace
          })
        }
      }
      print("\(status)")
    }
  }
  
  func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async -> Fireplace {
    guard let connection = self.fireplaceToConnection[fireplace] else {
      print("Unable to get connection for fireplace: \(fireplace.name)")
      return fireplace
    }
    let command = Command.turnOn(minutes: minutes)
    var commandValue = command.commandValue
    print("sending command: \(command) (\(String(format: "0x%04x", commandValue)))")
    connection.send(content: Data(bytes: &commandValue, count: 2), completion: .contentProcessed({ error in
      if let error = error {
        print("got error sending: \(error)")
      }
    }))
    return fireplace
  }
  
  func turnOffFireplace(_ fireplace: Fireplace) async -> Fireplace {
    guard let connection = self.fireplaceToConnection[fireplace] else {
      print("Unable to get connection for fireplace: \(fireplace.name)")
      return fireplace
    }
    let command = Command.turnOff
    var commandValue = command.commandValue
    print("sending command: \(command) (\(String(format: "0x%04x", commandValue)))")
    connection.send(content: Data(bytes: &commandValue, count: 2), completion: .contentProcessed({ error in
      if let error = error {
        print("got error sending: \(error)")
      }
    }))
    return fireplace
  }
}
