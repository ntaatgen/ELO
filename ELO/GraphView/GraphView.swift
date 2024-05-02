//
//  GraphView.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/15/23.
//

import SwiftUI

struct GraphView: View {
    @ObservedObject var model: ELOViewModel
    let vertexSize: CGFloat = 20
    @State var selectedItem = 2
    @State var closestNodeIndex: Int? = nil
    @State private var thresh: String = "0.5"
    var body: some View {
        if model.graphData != nil {
            VStack {
                HStack {
                    Button("Refresh"){
                        model.primViewCalculateGraph()
                    }
                    Text("Threshold:")
                    TextField("Threshold", text: $thresh, onEditingChanged: {changed in model.changeTreshold(thresh)})
                    Spacer()
                }
                GeometryReader { geometry in
                    ZStack {
                        ForEach(model.graphData!.edges) { edge in
                            GraphEdge(edge: edge)
                                .stroke()
                                .foregroundColor(edge.learned ? Color.red : Color.black)
                        }
                        ForEach(model.graphData!.nodes) { node in
                            GraphNode(node: node, geometry: geometry)
                        }
                        
                    }
                    .gesture(DragGesture()
                        .onChanged {value in
                            onChanged(value: value, geometry: geometry)}
                        .onEnded { _ in
                            model.updatePrimViewData()
                            closestNodeIndex = nil
                        }
                    )
                }
                
            }
        }
    }
    func onChanged(value: DragGesture.Value, geometry: GeometryProxy) {
        let x = Double((value.location.x / geometry.size.width) * 300)
        let y = Double((value.location.y / geometry.size.height) * 300)
        if closestNodeIndex == nil {
            var j: Int = 0
            var distance = (x - model.graphData!.nodes[j].x) * (x - model.graphData!.nodes[j].x) + (y - model.graphData!.nodes[j].y) * (y - model.graphData!.nodes[j].y)
            for i in 1..<model.graphData!.nodes.count {
                let newDistance = (x - model.graphData!.nodes[i].x) * (x - model.graphData!.nodes[i].x) + (y - model.graphData!.nodes[i].y) * (y - model.graphData!.nodes[i].y)
                if newDistance < distance {
                    j = i
                    distance = newDistance
                }
            }
            closestNodeIndex = j
        }
        model.changeNodeLocation(node: closestNodeIndex!, newX: x, newY: y)
//        print(model.graphData!.nodes[closestNodeIndex!].orgName)
//        print(value.startLocation)
//        print("onChanged", value.location)
    }
}


