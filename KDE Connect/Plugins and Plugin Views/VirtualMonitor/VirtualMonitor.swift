// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import Combine

@objc class VirtualMonitor: NSObject, ObservablePlugin {
    @objc weak var controlDevice: Device!
    private var queryGeneration = 0
    private let protocolState = VirtualMonitorProtocol()
    @Published private(set) var availability = VMAvailability.unknown

    @objc init(controlDevice: Device) {
        self.controlDevice = controlDevice
        super.init()
    }

    func refresh() {
        queryGeneration += 1
        let generation = queryGeneration
        guard let device = controlDevice else { return }
        if let body = protocolState.request(paired: device.isPaired(), reachable: device.isReachable(), protocolVersion: device._deviceInfo.protocolVersion) {
            send(body: body, type: .virtualMonitorRequest)
        }
        availability = protocolState.availability
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self, self.queryGeneration == generation else { return }
            self.protocolState.expire()
            self.availability = self.protocolState.availability
        }
    }

    @objc func onDevicePacketReceived(np: NetworkPacket) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let device = self.controlDevice else { return }
            let reply = self.protocolState.receive(body: np._Body as? [AnyHashable: Any] ?? [:], type: np.type.rawValue, paired: device.isPaired(), reachable: device.isReachable(), protocolVersion: device._deviceInfo.protocolVersion)
            if let reply { self.send(body: reply, type: .virtualMonitor) }
            self.availability = self.protocolState.availability
        }
    }

    func suspend() {
        queryGeneration += 1
        _ = protocolState.request(paired: false, reachable: false, protocolVersion: 8)
        availability = protocolState.availability
    }

    func canOpenReceiver() -> Bool {
        guard let device = controlDevice else { return false }
        return protocolState.canOpen(paired: device.isPaired(), reachable: device.isReachable(), protocolVersion: device._deviceInfo.protocolVersion)
    }

    private func send(body: [AnyHashable: Any], type: NetworkPacket.`Type`) {
        guard let device = controlDevice, device.isPaired(), device.isReachable() else { return }
        let packet = NetworkPacket(type: type)
        packet._Body = NSMutableDictionary(dictionary: body)
        device.send(packet, tag: Int(PACKET_TAG_NORMAL))
    }
}
