//
//  FruchtermanReingold.swift
//  PRIMs
//
//  Created by Niels Taatgen on 5/12/15.
//  Copyright (c) 2015 Niels Taatgen. All rights reserved.
//

import Foundation

class Node {
    let name: String
    var x: Double = 0.0
    var y: Double = 0.0
    var dx: Double = 0.0
    var dy: Double = 0.0
    var taskNumber: Int = -2 // White node
    var rank = 0.0
    var skillNode = false
    var taskNode = false
    var labelVisible = false
    var shortName: String
    var definedByTask: Int? = nil
    var halo = false
    var fixed = false
    var items: [Item] = []
    init(name: String) {
        self.name = name
        self.shortName = name
    }
}

class Edge {
    let from: Node
    let to: Node
    var learned: Bool = false
    init(from: Node, to: Node) {
        self.from = from
        self.to = to
    }
}



class FruchtermanReingold {
    var nodes: [String:Node] = [:]
    var keys: [String] = []
    var nodeToIndex: [String:Int] = [:]
    var edges: [Edge] = []
    var W: Double
    var H: Double
    let iterations = 100
    var constantC = 0.3
    var wallRepulsionMultiplier = 2.0
    var area: Double {
        get {
            return W * H
        }
    }
    var k: Double {
        get {
            if nodes.count > 0 {
                return constantC * sqrt(area/Double(nodes.count))
            } else {
                return 0.1
            }
        }
    }
    
    init(W: Double, H: Double) {
        self.W = W
        self.H = H
    }
    
    func attractionForce(_ x: Double) -> Double {
        return pow(x,2)/k
    }
    
    func repulsionForce(_ z: Double) -> Double {
        return pow(k,2) / z
    }

    func vectorLength(_ x: Double, y: Double) -> Double {
        return sqrt(pow(x,2)+pow(y,2))
    }
    
    func rescale(_ newW: Double, newH: Double) {
        for (_,node) in nodes {
            node.x = node.x * (newW/W)
            node.y = node.y * (newH/H)
        }
        W = newW
        H = newH
    }
    
    func calculate(randomInit: Bool) {
//        DispatchQueue.global().async { () -> Void in
            var maxRank = 0.0
            if randomInit {
                for (_,node) in self.nodes {
                    if !node.fixed {
                        node.x = Double(Int(arc4random_uniform(UInt32(self.W))))
                        node.y = Double(Int(arc4random_uniform(UInt32(self.H))))
                        maxRank = max(maxRank,node.rank)
                    }
                }
            }
            let rankStep = (self.H - 30) / (maxRank - 1)
            for i in 0..<self.iterations {
                let temperature = randomInit ? 0.1 * max(self.W,self.H) * Double(self.iterations - i)/Double(self.iterations) :
                0.01 * max(self.W,self.H) * Double(self.iterations - i)/Double(self.iterations)
                // Calculate repulsive forces
                for (_,node) in self.nodes {
                    node.dx = 0
                    node.dy = 0
                    for (_,node2) in self.nodes {
                        if node !== node2 {
                            let deltaX = node.x - node2.x
                            let deltaY = node.y - node2.y
                            let deltaLength = self.vectorLength(deltaX, y: deltaY)
                            node.dx += (deltaX / deltaLength) * self.repulsionForce(deltaLength)
                            node.dy += (deltaY / deltaLength) * self.repulsionForce(deltaLength)
                        }
                    }
                    // repulsion of walls
                    node.dx += self.wallRepulsionMultiplier * self.repulsionForce(node.x + 1)
                    node.dx -= self.wallRepulsionMultiplier * self.repulsionForce(self.W + 1 - node.x)
                    node.dy += self.wallRepulsionMultiplier * self.repulsionForce(node.y + 1)
                    
                    node.dy -= self.wallRepulsionMultiplier * self.repulsionForce(self.H + 1 - node.y)
                    
                }
                // calculate attractive forces
                
                for edge in self.edges {
                    let deltaX = edge.from.x - edge.to.x
                    let deltaY = edge.from.y - edge.to.y
                    let deltaLength = self.vectorLength(deltaX, y: deltaY)
                    edge.from.dx -= (deltaX / deltaLength) * self.attractionForce(deltaLength)
                    edge.from.dy -= (deltaY / deltaLength) * self.attractionForce(deltaLength)
                    edge.to.dx += (deltaX / deltaLength) * self.attractionForce(deltaLength)
                    edge.to.dy += (deltaY / deltaLength) * self.attractionForce(deltaLength)
                }
                
                // move the nodes
                
                for (_,node) in self.nodes {
                    //                                println("\(node.name) at (\(node.x),\(node.y))")
                    //                println("\(node.name) delta (\(node.dx),\(node.dy))")
                    if !node.fixed {
                        node.x += (node.dx / self.vectorLength(node.dx, y: node.dy)) * min(abs(node.dx), temperature)
                        node.y += (node.dy / self.vectorLength(node.dx, y: node.dy)) * min(abs(node.dy), temperature)
                        node.x = min(self.W, max(0, node.x))
                        node.y = min(self.H, max(0, node.y))
                        //                println("\(node.name) at (\(node.x),\(node.y))")
                        if node.rank > 0.1 {
                            node.y = rankStep * (node.rank - 1)
                            //                    let midY = rankStep * (node.rank - 1)
                            //                    node.y = min(midY + 0.3 * rankStep, max( midY - 0.3 * rankStep, node.y))
                        }
                    }
                }
//                DispatchQueue.main.async {
//                    NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdatePrimsGraph"), object: nil)
//                }
                
//            }
            
        }
    }
    
