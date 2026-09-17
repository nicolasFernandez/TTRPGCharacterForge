//
//  Coordinator.swift
//  TTRPGCharacterForge
//
//  Created by Nicolas Alonso Fernandez Alarcon on 12-11-25.
//

import SwiftUI

final class Coordinator {
    private unowned let compositionRoot: CompositionRoot

    init(compositionRoot: CompositionRoot) {
        self.compositionRoot = compositionRoot
    }

    @ViewBuilder
    func makeView() -> some View {
        ContentView(compositionRoot: compositionRoot)
    }
}
