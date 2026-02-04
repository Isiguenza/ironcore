//
//  Iron_Core_WatchApp.swift
//  Iron Core Watch Watch App
//
//  Created by Iñaki Sigüenza on 03/02/26.
//

import SwiftUI

@main
struct Iron_Core_Watch_Watch_AppApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var workoutManager = WatchWorkoutManager.shared
    
    var body: some Scene {
        WindowGroup {
            RoutineListView()
                .environmentObject(connectivityManager)
                .environmentObject(workoutManager)
        }
    }
}
