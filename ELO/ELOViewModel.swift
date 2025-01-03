//
//  ELOmain.swift
//  ELO
//
//  Created by Niels Taatgen on 3/6/24.
//

import SwiftUI


class ELOViewModel: ObservableObject {
    
    @Published private var model: ELOmodel
    
    @Published var alphaV = String(ELOlogic.alphaDefault)
    @Published var nSkillsV = String(ELOlogic.nSkillsDefault)
//    @Published var alphaStudentV = String(ELOlogic.alphaStudentsDefault)
    @Published var alphaHebbV = String(ELOlogic.alphaHebbDefault)
    @Published var nEpochsV = String(ELOlogic.epochsDefault)
    @Published var lastLoaded = false { didSet {model.logic.showLastLoadedStudents = lastLoaded}}
    @Published var selectableNodeLabels = false
    @Published var studentMode = false  { didSet {
        if studentMode == true {
            selectableNodeLabels = true
        }
        model.changeStudentMode(studentMode)
        model.updatePrimViewData()}}
    @Published var currentItemInfos: [ItemInfo] = []
    @Published var openSheet = false
    @Published var sheetImage: NSImage? = nil
    @Published var queryItem: ItemInfo? = nil
    @Published var feedback = [Color](repeating: Color.white, count: 10)
    var lastLoadPath: URL? = nil
    var lastClickedNode: UUID? = nil
    let maxImages = 10 // How many item images maximally at the same time
    
    var graphData: GraphData? {
        model.graphData
    }
    
    var resultsLWB: Double {
        return results.isEmpty ? 0 : results.reduce(100000) { min($0, $1.y)}
    }

    var resultsUPB: Double {
        return results.isEmpty ? 0 : results.reduce(0) {max($0, $1.y)}

    }
    
    var resultsLowestX: Int {
        return results.isEmpty ? 0 : results.reduce(100000) { min($0, $1.x)}
    }
    
    var resultsHighestX: Int {
        return results.isEmpty ? 0 : results.reduce(0) {max($0, $1.x)}
    }
    
    
    var chartLegendLabels: KeyValuePairs<String, Color> {
        switch model.logic.nSkills {
        case 1: return ["1":colors[0]]
        case 2: return ["1x":colors[0],"x1":colors[1]]
        case 3: return ["1xx":colors[0],"x1x":colors[1],"xx1":colors[2]]
        case 4: return ["1xxx":colors[0],"x1xx":colors[1],"xx1x":colors[2],"xxx1":colors[3]]
        case 5: return ["1xxxx":colors[0],"x1xxx":colors[1],"xx1xx":colors[2],"xxx1x":colors[3],"xxxx1":colors[4]]
        default: return ["1xxxxx":colors[0],"x1xxxx":colors[1],"xx1xxx":colors[2],"xxx1xx":colors[3],"xxxx1x":colors[4],"xxxxx1":colors[5]]
        }
    }
    
    var trace: String {
        model.trace
    }
    
//    var alpha: Double {
//        model.alpha
//    }
    
