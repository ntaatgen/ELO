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
            ELOMainView(model: model)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("Load data...") {
                    model.loadData()
                }
                Button("Synthetic data") {
                    model.generateData()
                }
                Divider()
                Button("Save model...") {
                    model.saveModel()
                }
                Button("Load model...") {
                    model.loadModel()
                }
                Divider()
                Button("Write output file...") {
                    model.writeDataFile()
                }
            }
        }
    }
}
