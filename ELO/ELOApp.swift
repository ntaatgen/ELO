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
                .keyboardShortcut("o", modifiers: [.command])
                Button("Add data...") {
                    model.loadData(add: true)
                }
                Divider()
                Button("Open Parameters Panel") {
                    openWindow(id: "parameters")  // ✅ tell SwiftUI which window to open
                }
                .keyboardShortcut("p", modifiers: [.command])
                
                Toggle(isOn: $model.lastLoaded, label: { Text("Last loaded students") })
                //                Toggle(isOn: $model.selectableNodeLabels, label: { Text("Selectable node labels")})
                Divider()
                Button("Run script...") {
                    model.runScript()
                }
                .keyboardShortcut("r", modifiers: [.command])
                Button("Split half analysis...") {
                    model.splitHalf()
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
                Divider()
                Button("Load new item vectors...") {
                    model.loadNewItemVectors()
                }
            }
            CommandGroup(replacing: CommandGroupPlacement.toolbar) {
                Button("Find optimal clusters") {
                    model.findOptimalClusters()
                }
                Button("Switch to clustered nodes") {
                    model.clusterNodes()
                }
                Divider()
                Toggle(isOn: $model.selectableNodeLabels, label: { Text("Selectable node labels")})
                Divider()
                Toggle(isOn: $model.studentMode, label: { Text("Student Mode")})
                Divider()
                Button("New Student") {
                    model.createNewStudent()
                }
                Divider()
            }
        }
        Window("Parameters", id: "parameters") {
            ParametersPanel(viewModel: model)
        }
    }
    @Environment(\.openWindow) private var openWindow
}
