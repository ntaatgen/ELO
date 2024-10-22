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
        VStack {
            ForEach(model.timeList, id:\.self) {
                Text(String($0))
            }
        }
    }
    
    var body: some View {
        //        HStack {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Button(action: { model.back() }) {
                        Label("Back", systemImage: "arrowshape.left")
                    }
                    .padding()
                    Button(action: { model.forward() }) {
                        Label("Forward", systemImage: "arrowshape.right")
                    }
                    .padding()
                    Button(action: { model.switchGraphs()}) {
                        Label("Switch graphs", systemImage: "play")
                    }
                    .padding()
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
                    .padding()
                    Picker("Time: ", selection: $pickedTime) {
                        ForEach(model.timeList, id:\.self) {
                            Text(String($0))
                        }
                        //                        pickerContent()
                    }
                    .pickerStyle(.automatic)
                    .padding()
                    Button(action: { model.run(time: pickedTime) }){
                        Label("Run", systemImage: "play")
                    }
                    .padding()
                    Button(action: {model.run(time: nil)}) {
                        Label("Run All", systemImage: "play")
                    }
                    .padding()
                }
                HStack {
                    Text("Epochs:")
                    TextField("Epochs", text: $model.nEpochsV)
                        .onChange(of: model.nEpochsV) { model.nEpochsV = model.changeEpochs(model.nEpochsV) }
                    Text("alpha:")
                    TextField("aItems", text: $model.alphaV)
                        .onChange(of: model.alphaV) { model.alphaV = model.changeAlpha(model.alphaV) }
                    //                    Text("alphaSubjects:")
                    //                    TextField("aSubs", text: $model.alphaStudentV)
                    //                        .onChange(of: model.alphaStudentV) { model.alphaStudentV = model.changeASubjects(model.alphaStudentV)}
                    Text("alphaHebb:")
                    TextField("aHebb", text: $model.alphaHebbV)
                        .onChange(of: model.alphaHebbV) { model.alphaHebbV = model.changeAHebb(model.alphaHebbV)}
                    Text("# Skills:")
                    TextField("nSkills", text: $model.nSkillsV)
                        .onChange(of: model.nSkillsV) { model.nSkillsV = model.changeNSkills(model.nSkillsV)}
                    Spacer()
                }
                
                HSplitView {
                    VSplitView {
                        HStack {
                            Spacer()
                            
                            if model.selected != nil {
                                switch model.graphSelected {
                                case .items: if model.selected! < model.sortedKeys.count {
                                    Text(model.sortedKeys[model.selected!])
                                        .frame(height: 15)
                                }
                                case .students: if model.selected! < model.studentKeys.count {
                                    Text(model.studentKeys[model.selected!])
                                        .frame(height: 15)
                                }
                                case .errors: Text("Final error " + String(model.results.last!.y))
                                        .frame(height: 15)
                                }
                            }
                            Spacer()
                        }
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
                            }
                            .chartYScale(domain: 0...1)
                            .chartXScale(domain: model.resultsLowestX...model.resultsHighestX)
                            .chartLegend(position: .bottom)
                            .chartForegroundStyleScale(model.chartLegendLabels)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        GraphView(model: model)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VSplitView {
                        ScrollView {
                            Text(model.trace)
                                .frame(maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
                        }
                        if !model.currentItemImages.isEmpty {
                            ScrollView {
                                ForEach(model.currentItemImages, id:\.self) {img in
                                    Image(nsImage: img)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        }
                        
                        
                    }
                }
            }
            .sheet(isPresented: $model.openSheet) {
                if model.queryItem != nil {
                    ItemView(model: model, itemInfo: model.queryItem!, groupsize: model.queryItem!.questions.count)
                        .frame(minWidth: geometry.size.width * 0.7)
                    //                        .frame(minWidth: model.queryItem!.image?.size.width ?? 0, minHeight: model.queryItem!.image?.size.height ?? 0)
                }
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
