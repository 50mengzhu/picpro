//
//  picproApp.swift
//  picpro
//
//  Created by mica dai on 2024/7/15.
//

import SwiftUI

@main
struct picproApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
