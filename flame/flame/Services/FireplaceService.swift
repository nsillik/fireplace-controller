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
import ComposableArchitecture
import os

private let logger = Logger(subsystem: "flame", category: "fireplace")
private let fireplacePort: UInt16 = 42069

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

@MainActor
protocol FireplaceService {
    var fireplaces: [Fireplace] { get }
    var defaultMinutes: UInt16 { get }
    func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async
    func turnOffFireplace(_ fireplace: Fireplace) async
    func fireplaceUpdates() -> AsyncStream<[Fireplace]>
}

@MainActor
@Observable
class LiveFireplaceService: FireplaceService {
    var defaultMinutes: UInt16 = 30

    var fireplaces: [Fireplace]
    var cancellables = [AnyCancellable]()
    var fireplaceToConnection = [Fireplace.ID: NWConnection]()
    private var reconnectAttempts = [Fireplace.ID: Int]()

    init(fireplaces: [Fireplace]) {
        self.fireplaces = fireplaces
        for fireplace in self.fireplaces {
            connectTo(fireplace)
        }

        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                for (_, connection) in self.fireplaceToConnection {
                    self.requestStatus(connection: connection)
                }
            }
            .store(in: &cancellables)
    }

    func connectTo(_ fireplace: Fireplace) {
        let connection = NWConnection(host: .ipv4(.init(fireplace.ipAddress)!), port: .init(integerLiteral: fireplacePort), using: .udp)
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    logger.info("Connection ready for \(fireplace.name)")
                    self.reconnectAttempts[fireplace.id] = 0
                    self.requestStatus(connection: connection)
                case .setup:
                    logger.debug("Connection setup for \(fireplace.name)")
                case .cancelled:
                    self.fireplaceToConnection.removeValue(forKey: fireplace.id)
                    self.reconnectWithBackoff(fireplace)
                case .preparing:
                    logger.debug("Connection preparing for \(fireplace.name)")
                case let .failed(error):
                    logger.error("Connection failed for \(fireplace.name): \(error)")
                    connection.cancel()
                    self.fireplaceToConnection.removeValue(forKey: fireplace.id)
                    self.reconnectWithBackoff(fireplace)
                case let .waiting(error):
                    logger.info("Connection waiting for \(fireplace.name): \(error)")
                @unknown default:
                    logger.warning("Unknown connection state for \(fireplace.name): \(String(describing: state))")
                }
            }
        }
        connection.start(queue: .global())
        self.receive(fireplace: fireplace, connection: connection)
        fireplaceToConnection[fireplace.id] = connection
    }

    private func reconnectWithBackoff(_ fireplace: Fireplace) {
        let attempt = reconnectAttempts[fireplace.id, default: 0]
        reconnectAttempts[fireplace.id] = attempt + 1
        let delay = min(pow(2.0, Double(attempt)), 30.0)
        logger.info("Reconnecting to \(fireplace.name) in \(delay)s (attempt \(attempt + 1))")
        Task {
            try? await Task.sleep(for: .seconds(delay))
            self.connectTo(fireplace)
        }
    }

    func requestStatus(connection: NWConnection) {
        var message = Command.getStatus.commandValue
        connection.send(content: Data(bytes: &message, count: 2), completion: NWConnection.SendCompletion.contentProcessed(({ _ in
            logger.debug("Sent status request: \(String(format: "0x%04x", message))")
        })))
    }

    func receive(fireplace: Fireplace, connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, _ in
            guard let data = data else {
                Task { @MainActor in
                    self?.receive(fireplace: fireplace, connection: connection)
                }
                return
            }
            logger.debug("Got \(data.count) bytes from \(fireplace.name)")
            guard data.count == 2 else {
                Task { @MainActor in
                    self?.receive(fireplace: fireplace, connection: connection)
                }
                return
            }

            let returnedStatus = UInt16(data[1]) << 8 | UInt16(data[0])
            let status = Fireplace.Status.fromServerValue(returnedStatus)
            Task { @MainActor in
                self?.fireplaces = self?.fireplaces.map { existing in
                    var updated = existing
                    if existing.id == fireplace.id {
                        updated.status = status
                        logger.debug("Updated \(fireplace.name) status: \(String(describing: status))")
                    }
                    return updated
                } ?? []
                self?.receive(fireplace: fireplace, connection: connection)
            }
        }
    }

    func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async {
        guard let connection = fireplaceToConnection[fireplace.id] else {
            logger.error("Unable to get connection for fireplace: \(fireplace.name)")
            return
        }
        let command = Command.turnOn(minutes: minutes)
        var commandValue = command.commandValue
        logger.info("Sending command: \(String(describing: command)) (\(String(format: "0x%04x", commandValue)))")
        connection.send(content: Data(bytes: &commandValue, count: 2), completion: .contentProcessed { error in
            if let error = error {
                logger.error("Error sending turn on: \(error)")
            }
        })
    }

    func fireplaceUpdates() -> AsyncStream<[Fireplace]> {
        AsyncStream { continuation in
            Task { @MainActor in
                while !Task.isCancelled {
                    await withCheckedContinuation { resume in
                        withObservationTracking {
                            _ = self.fireplaces
                        } onChange: {
                            Task { @MainActor in
                                resume.resume()
                            }
                        }
                    }
                    continuation.yield(self.fireplaces)
                }
                continuation.finish()
            }
        }
    }

    func turnOffFireplace(_ fireplace: Fireplace) async {
        guard let connection = fireplaceToConnection[fireplace.id] else {
            logger.error("Unable to get connection for fireplace: \(fireplace.name)")
            return
        }
        let command = Command.turnOff
        var commandValue = command.commandValue
        logger.info("Sending command: \(String(describing: command)) (\(String(format: "0x%04x", commandValue)))")
        connection.send(content: Data(bytes: &commandValue, count: 2), completion: .contentProcessed { error in
            if let error = error {
                logger.error("Error sending turn off: \(error)")
            }
        })
    }
}

