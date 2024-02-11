import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                NavigationLink(
                    destination: CameraView(),
                    label: {
                        Image(systemName: "camera")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