    init() {
        model = ELOmodel()
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.updateGraph(_:)), name: NSNotification.Name(rawValue: "updateGraph"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.updatePrimsGraph(_:)), name: NSNotification.Name(rawValue: "updatePrimsGraph"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.runDone(_:)), name: NSNotification.Name(rawValue: "runDone"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ELOViewModel.endRun(_:)), name: NSNotification.Name(rawValue: "endRun"), object: nil)
    }
    
    func setImage(name: String, node: UUID) {
        guard lastLoadPath != nil else { return }
        let item = ItemInfo(name: name, loadPath: lastLoadPath!)
        guard item.image != nil || item.questions != [] else {return}
        
        if node == lastClickedNode {
            currentItemInfos.append(item)
        } else {
            lastClickedNode = node
            currentItemInfos = [item]
        }
        if currentItemInfos.count > maxImages {
            currentItemInfos.removeFirst()
        }
    }
    
    func setImageToCurrentProblem() {
        if model.selected! < model.sortedKeys.count {
            let imageName = model.sortedKeys[model.selected!]
            currentItemInfos = []
            setImage(name: imageName, node: UUID())
        }
    }
    
    func showItemOnSheet(_ name: String) {
        guard lastLoadPath != nil else { return }
        queryItem = ItemInfo(name: name, loadPath: lastLoadPath!)
        feedback = [Color](repeating: Color.blue, count: 10)
        openSheet = true
        
    }
    
    func scoreSheet(answers: [String]) {
        model.scoreSheet(itemInfo: queryItem!, answers: answers)
        var newFeedback: [Color] = []
        for i in 0..<model.logic.feedback.count {
            if model.logic.feedback[i] {
                newFeedback.append(Color.green)
            } else {
                newFeedback.append(Color.red)
            }
        }
        feedback = newFeedback
    }
    
    func createNewStudent() {
        model.createNewStudent()
        _ = changeAlpha("0.01")
        alphaV = "0.01"
        studentMode = true
    }
    
    func loadData(add: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            for url in panel.urls {
                model.loadData(filePath: url, add: add)
                model.addToTrace(s: add ? "Adding data \(url.pathComponents.last!)" : "Loading data \(url.pathComponents.last!)")
                lastLoadPath = url.deletingLastPathComponent()
//                currentItemImage = NSImage(contentsOf: lastLoadPath!.appendingPathComponent("1_1.png"))
            }
        }
    }
    
    func runScript() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "Run"
        if panel.runModal() == .OK {
            for url in panel.urls {
                model.addToTrace(s: "Start running script \(url.pathComponents.last!)")
                model.runScript(filePath: url)
                model.addToTrace(s: "Finished running script \(url.pathComponents.last!)")
                model.selected = 0
                model.primViewCalculateGraph()
                model.updatePrimViewData()
                model.update()
                updateParameters()
                if model.selectedGroup == .items {
                    setImageToCurrentProblem()
                }
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
                        self.model.writeDataToFile(url: panelURL, lastonly: lastonly)
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
                            self.model.addToTrace(s: "Saving model to file \(panelURL.pathComponents.last!)")
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
                    model.addToTrace(s: "Loading model from \(panelURL.pathComponents.last!)")
                    model.selected = 0
                    model.primViewCalculateGraph()
                    model.updatePrimViewData()
                    model.update()
                    updateParameters()
                    if model.selectedGroup == .items {
                        setImageToCurrentProblem()
                    }
                    lastLoadPath = panelURL.deletingLastPathComponent()
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
    
    func changeEpochs(_ epochs: String) -> String {
        if let numval = Int(epochs) {
            model.setEpochs(value: numval)
            model.addToTrace(s: "Changing epochs to \(epochs)")
            return epochs
        } else {
            model.addToTrace(s: "Illegal value for epochs")
            return String(model.logic.nEpochs)
        }
    }
    
    func changeAlpha(_ value:String) -> String {
        if let numval = Double(value) {
            model.setAlpha(value: numval)
            model.addToTrace(s: "Changing Alpha  to \(numval)")
            return value
        } else {
            model.addToTrace(s: "Illegal value for Alpha")
            return String(model.alpha)
        }
    }
    
//    func changeASubjects(_ value:String) -> String {
//        if let numval = Double(value) {
//            model.setASubjects(value: numval)
//            model.addToTrace(s: "Changing Alpha subjects to \(numval)")
//            return value
//        } else {
//            model.addToTrace(s: "Illegal value for Alpha subjects")
//            return String(model.logic.alphaStudents)
//        }
//    }
    
    func changeAHebb(_ value:String) -> String {
        if let numval = Double(value) {
            model.setAHebb(value: numval)
            model.addToTrace(s: "Changing Alpha Hebb to \(numval)")
            return value
        } else {
            model.addToTrace(s: "Illegal value for Alpha Hebb")
            return String(model.logic.alphaHebb)
        }
    }
    
    
    func changeNSkills(_ value:String) -> String {
        if let numval = Int(value) {
            if model.logic.students.isEmpty && model.logic.items.isEmpty && numval <= ELOlogic.maxSkills {
                model.setSkills(value: numval)
                model.addToTrace(s: "Changing skill number to \(numval)")
                return value
            } else if numval > ELOlogic.maxSkills {
                model.addToTrace(s: "Too many skills, max is \(ELOlogic.maxSkills)")
                return(String(model.logic.nSkills))
            } else {
                 model.addToTrace(s: "Cannot change nSkills after loading data")
                return(String(model.logic.nSkills))
            }
        } else {
            model.addToTrace(s: "Illegal value for skill number")
            return(String(model.logic.nSkills))
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
        updateParameters()
        currentItemInfos = []
    }
    
    func run(time: Int?) {
        model.run(time: time)
        primViewCalculateGraph()
        
        model.addToTrace(s: "Running model at time \(time ?? 0) for \(model.logic.nEpochs) epochs")
    }
    
    @objc func runDone(_ notification: Notification) {
        model.update()
        if model.selectedGroup == .items {
            setImageToCurrentProblem()
        }
    }
    
    @objc func updateGraph(_ notification: Notification) {
        model.addToTrace(s: "Epoch \(model.logic.counter)")
        primViewCalculateGraph()
        model.update()
        if model.selectedGroup == .items {
            setImageToCurrentProblem()
        }
    }
    
    @objc func endRun(_ notification: Notification) {
        model.addToTrace(s: "Done running")
        model.addToTrace(s: "Avg. error = \(model.logic.calculateError())")
        if model.selectedGroup == .items {
            setImageToCurrentProblem()
        }
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
        if model.selectedGroup == .students && studentKeys.isEmpty {
            model.selectedGroup = model.selectedGroup.next()
        }
        if model.selectedGroup == .students {
            updatePrimViewData()
        }
        if model.selectedGroup == .items {
            setImageToCurrentProblem()
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
        if model.selectedGroup == .items {
            setImageToCurrentProblem()
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
        if model.selectedGroup == .items {
            setImageToCurrentProblem()
        }
        model.update()
    }
    
    func updateParameters() {
        alphaV = String(model.logic.alpha)
        nSkillsV = String(model.logic.nSkills)
//        alphaStudentV = String(model.logic.alphaStudents)
        alphaHebbV = String(model.logic.alphaHebb)
        nEpochsV = String(model.logic.nEpochs)
        lastLoaded = model.logic.showLastLoadedStudents
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

func gradientColor(value: Double, alpha: Double = 1) -> Color {
    let color = NSColor(red: 1 - value, green: value, blue: 0, alpha: alpha)
    return Color(color)
   }
