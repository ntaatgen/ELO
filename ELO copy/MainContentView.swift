//
//  ContentView.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI
import Charts
@available(macOS 13.0,*)

struct MainContentView: View {
    @ObservedObject var model: ELOViewModel
    @State private var epochs: String = "1"
    @State private var aItems: String = "0.005"
    @State private var aSubjects: String = "0.05"
    var body: some View {
        VStack {
            HStack {
                Button(action: { model.back() }) {
                    Label("Back", systemImage: "play")
                }
                Button(action: { model.forward() }) {
                    Label("Forward", systemImage: "play")
                }
                Text("Epochs:")
                TextField("Epochs", text: $epochs, onEditingChanged: {changed in model.changeEpochs(epochs)})
                Text("alphaItems:")
                TextField("aItems", text: $aItems, onEditingChanged: {changed in model.changeAItems(aItems)})
                Text("alphaSubjects:")
                TextField("aSubs", text: $aSubjects, onEditingChanged: {changed in model.changeASubjects(aSubjects)})
                Button(action: { model.rerun() }){
                    Label("Run", systemImage: "play")
                }
            }
            if model.selected != nil && model.selected! < model.sortedKeys.count {
                Text(model.sortedKeys[model.selected!])
            }
            HStack {
                Chart(model.results) {
                    LineMark(x: .value("Training", $0.x),
                             y: .value("Score",$0.y),
                             series: .value("Index",$0.z)
                    )
                    .foregroundStyle(model.colors[$0.z])
                    //                .foregroundStyle(by: .value("Index", $0.z + 1))
                }
                .chartYScale(domain: 0...1)

            }
            PrimGraphView(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
        }
        .padding()
    }
}

//#Preview {
//    ContentView()
//}
