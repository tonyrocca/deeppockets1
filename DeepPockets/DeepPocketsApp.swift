//
//  DeepPocketsApp.swift
//  DeepPockets
//
//  Created by Tony Rocca on 12/10/24.
//

import SwiftUI

@main
struct DeepPocketsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
