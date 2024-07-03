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
                Button("Add data...") {
                    model.loadData(add: true)
                }
                Divider()
                Button("Run script...") {
                    model.runScript()
                }
                Divider()
                Button("Synthetic data full graph") {
                    model.generateData(set: 0)
                }
                Button("Synthetic data reduced graph") {
                    model.generateData(set: 1)
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
                Button("Write output file, last only...") {
                    model.writeDataFile(lastonly: true)
                }
            }
        }
    }
}
