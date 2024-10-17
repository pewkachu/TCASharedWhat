//
//  TCASharedWhatApp.swift
//  TCASharedWhat
//
//  Created by oantoniuk on 17.10.2024.
//

import ComposableArchitecture
import SwiftUI

@main
struct TCASharedWhatApp: App {

    init() {
        Task {
            try await Task.sleep(for: .seconds(1))
            @Shared(.sharedThing) var thing

            while (true) {
                thing.isOk.toggle()
                try await Task.sleep(for: .seconds(2))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: Feature.State(), reducer: {
                Feature()
            }))
        }
    }
}
