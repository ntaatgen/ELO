//
//  GraphViewPDF.swift
//  ELO
//
//  Created by Niels Taatgen on 08/01/2026.
//

import SwiftUI

struct GraphViewPDF: View {
    @ObservedObject var model: ELOViewModel
    let vertexSize: CGFloat = 20
    var body: some View {
        if model.graphData != nil {
            VStack {
                GeometryReader { geometry in
                    ZStack {
                        ForEach(model.graphData!.edges) { edge in
                            GraphEdge(edge: edge)
                                .stroke()
                                .foregroundColor(edge.learned ? Color.red : Color.black)
                        }
                        ForEach(model.graphData!.nodes) { node in
                            GraphNode(model: model, node: node, geometry: geometry, selectable: model.selectableNodeLabels)
                        }
                        
                    }
                    
                }
                
            }
        }
    }
}
