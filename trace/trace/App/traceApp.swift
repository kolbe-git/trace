//
//  traceApp.swift
//  trace
//

import SwiftUI
import SwiftData

@main
struct traceApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Workout.self,
            RouteSample.self,
            Split.self,
            Goal.self,
            UserProfile.self,
        ])
        // cloudKitDatabase: .automatic —— 配了 iCloud/CloudKit 能力时自动同步私有库，
        // 没配能力时退化为纯本地存储。
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
