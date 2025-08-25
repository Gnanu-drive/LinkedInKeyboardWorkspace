//
//  LinkedInCompanionAppApp.swift
//  LinkedInCompanionApp
//
//  Created by Gnanendra Naidu N on 19/06/25.
//
//
//import SwiftUI
//
//@main
//struct LinkedInCompanionAppApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

import SwiftUI

@main
struct LinkedInCompanionAppApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                AIWorker.shared.processRequests()
            }
        }
    }
}
