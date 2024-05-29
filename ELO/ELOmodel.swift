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
    var selectedG: SelectedGraph = .items
//    var studentSelected: Bool = false
    var primGraphData: FruchtermanReingold?
    var graphData: GraphData?
    var timeList: [Int] = [0]

    mutating func loadData(filePath: URL, add: Bool) {
        if add {
            logic.addDataWithURL(filePath)
        } else {
            logic.loadDataWithURL(filePath)
        }
        update()
    }
    
    mutating func generateData(set: Int) {
        if set == 0 {
            logic.generateDataFull()
        } else if set == 1 {
            logic.generateData()
        }
        update()
    }
    
    mutating func update() {
        results = logic.results
        studentResults = logic.studentResults
        errorResults = logic.errors
        studentKeys = logic.studentKeys
        sortedKeys = logic.sortedKeys
        timeList = logic.timeList
    }
    
    func setEpochs(value: Int) {
        logic.nEpochs = value
    }
    
    func setAItems(value: Double) {
        logic.alphaItems = value
    }
    
    func setOffsetParameter(value: Double) {
        logic.offsetParameter = value
    }
    
    func setASubjects(value: Double) {
        logic.alphaStudents = value
    }
    
    func setThreshold(value: Double) {
        logic.skillThreshold = value
    }
    
    func setSkills(value: Int) {
        if value > 0 && value <= ELOlogic.maxSkills {
            logic.nSkills = value
        }
    }
    
    mutating func reset() {
        logic.resetModel()
        update()
        selected = 0
    }
    
    mutating func run(time: Int) {
        logic.run(time: time)
        update()
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
    
    func averageScore(s: Student, items: [Item]) -> Double {
        var score = 0.0
        var count = 0.0
        for result in logic.scores {
            if result.student == s.name && items.contains(where: {$0.name == result.item}) {
                score += result.score
                count += 1
            }
        }
        
        print(count)
        return count != 0 ? score/count : 0.0
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
            var nodeScore = 0.0
            if selectedG == .students && selected != nil {
                nodeScore = averageScore(s: logic.students[studentKeys[selected!]]!, items: node.items)
            }
            graphData!.nodes.append(
                ViewNode(x: node.x,
                         y: node.y,
                         z: selectedG == .students ? nodeScore : nil,
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

