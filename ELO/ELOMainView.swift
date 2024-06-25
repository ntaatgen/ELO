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
//                    TextField("Epochs", text: $epochs, onEditingChanged: {changed in model.changeEpochs(epochs)})
                    TextField("Epochs", text: $model.nEpochsV)
                        .onChange(of: model.nEpochsV) { model.nEpochsV = model.changeEpochs(model.nEpochsV) }
                    Text("alphaItems:")
                    TextField("aItems", text: $model.alphaItemsV) //, onEditingChanged: {changed in model.changeAItems(aItems)})
                        .onChange(of: model.alphaItemsV) { model.alphaItemsV = model.changeAItems(model.alphaItemsV) }
                    Text("alphaSubjects:")
                    TextField("aSubs", text: $model.alphaStudentV) //, onEditingChanged: {changed in model.changeASubjects(aSubjects)})
                        .onChange(of: model.alphaStudentV) { model.alphaStudentV = model.changeASubjects(model.alphaStudentV)}
                    Text("alphaHebb:")
                    TextField("aHebb", text: $model.alphaHebbV) //, onEditingChanged: {changed in model.changeAHebb(aHebb)})
                        .onChange(of: model.alphaHebbV) { model.alphaHebbV = model.changeAHebb(model.alphaHebbV)}
                    Text("# Skills:")
                    TextField("nSkills", text: $model.nSkillsV) // , onEditingChanged: {changed in model.changeNSkills(nSkills)})
                        .onChange(of: model.nSkillsV) { model.nSkillsV = model.changeNSkills(model.nSkillsV)}
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
                VSplitView {
                    //                HStack {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    //                }
                    GraphView(model: model)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            ScrollView {
                Text(model.trace)
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
