//
//  ELOApp.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI

@main
struct ELOApp: App {
    let model = ELOViewModel()
    var body: some Scene {
        WindowGroup {
            MainContentView(model: model)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("Load data...") {
                    model.loadData()
                }
                Button("Synthetic data") {
                    model.generateData()
                }
            }
        }
    }
}
