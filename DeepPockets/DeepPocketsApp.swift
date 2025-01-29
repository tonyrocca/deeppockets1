import SwiftUI

@main
struct DeepPocketsApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WelcomeView()
            }
            .preferredColorScheme(.dark)
        }
    }
}
