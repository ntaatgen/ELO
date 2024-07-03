//
//  ELOmodel.swift
//  ELO
//
//  Created by Niels Taatgen on 3/7/24.
//

import Foundation

enum SelectedGraph {
    case items
    case students
    case errors
    func next() -> SelectedGraph {
        switch self {
        case .errors: return .items
        case .students: return .errors
        case .items: return .students
        }
    }
}

struct ELOmodel {
    internal var logic = ELOlogic()
    
    var results: [ModelData] = []

    var studentResults: [ModelData] = []
    var errorResults: [ModelData] = []
    var sortedKeys: [String] = []
    var studentKeys: [String] = []
    var selected: Int? = nil
    var selectedGroup: SelectedGraph = .items
//    var studentSelected: Bool = false
    var primGraphData: FruchtermanReingold?
    var graphData: GraphData?
    var timeList: [Int] = [0]
    var alphaItems: Double = ELOlogic.alphaItemsDefault
    var trace: String = "Starting ELO         \n"
    
    mutating func loadData(filePath: URL, add: Bool) {
        if add {
            logic.addDataWithURL(filePath)
        } else {
            logic.loadDataWithURL(filePath)
        }
        update()
    }
    
    mutating func runScript(filePath: URL) {
        let script = try? String(contentsOf: filePath, encoding: String.Encoding.utf8)
        guard script != nil else {
            addToTrace(s: "Failed to load script")
            return
        }
        let lines = script!.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: " ")
            if parts.count == 0 {
                continue
            }
            switch parts[0] {
            case "load-data":
                guard parts.count == 2 else {
                    addToTrace(s: "Invalid number of arguments in load-data")
                    return
                }
                let url: URL = filePath.deletingLastPathComponent().appendingPathComponent(parts[1])
                loadData(filePath: url, add: false)
                addToTrace(s: "Loaded \(url.lastPathComponent)")
            case "add-data":
                guard parts.count == 2 else {
                    addToTrace(s: "Invalid number of arguments in add-data")
                    return
                }
                let url: URL = filePath.deletingLastPathComponent().appendingPathComponent(parts[1])
                loadData(filePath: url, add: true)
                addToTrace(s: "Added \(url.lastPathComponent)")
            case "load-model":
                guard parts.count == 2 else {
                    addToTrace(s: "Invalid number of arguments in load-model")
                    return
                }
                let url: URL = filePath.deletingLastPathComponent().appendingPathComponent(parts[1])
                do {
                    let data = try Data(contentsOf: url)
                    logic = try JSONDecoder().decode(ELOlogic.self, from: data)
                    addToTrace(s: "Loading model from \(url.pathComponents.last!)")
                    selected = 0
                    primViewCalculateGraph()
                    updatePrimViewData()
                    update()
                }
                catch _ as NSError {
                    addToTrace(s: "Error in loading model.")
                }
            case "save-model":
                guard parts.count == 2 else {
                    addToTrace(s: "Invalid number of arguments in save-model")
                    return
                }
                let url: URL = filePath.deletingLastPathComponent().appendingPathComponent(parts[1])
                do {
                    try JSONEncoder().encode(self.logic)
                        .write(to: url)
                    addToTrace(s: "Saving model to file \(parts[1])")
                }
                catch let error as NSError {
                    print("Ooops! Something went in saving model file: \(error)")
                    return
                }
            case "write-data":
                guard parts.count == 2 else {
                    addToTrace(s: "Invalid number of arguments in write-data")
                    return
                }
                let url: URL = filePath.deletingLastPathComponent().appendingPathComponent(parts[1])
                writeDataToFile(url: url, lastonly: false)
            case "write-data-last":
                guard parts.count == 2 else {
                    addToTrace(s: "Invalid number of arguments in write-data-last")
                    return
                }
                let url: URL = filePath.deletingLastPathComponent().appendingPathComponent(parts[1])
                writeDataToFile(url: url, lastonly: true)
            case "run":
                guard parts.count <= 2 else {
                    addToTrace(s: "Invalid number of arguments in run")
                    return
                }
                var time = 0
                if parts.count == 2 {
                    if let x = Int(parts[1]) {
                        time = x
                    } else {
                        addToTrace(s: "Invalid time argument in run")
                    }
                }

                logic.calculateModelForBatch(time: time)

            case "set":
                guard parts.count == 3 else {
                    addToTrace(s: "Invalid number of arguments in set command")
                    return
                }
                switch parts[1] {
                case "epochs":
                    if let num = Int(parts[2]) {
                        setEpochs(value: num)
                    } else {
                        addToTrace(s: "Invalid number for set epochs")
                    }
                case "alpha-items":
                    if let num = Double(parts[2]) {
                        setAItems(value: num)
                    } else {
                        addToTrace(s: "Invalid number for set alpha-items")
                    }
                case "alpha-students":
                    if let num = Double(parts[2]) {
                        setASubjects(value: num)
                    } else {
                        addToTrace(s: "Invalid number for set alpha-students")
                    }
                case "alpha-hebb":
                    if let num = Double(parts[2]) {
                        setAHebb(value: num)
                    } else {
                        addToTrace(s: "Invalid number for set alpha-hebb")
                    }
                case "skills":
                    if let num = Int(parts[2]) {
                        setSkills(value: num)
                    } else {
                        addToTrace(s: "Invalid number for set skills")
                    }
                default: addToTrace(s: "Invalid parameter name \(parts[1])")
                }
            default: addToTrace(s: "Unknown command \(parts[0])")
            }
            
            
        }
    }
    
    mutating func generateData(set: Int) {
        if set == 0 {
            logic.generateDataFull()
        } else if set == 1 {
            logic.generateDataReduced()
        }
        update()
    }
    
    mutating func writeDataToFile(url: URL, lastonly: Bool) {
        var output = ""
        for i in 0..<logic.sortedKeys.count {
            let item = logic.items[logic.sortedKeys[i]]!
            output += "item, " + item.name
            for j in 0..<item.skills.count {
                output += ", " + String(item.skills[j])
            }
            output += "\n"
        }
        if lastonly {
            for studentName in logic.lastLoadedStudents {
                let student = logic.students[studentName]!
                output += "student, " + student.name
                for j in 0..<student.skills.count {
                    output += ", " + String(student.skills[j])
                }
                output += "\n"
            }
        } else {
            for (_, student) in logic.students {
                output += "student, " + student.name
                for j in 0..<student.skills.count {
                    output += ", " + String(student.skills[j])
                }
                output += "\n"
            }
        }
        do {
            try output.write(to: url, atomically: true, encoding: .utf8)
            addToTrace(s: "Saving data to file \(url.pathComponents.last!)")
        }
        catch let error as NSError {
            addToTrace(s: "Ooops! Something went wrong: \(error)")
            return
        }
    }

        
    mutating func update() {
        results = logic.results
        studentResults = logic.studentResults
        errorResults = logic.errors
        studentKeys = logic.studentKeys
        sortedKeys = logic.sortedKeys
        timeList = logic.timeList
    }
    
    mutating func addToTrace(s: String) {
        trace += s + "\n"
    }
    
    func setEpochs(value: Int) {
        logic.nEpochs = value
    }
    
    mutating func setAItems(value: Double) {
        alphaItems = value
        logic.alphaItems = value
    }
    
    func setASubjects(value: Double) {
        logic.alphaStudents = value
    }
    
    func setAHebb(value: Double) {
        logic.alphaHebb = value
    }
    
    func setThreshold(value: Double) {
        logic.skillThreshold = value
    }
    
    func setSkills(value: Int) {
            logic.nSkills = value
    }
    
    mutating func reset() {
        logic = ELOlogic()
//        logic.resetModel()
        resetGraph()
        timeList = [0]
        selectedGroup = .items
        trace = "Restarting ELO..\n"
        selected = 0
        update()
    }
    
    mutating func run(time: Int) {
            logic.run(time: time)
//            update()
            selected = 0
        
    }
    
    mutating func resetGraph() {
        primGraphData = nil
        graphData = nil
    }
    
    mutating func primViewCalculateGraph() {
        primGraphData = FruchtermanReingold(W: 300.0, H: 300.0)
        primGraphData!.constantC = 0.1

        primGraphData!.setUpGraph(logic)

        primGraphData!.calculate(randomInit: true)
    }
    
    func averageScore(s: Student, items: [Item]) -> Double? {
        var score = 0.0
        var count = 0.0
        for result in logic.scores {
            if result.student == s.name && items.contains(where: {$0.name == result.item}) {
                score += result.score
                count += 1
            }
        }
        
//        print(count)
        return count != 0 ? score/count : nil
    }
    
    mutating func updatePrimViewData() {
        guard primGraphData != nil else { return }
        graphData = GraphData()
        for (_, node) in primGraphData!.nodes {
            var s = ""
            for item in node.items {
                if s == "" {
                    s = item.name
                } else {
                    s = s + "\n" + item.name
                }
            }
            var nodeScore: Double? = 0.0
            if selectedGroup == .students && selected != nil && !studentKeys.isEmpty {
                nodeScore = averageScore(s: logic.students[studentKeys[selected!]]!, items: node.items)
            }
            graphData!.nodes.append(
                ViewNode(x: node.x,
                         y: node.y,
                         z: selectedGroup == .students ? nodeScore : nil,
                         taskNumber: node.taskNumber,
                         halo: node.halo,
                         name: node.shortName,
                         orgName: node.name,
                         skillNode: node.skillNode,
                         taskNode: node.taskNode,
                         problems: s
                        ))
        }
        for edge in primGraphData!.edges {
            graphData!.edges.append(
                ViewEdge(start: (x: edge.from.x, y: edge.from.y),
                         end: (x: edge.to.x, y: edge.to.y),
                         learned: edge.learned)
            )
        }
    }
    
    mutating func changeNodeLocation(node: Int, newX: Double, newY: Double ) {
        primGraphData!.nodes[graphData!.nodes[node].orgName]!.x = newX
        primGraphData!.nodes[graphData!.nodes[node].orgName]!.y = newY
        primGraphData!.nodes[graphData!.nodes[node].orgName]!.fixed = true
        graphData!.nodes[node].x = newX
        graphData!.nodes[node].y = newY
    }
    
    
    
}

struct ViewNode: Identifiable {
    var id = UUID()
    var x: Double
    var y: Double
    var z: Double? = nil
    var taskNumber: Int
    var halo: Bool
    var name: String
    var orgName: String
    var skillNode: Bool
    var taskNode: Bool
    var problems: String
    var problemsHidden: Bool = true
}

struct ViewEdge: Identifiable {
    var id = UUID()
    var start: (x: Double, y: Double)
    var end: (x: Double, y: Double)
    var learned: Bool
}

struct GraphData: Identifiable {
    var id = UUID()
    var nodes: [ViewNode] = []
    var edges: [ViewEdge] = []
}

