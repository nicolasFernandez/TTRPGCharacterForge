//
//  TTRPGCharacterForgeApp.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 26-12-22.
//

import SwiftUI
import SwiftData

@main
struct TTRPGCharacterForgeApp: App {
    @State private var compositionRoot = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            compositionRoot.coordinator.makeView()
                .modelContainer(compositionRoot.modelContainer)
        }
    }
}
