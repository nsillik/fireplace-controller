//
//  FireplaceService.swift
//  flame
//
//  Created by Nick Sillik on 1/7/23.
//

import Combine
import Foundation
import Network
import SwiftUI

enum Command {
    case turnOff, getStatus, turnOn(minutes: UInt16)

    var commandValue: UInt16 {
        switch self {
        case .turnOff:
            return 0x0000
        case .getStatus:
            return 0x4000
        case let .turnOn(minutes):
            return 0x8000 | (0x3FFF & (minutes * 60))
        }
    }
}

protocol FireplaceService: ObservableObject {
    var fireplaces: [Fireplace] { get }
    var defaultMinutes: UInt16 { get }
    func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async -> Fireplace
    func turnOffFireplace(_ fireplace: Fireplace) async -> Fireplace
}

class LiveFireplaceService: FireplaceService {
    var defaultMinutes: UInt16 = 30

    @Binding var fireplaces: [Fireplace]
    var cancellables = [AnyCancellable]()
    var fireplaceToConnection = [Fireplace: NWConnection]()

    init(fireplaces: Binding<[Fireplace]>) {
        _fireplaces = fireplaces
        for fireplace in self.fireplaces {
            connectTo(fireplace)
        }

        for (fireplace, connection) in fireplaceToConnection {
            receive(fireplace: fireplace, connection: connection)
        }

        Timer.publish(every: 20, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                for (fireplace, connection) in self.fireplaceToConnection {
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
            case let .failed(error):
                print("Failed: \(error)")
                self.connectTo(fireplace)
            case let .waiting(error):
                print("waiting: \(error)")
            @unknown default:
                print("unknown: \(state)")
            }
        }
        connection.start(queue: .global())
        fireplaceToConnection[fireplace] = connection
    }

    func requestStatus(fireplace _: Fireplace, connection: NWConnection) {
        var message: Int16 = 0x4000 // Status
        connection.send(content: Data(bytes: &message, count: 2), completion: NWConnection.SendCompletion.contentProcessed(({ _ in
            print("sent: \(String(format: "0x%04x", message))")
        })))
    }

    func receive(fireplace: Fireplace, connection: NWConnection) {
        connection.receiveMessage { data, _, _, _ in
            guard let data = data else { return }
            print("Got \(data.count) bytes")
            guard data.count == 2 else { return }

            let returnedStatus = UInt16(data[1]) << 8 | UInt16(data[0])
            let status = Fireplace.Status.fromServerValue(returnedStatus)
            Task {
                await MainActor.run {
                    self.fireplaces = self.fireplaces.map { fireplace in
                        var fireplace = fireplace
                        if fireplace == fireplace {
                            fireplace.status = status
                            print("\(fireplace.status)")
                        }
                        return fireplace
                    }
                }
            }
        }
    }

    func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async -> Fireplace {
        guard let connection = fireplaceToConnection[fireplace] else {
            print("Unable to get connection for fireplace: \(fireplace.name)")
            return fireplace
        }
        let command = Command.turnOn(minutes: minutes)
        var commandValue = command.commandValue
        print("sending command: \(command) (\(String(format: "0x%04x", commandValue)))")
        connection.send(content: Data(bytes: &commandValue, count: 2), completion: .contentProcessed { error in
            if let error = error {
                print("got error sending: \(error)")
            }
        })
        return fireplace
    }

    func turnOffFireplace(_ fireplace: Fireplace) async -> Fireplace {
        guard let connection = fireplaceToConnection[fireplace] else {
            print("Unable to get connection for fireplace: \(fireplace.name)")
            return fireplace
        }
        let command = Command.turnOff
        var commandValue = command.commandValue
        print("sending command: \(command) (\(String(format: "0x%04x", commandValue)))")
        connection.send(content: Data(bytes: &commandValue, count: 2), completion: .contentProcessed { error in
            if let error = error {
                print("got error sending: \(error)")
            }
        })
        return fireplace
    }
}

class PreviewFireplaceService: FireplaceService {
    var defaultMinutes: UInt16 = 30

    @Published var fireplaces: [Fireplace] = [
        .init(ipAddress: "a", name: "Living Room", status: .off),
        .init(ipAddress: "b", name: "Bedroom", status: .on(timeRemaining: 30.0 * 60.0)),
        .init(ipAddress: "c", name: "Dungeon", status: .off),
    ]

    func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async -> Fireplace {
        fireplaces = fireplaces.map { f in
            var new = f
            if f == fireplace {
                new.status = .on(timeRemaining: Double(minutes) * 60.0)
            }
            return new
        }
        return fireplaces.first(where: { $0 == fireplace })! // TODO(nsillik): Get rid of the `!`
    }

    func turnOffFireplace(_ fireplace: Fireplace) async -> Fireplace {
        fireplaces = fireplaces.map { f in
            var new = f
            if f == fireplace {
                new.status = .off
            }
            return new
        }
        return fireplaces.first(where: { $0.id == fireplace.id })! // TODO(nsillik): Get rid of the `!`
    }
}
