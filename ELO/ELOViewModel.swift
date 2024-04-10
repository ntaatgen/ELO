//
//  ELOmain.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI


class ELOViewModel: ObservableObject {
    
    @Published private var model: ELOmodel
    
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
    
    init() {
        model = ELOmodel()
//        model.runTest()
    }
}
