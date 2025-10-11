import SwiftUI

struct ContentView: View {
    @StateObject private var btManager = BluetoothManager()
        
        var body: some View {
            VStack {
                if btManager.devices.isEmpty {
                    Text("Üdv az appban!")
                        .font(.largeTitle)
                        .padding()
                    Text("Keresés közeli eszközök után…")
                        .padding(.top, 8)
                } else {
                    List(btManager.devices, id: \.identifier) { device in
                        Text(device.name ?? "Ismeretlen eszköz")
                    }
                }
            }
            .onAppear {
                btManager.startScan()
            }
        }
}

#Preview {
    ContentView()
}
