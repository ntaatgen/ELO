//
//  ELOApp.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI

@main
struct ELOApp: App {
    @ObservedObject var model = ELOViewModel()
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
                Toggle(isOn: $model.lastLoaded, label: { Text("Last loaded students") })
//                Toggle(isOn: $model.selectableNodeLabels, label: { Text("Selectable node labels")})
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
            CommandGroup(replacing: CommandGroupPlacement.toolbar) {
                Toggle(isOn: $model.selectableNodeLabels, label: { Text("Selectable node labels")})
                Divider()
                Toggle(isOn: $model.studentMode, label: { Text("Student Mode")})
                Divider()
            }
        }
    }
}
