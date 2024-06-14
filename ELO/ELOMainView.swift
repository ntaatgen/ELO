//
//  ELOMainView.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI
import Charts
@available(macOS 13.0,*)

struct ELOMainView: View {
    @ObservedObject var model: ELOViewModel
    @State private var epochs: String = "1000"
    @State private var aItems: String = "0.005"
    @State private var aSubjects: String = "0.05"
    @State private var aHebb: String = "0.025"
    @State private var nSkills: String = "4"
    @State private var pickedTime: Int = 0

    func pickerContent() -> some View {
        ForEach(model.timeList, id:\.self) {
            Text(String($0))
        }
    }
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Button(action: { model.back() }) {
                        Label("Back", systemImage: "arrowshape.left")
                    }
                    Button(action: { model.forward() }) {
                        Label("Forward", systemImage: "arrowshape.right")
                    }
                    Button(action: { model.switchGraphs()}) {
                        Label("Switch graphs", systemImage: "play")
                    }
                    switch model.graphSelected {
                    case .items:
                        Text("Showing Items")
                    case .students:
                        Text("Showing Students")
                    case .errors:
                        Text("Showing Errors")
                    }
                    Spacer()
                    
                    Button(action: { model.reset()}) {
                        Label("Reset", systemImage: "eraser")
                    }
                    Picker("Time: ", selection: $pickedTime) {
                        pickerContent()
                    }
                    .pickerStyle(.automatic)
                    Button(action: { model.run(time: pickedTime) }){
                        Label("Run", systemImage: "play")
                    }
                }
                HStack {
                    Text("Epochs:")
                    TextField("Epochs", text: $epochs, onEditingChanged: {changed in model.changeEpochs(epochs)})
                    Text("alphaItems:")
                    TextField("aItems", text: $aItems, onEditingChanged: {changed in model.changeAItems(aItems)})
                    Text("alphaSubjects:")
                    TextField("aSubs", text: $aSubjects, onEditingChanged: {changed in model.changeASubjects(aSubjects)})
                    Text("alphaHebb:")
                    TextField("aHebb", text: $aHebb, onEditingChanged: {changed in model.changeAHebb(aHebb)})
                    Text("# Skills:")
                    TextField("nSkills", text: $nSkills, onEditingChanged: {changed in model.changeNSkills(nSkills)})
                    Spacer()
                }
                if model.selected != nil {
                    switch model.graphSelected {
                    case .items: if model.selected! < model.sortedKeys.count {
                        Text(model.sortedKeys[model.selected!])
                    }
                    case .students: if model.selected! < model.studentKeys.count {
                        Text(model.studentKeys[model.selected!])
                    }
                    case .errors: Text("Final error " + String(model.results.last!.y))
                        
                    }
                }
                HStack {
                    if model.graphSelected == .errors {
                        Chart(model.results) {
                            LineMark(x: .value("Training", $0.x),
                                     y: .value("Score",$0.y),
                                     series: .value("Index",$0.z)
                            )
                            .foregroundStyle(model.colors[$0.z])
                            //                .foregroundStyle(by: .value("Index", $0.z + 1))
                        }
                        .chartYScale(domain: model.resultsLWB...model.resultsUPB)
                        
                    } else {
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
                }
                GraphView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
            .padding()
            ScrollView {
                Text(model.trace)
            }
            Spacer()
        }
    }
}

//#Preview {
//    ContentView()
//}
