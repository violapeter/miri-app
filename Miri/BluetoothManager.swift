import CoreBluetooth
import Foundation

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    private var central: CBCentralManager!
    @Published var devices: [CBPeripheral] = []
    
    private var lastSeen: [UUID: Date] = [:]
    
    private var seenIDs: Set<UUID> = []
    
    private var pruneTimer: Timer?
    
    private let timeoutInterval: TimeInterval = 10
    private let pruneInterval: TimeInterval = 2
    
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        DispatchQueue.main.async {
            self.devices.removeAll()
        }
        lastSeen.removeAll()
        seenIDs.removeAll()
        
        guard central.state == .poweredOn else { return }
        
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        let serviceUUIDs = [CBUUID(string: "b00491cd-0c14-4d38-8781-d7a6e9b5547a")]
        central.scanForPeripherals(withServices: serviceUUIDs, options: options)
        
        startPruneTimerIfNeeded()
    }
    
    func stopScan() {
        central.stopScan()
        stopPruneTimer()
    }
    
    private func startPruneTimerIfNeeded() {
        guard pruneTimer == nil else { return }
        pruneTimer = Timer.scheduledTimer(withTimeInterval: pruneInterval, repeats: true) { [weak self] _ in
            self?.pruneStaleDevices()
        }
        RunLoop.main.add(pruneTimer!, forMode: .common)
    }
    
    private func stopPruneTimer() {
        pruneTimer?.invalidate()
        pruneTimer = nil
    }
    
    private func pruneStaleDevices() {
        let cutoff = Date().addingTimeInterval(-timeoutInterval)
        
        let staleUUIDs = lastSeen.filter { $0.value < cutoff }.map { $0.key }
        guard !staleUUIDs.isEmpty else { return }
        
        staleUUIDs.forEach {
            lastSeen.removeValue(forKey: $0)
            seenIDs.remove($0)
        }
        
        DispatchQueue.main.async {
            self.devices.removeAll { peripheral in
                staleUUIDs.contains(peripheral.identifier)
            }
        }
    }
        
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScan()
        case .resetting, .unsupported, .unauthorized, .unknown, .poweredOff:
            stopScan()
            DispatchQueue.main.async {
                self.devices.removeAll()
            }
            lastSeen.removeAll()
            seenIDs.removeAll()
            print("Bluetooth állapot: \(central.state.rawValue)")
        @unknown default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        lastSeen[peripheral.identifier] = Date()
        
        let id = peripheral.identifier
        let isNew = seenIDs.insert(id).inserted
        guard isNew else { return }
        
        DispatchQueue.main.async {
            if !self.devices.contains(where: { $0.identifier == id }) {
                self.devices.append(peripheral)
            }
        }
    }
}