    func findClosest(_ x: Double, y: Double) -> Node? {
        var closest: Node?
        var closestDistance: Double = 1E20
        for (_,node) in nodes {
            let distance = pow(node.x - x, 2) + pow(node.y - y, 2)
            if distance < closestDistance {
                closest = node
                closestDistance = distance
            }
        }
        return closest
    }
    
    func makeVisibleClosestNodeName(_ x: Double, y: Double)  {
        let closest = findClosest(x, y: y)
        if closest != nil {
            closest!.labelVisible = !closest!.labelVisible
        }
    }
    
    func itemToSkillString(item: Item, model: ELOlogic) -> String {
        var s = ""
        for x in item.skills {
            if x >= model.skillThreshold {
                s = s + "1"
            } else {
                s = s + "0"
            }
        }
        return s
    }
    
    func itemHigherThan(item1: Item, item2: Item, model: ELOlogic) -> Bool {
        var b = false
        for i in 0..<item1.skills.count {
            if item1.skills[i] < model.skillThreshold && item2.skills[i] >= model.skillThreshold {
                return false
            } else if item1.skills[i] >= model.skillThreshold && item2.skills[i] < model.skillThreshold {
                b = true
            }
        }
        return b
    }
    
    func hasEdge(node1: Node, node2: Node) -> Edge? {
        for edge in edges {
            if (edge.from === node1 && edge.to === node2)  {
                return edge
            }
        }
        return nil
    }
    
    func setUpGraph(_ model: ELOlogic) {
        guard model.items.count != 0 else { return }
        nodes = [:]
        edges = []
        constantC = 1.0
        for key in model.sortedKeys {
            let item = model.items[key]!
            if item.experiences == 0 {
                continue
            }
            let s = itemToSkillString(item: item, model: model)
            if let node = nodes[s] {
                node.items.append(item)
            } else {
                let newNode = Node(name: s)
                newNode.shortName = s
                newNode.labelVisible = true
                newNode.items = [item]
                newNode.skillNode = true
                if !s.contains("1") { // all zeros, so bottom node
                    newNode.fixed = true
                    newNode.y = H - 20
                    newNode.x = W/2
                } else if !s.contains("0") { // all ones
                    newNode.fixed = true
                    newNode.y = 20
                    newNode.x = W/2
                }
                for (_, node) in nodes {
                    if itemHigherThan(item1: item, item2: node.items[0], model: model) {
                        let newEdge = Edge(from: node, to: newNode)
                        edges.append(newEdge)
                    } else if itemHigherThan(item1: node.items[0], item2: item, model: model) {
                        let newEdge = Edge(from: newNode, to: node)
                        edges.append(newEdge)
                    }
                }
                nodes[s] = newNode
            }
        }
        var removeList: [Edge] = []
        for (_, node1) in nodes {
            for (_, node2) in nodes {
                if let edge = hasEdge(node1: node1, node2: node2) {
                    for (_, node3) in nodes {
                        if hasEdge(node1: node1, node2: node3) != nil && hasEdge(node1: node3, node2: node2) != nil {
                            removeList.append(edge)
                        }
                    }
                }
            }
        }
        for edgeRemove in removeList {
            for i in 0..<edges.count {
                if edges[i] === edgeRemove {
                    edges.remove(at: i)
                    break
                }
            }
            
        }
        keys = Array(nodes.keys)
        nodeToIndex = [:]
        for i in 0..<keys.count {
            nodeToIndex[keys[i]] = i
        }
    }
  
    

    
}
