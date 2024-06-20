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
    
    var resultsLWB: Double {
        var lowest = 10000000.0
        for res in results {
            lowest = min(lowest,res.y)
        }
        print("Lowest ",lowest)
        return lowest
    }

    var resultsUPB: Double {
        var highest = -10000000.0
        for res in results {
            highest = max(highest,res.y)
        }
        print("Highest ",highest)
        return highest
    }
    
    var trace: String {
        model.trace
    }
    
    init() {
        model = ELOmodel()
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.updateGraph(_:)), name: NSNotification.Name(rawValue: "updateGraph"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.updatePrimsGraph(_:)), name: NSNotification.Name(rawValue: "updatePrimsGraph"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.runDone(_:)), name: NSNotification.Name(rawValue: "runDone"), object: nil)
    }
    
    func loadData(add: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                model.loadData(filePath: url, add: add)
                model.addToTrace(s: "Loading data \(url.pathComponents.last!)")
            }
        }
    }
    

    
    func writeDataFile(lastonly: Bool = false) {
        let savePanel = NSSavePanel()
        savePanel.title = "Write Data File"
        savePanel.nameFieldLabel = "File Name:"
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                    if let panelURL = savePanel.url {
                        var output = ""
                        for i in 0..<self.model.logic.sortedKeys.count {
                            let item = self.model.logic.items[self.model.logic.sortedKeys[i]]!
                            output += "item, " + item.name
                            for j in 0..<item.skills.count {
                                output += ", " + String(item.skills[j])
                            }
                            output += "\n"
                        }
                        if lastonly {
                            for studentName in self.model.logic.lastLoadedStudents {
                                let student = self.model.logic.students[studentName]!
                                output += "student, " + student.name
                                for j in 0..<student.skills.count {
                                    output += ", " + String(student.skills[j])
                                }
                                output += "\n"
                            }
                        } else {
                            for (_, student) in self.model.logic.students {
                                output += "student, " + student.name
                                for j in 0..<student.skills.count {
                                    output += ", " + String(student.skills[j])
                                }
                                output += "\n"
                            }
                        }
                        do {
                            try output.write(to: panelURL, atomically: true, encoding: .utf8)
                        }
                        catch let error as NSError {
                            print("Ooops! Something went wrong: \(error)")
                            return
                        }
                    }
                }
            
        }
    }
    
    func saveModel() {
        let savePanel = NSSavePanel()
        savePanel.title = "Save model"
        savePanel.nameFieldLabel = "File Name:"
        savePanel.begin { (result: NSApplication.ModalResponse) -> Void in
            if result == NSApplication.ModalResponse.OK {
                    if let panelURL = savePanel.url {
                        do {
                            try JSONEncoder().encode(self.model.logic)
                                .write(to: panelURL)
                        }
                        catch let error as NSError {
                            print("Ooops! Something went wrong: \(error)")
                            return
                        }
                    }
                }
            
        }
    }
    
    func loadModel() {
        do {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            if panel.runModal() == .OK {
                if let panelURL = panel.url {
                    let data = try Data(contentsOf: panelURL)
                    model.logic = try JSONDecoder().decode(ELOlogic.self, from: data)
                    model.selected = 0
                    model.update()
                    model.primViewCalculateGraph()
                }
            }
        }
        catch {
            return
        }
    }
    

    func generateData(set: Int) {
            model.generateData(set: set)
        model.addToTrace(s: "Generating data")
    }
    
    func changeEpochs(_ epochs: String) {
        if let numval = Int(epochs) {
            model.setEpochs(value: numval)
            model.addToTrace(s: "Changing epochs to \(epochs)")
        } else {
            model.addToTrace(s: "Illegal value for epochs")
        }
    }
    
    func changeAItems(_ value:String) {
        if let numval = Double(value) {
            model.setAItems(value: numval)
            model.addToTrace(s: "Changing Alpha items to \(numval)")
        } else {
            model.addToTrace(s: "Illegal value for Alpha items")
        }
    }
    
    func changeASubjects(_ value:String) {
        if let numval = Double(value) {
            model.setASubjects(value: numval)
            model.addToTrace(s: "Changing Alpha subjects to \(numval)")
        } else {
            model.addToTrace(s: "Illegal value for Alpha subjects")
        }
    }
    
    func changeAHebb(_ value:String) {
        if let numval = Double(value) {
            model.setAHebb(value: numval)
            model.addToTrace(s: "Changing Alpha Hebb to \(numval)")
        } else {
            model.addToTrace(s: "Illegal value for Alpha Hebb")
        }
    }
    
//    func changeOffsetParameter(_ value:String) {
//        if let numval = Double(value) {
//            model.setOffsetParameter(value: numval)
//        }
//    }
    
    func changeNSkills(_ value:String) {
        if let numval = Int(value) {
            model.setSkills(value: numval)
            model.addToTrace(s: "Changing skill number to \(numval)")
        } else {
            model.addToTrace(s: "Illegal value for skill number")
        }
    }
    
    func changeTreshold(_ value:String) {
        if let numval = Double(value) {
            model.setThreshold(value: numval)
        }
    }
    
    func reset() {
        model.reset()
        primViewCalculateGraph()
    }
    
    func run(time: Int) {
        model.run(time: time)
        primViewCalculateGraph()
        model.addToTrace(s: "Running model at time \(time) for \(model.logic.nEpochs) epochs")
    }
    
    @objc func runDone(_ notification: Notification) {
        model.update()
    }
    
    @objc func updateGraph(_ notification: Notification) {
        primViewCalculateGraph()
        model.update()
    }
    
    var results: [ModelData] {
        guard selected != nil else {return []}
        switch model.selectedGroup { 
        case .students: return model.studentResults.filter{ $0.item == studentKeys[selected!] }
        case .items: return model.results.filter{ $0.item == sortedKeys[selected!]}
        case .errors: return model.errorResults
        }
    }
    
    func switchGraphs() {
        guard selected != nil else { return }
        model.selectedGroup = model.selectedGroup.next()
        model.selected = 0
        if model.selectedGroup == .students {
            updatePrimViewData()
        }
    }
    
    var graphSelected: SelectedGraph {
        model.selectedGroup
    }

    var selected: Int? {
        model.selected
    }
    
    var sortedKeys: [String] {
        model.sortedKeys
    }
    
    var studentKeys: [String] {
        model.studentKeys
    }
    
    var timeList: [Int] {
        model.timeList
    }
    
    let colors: [Color] = [
        Color.red,
        Color.green,
        Color.blue,
        Color.orange,
        Color.yellow,
        Color.cyan,
        Color.indigo,
        Color.black,
        Color.gray,
        Color.pink
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
        if model.selectedGroup == .students {
            updatePrimViewData()
        }
        model.update()
    }
    
    func forward() {
        if selected == nil || model.selectedGroup == .errors  {
            model.selected = 0
        } else if (model.selectedGroup == .items && model.selected! != sortedKeys.count - 1) || (model.selectedGroup == .students && model.selected != studentKeys.count - 1) {
            model.selected = model.selected! + 1
        }
        if model.selectedGroup == .students {
            updatePrimViewData()
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

func gradientColor(value: Double) -> Color {
    let color = NSColor(red: 1 - value, green: value, blue: 0, alpha: 1)
    return Color(color)
   }
