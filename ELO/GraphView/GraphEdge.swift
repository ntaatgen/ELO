//
//  GraphEdge.swift
//  PRIMs
//
//  Created by Niels Taatgen on 3/16/23.
//

import SwiftUI

struct GraphEdge: Shape {
    var edge: ViewEdge
    let lineWidth:CGFloat = 3
    let vertexSize: CGFloat = 20
    let arrowSize: CGFloat = 10
    func path(in rect: CGRect) -> Path {
        let start = CGPoint(x: CGFloat(edge.start.x)/300 * rect.width, y: CGFloat(edge.start.y)/300 * rect.height)
        let end = CGPoint(x: CGFloat(edge.end.x)/300 * rect.width, y: CGFloat(edge.end.y)/300 * rect.height)
        let π = CGFloat(Double.pi)
        var angle: CGFloat
        
        if start.x != end.x {
            angle = atan((end.y - start.y) / (end.x - start.x))
        } else {
            angle = start.y > end.y ? -π/2 : π/2
        }
        if start.x > end.x {
            angle += π
        }
        let intersect = CGPoint(x: end.x - (vertexSize + lineWidth) * cos(angle), y: end.y - (vertexSize + lineWidth) * sin(angle))
        let arrowtip1 = CGPoint(x: intersect.x + arrowSize * cos(angle - 0.75 * π), y: intersect.y + arrowSize * sin(angle - 0.75 * π))
        let arrowtip2 = CGPoint(x: intersect.x + arrowSize * cos(angle + 0.75 * π), y: intersect.y + arrowSize * sin(angle + 0.75 * π))
        
        var path = Path()
        path.move(to: start)
        path.addLine(to: intersect)
        path.addLine(to: arrowtip1)
        path.move(to: intersect)
        path.addLine(to: arrowtip2)
        return path
    }
    
    
}
