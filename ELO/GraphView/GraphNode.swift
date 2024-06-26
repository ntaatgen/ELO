//
//  GraphNode.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/15/23.
//

import SwiftUI

struct GraphNode: View {
//    @ObservedObject var model: PRIMsViewModel
    var node: ViewNode
    let vertexSize: CGFloat = 20
    var geometry: GeometryProxy
    var body: some View {
        ZStack {
            if node.halo {
                GraphHalo(node: node)
                    .foregroundColor(Color.yellow)
            }
            GraphNodeShape(node: node)
                .strokeBorder(Color.black, lineWidth: node.skillNode == false && node.taskNode == false ? 1 : 3)
                .background(GraphNodeShape(node: node).foregroundColor(node.z != nil ? gradientColor(value: node.z!) : .gray))
            Text(node.name)
                .font(node.skillNode == false && node.taskNode == false ? .caption2 : .title2)
                .position(x: CGFloat(node.x)/300 * geometry.size.width,
                          y: CGFloat(node.y)/300 * geometry.size.height + 1.5 * vertexSize)
            Text(node.problems)
                .font(.caption2)
                .background(Color.white)
                .border(Color.black, width: 1)
                .position(x: CGFloat(node.x)/300 * geometry.size.width + vertexSize*1.5,
                          y: CGFloat(node.y)/300 * geometry.size.height)

        }
        
        
    }
    
    
    
}