@MainActor
class PreviewFireplaceService: FireplaceService {
    var defaultMinutes: UInt16 = 30

    @Published var fireplaces: [Fireplace] = [
        .init(ipAddress: "a", name: "Living Room", status: .off),
        .init(ipAddress: "b", name: "Bedroom", status: .on(timeRemaining: 30.0 * 60.0)),
        .init(ipAddress: "c", name: "Dungeon", status: .off),
    ]

    func fireplaceUpdates() -> AsyncStream<[Fireplace]> {
        AsyncStream { continuation in
            let cancellable = $fireplaces
                .removeDuplicates()
                .sink { fireplaces in
                    continuation.yield(fireplaces)
                }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    func turnOnFireplace(_ fireplace: Fireplace, minutes: UInt16) async {
        fireplaces = fireplaces.map { f in
            var new = f
            if f == fireplace {
                new.status = .on(timeRemaining: Double(minutes) * 60.0)
            }
            return new
        }
    }

    func turnOffFireplace(_ fireplace: Fireplace) async {
        fireplaces = fireplaces.map { f in
            var new = f
            if f == fireplace {
                new.status = .off
            }
            return new
        }
    }
}

enum FireplaceServiceKey: @preconcurrency DependencyKey {
    @MainActor static let liveValue: any FireplaceService = LiveFireplaceService(fireplaces: [
        Fireplace(ipAddress: "192.168.1.81", name: "Bedroom", status: .off),
        Fireplace(ipAddress: "192.168.1.82", name: "Living Room", status: .off)
    ])
    @MainActor static let previewValue: any FireplaceService = PreviewFireplaceService()
}

extension DependencyValues {
  var fireplaceService: any FireplaceService {
    get { self[FireplaceServiceKey.self] }
    set { self[FireplaceServiceKey.self] = newValue }
  }
}
