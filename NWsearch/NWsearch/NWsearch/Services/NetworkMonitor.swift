import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    @Published private(set) var connectionType: ConnectionType = .none
    @Published private(set) var isConnected: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let type: ConnectionType
            if path.status != .satisfied {
                type = .none
            } else if path.usesInterfaceType(.wifi) {
                type = .wifi
            } else if path.usesInterfaceType(.cellular) {
                type = .cellular
            } else {
                type = .none
            }
            DispatchQueue.main.async {
                self.connectionType = type
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
