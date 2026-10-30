import SwiftUI
import AVFoundation

@main
struct MusicOnlyApp: App {
    init() {
        // Lets audio keep playing when the screen locks or the app is backgrounded.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea(.container, edges: .bottom)
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark)
        }
    }
}
