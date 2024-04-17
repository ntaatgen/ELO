//
//  ELOmain.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI


class ELOViewModel: ObservableObject {
    
    @Published private var model: ELOmodel
    
    var graphData: GraphData? {
        model.graphData
    }
    
    init() {
        model = ELOmodel()
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.updatePrimsGraph(_:)), name: NSNotification.Name(rawValue: "UpdatePrimsGraph"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.updateAll(_:)), name: NSNotification.Name(rawValue: "UpdateAll"), object: nil)
    }
    
    func loadData() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                model.loadData(filePath: url)
            }
        }
    }
    
    func generateData() {
        model.generateData()
    }
    
    func changeEpochs(_ epochs: String) {
        if let numval = Int(epochs) {
            model.setEpochs(value: numval)
        }
    }
    
    func changeAItems(_ value:String) {
        if let numval = Double(value) {
            model.setAItems(value: numval)
        }
    }
    
    func changeASubjects(_ value:String) {
        if let numval = Double(value) {
            model.setASubjects(value: numval)
        }
    }
    func rerun() {
        model.rerun()
        primViewCalculateGraph()
    }
    
    var results: [ModelData] {
        guard selected != nil else {return []}
        
        return model.results.filter{ $0.item == sortedKeys[selected!]}
    }

    var selected: Int? {
        model.selected
    }
    
    var sortedKeys: [String] {
        model.sortedKeys
    }
    
    let colors: [Color] = [
        Color.red,
        Color.green,
        Color.blue,
        Color.orange,
        Color.yellow,
        Color.cyan,
        Color.indigo
    ]
    
    func primViewCalculateGraph() {
        model.primViewCalculateGraph()
        model.updatePrimViewData()
    }
    
    func updatePrimViewData() {
        model.updatePrimViewData()
    }
    
    func changeNodeLocation(node: Int, newX: Double, newY: Double ) {
        model.changeNodeLocation(node: node, newX: newX, newY: newY)
    }
    
    func back() {
        if selected == nil || selected == 0 {
            model.selected = 0
        } else {
            model.selected = model.selected! - 1
        }
        model.update()
    }
    
    func forward() {
        if selected == nil  {
            model.selected = 0
        } else if model.selected! != sortedKeys.count - 1 {
            model.selected = model.selected! + 1
        }
        model.update()
    }
    
    @objc func updatePrimsGraph(_ notification: Notification) {
        model.updatePrimViewData()
    }
    
    @objc func updateAll(_ notification: Notification) {
        model.update()
    }
    


}


func numberToColor(_ i: Int) -> Color {
    switch i {
    case -3: return Color.brown
    case -2: return Color.gray
    case -1: return Color.white
    case 0: return Color.red
    case 1: return Color.blue
    case 2: return Color.green
    case 3: return Color.purple
    case 4: return Color.cyan
    case 5: return Color.indigo
    case 6: return Color.orange
    case 7: return Color.yellow
    default: return Color.black
    }
}

