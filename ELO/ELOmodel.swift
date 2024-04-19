//
//  ELOmodel.swift
//  ELO
//
//  Created by Niels Taatgen on 3/7/24.
//

import Foundation

struct ELOmodel {
    internal var logic = ELOlogic()
    
    var results: [ModelData] = []
    var sortedKeys: [String] = []
    var selected: Int? = nil
    
    var primGraphData: FruchtermanReingold?
    var graphData: GraphData?


    func loadData(filePath: URL) {
        logic.loadDataWithString(filePath)
    }
    
    mutating func generateData() {
        logic.generateData()
        update()
    }
    
    mutating func update() {
        results = logic.results
        sortedKeys = logic.sortedKeys
    }
    
    func setEpochs(value: Int) {
        logic.nEpochs = value
    }
    
    func setAItems(value: Double) {
        logic.alphaItems = value
    }
    
    func setASubjects(value: Double) {
        logic.alphaStudents = value
    }
    
    func setThreshold(value: Double) {
        logic.skillThreshold = value
    }
    
    mutating func rerun() {
        logic.rerun()
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
            graphData!.nodes.append(
                ViewNode(x: node.x,
                         y: node.y,
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
    
//    func runTest() {
//        logic.testLogic()
//    }
    
}

struct ViewNode: Identifiable {
    var id = UUID()
    var x: Double
    var y: Double
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

