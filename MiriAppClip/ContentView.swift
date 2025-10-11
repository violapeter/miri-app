import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Connecting to your Miri...")
            ProgressView()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
