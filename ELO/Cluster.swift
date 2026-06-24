//
//  Cluster.swift
//  ELO
//
//  Created by Niels Taatgen on 08/10/2025.
//

import Foundation


func splitArrayInTwo<T>(_ array: [T], proportion: Double) -> ([T], [T]) {
    // Shuffle the array randomly
    let shuffledArray = array.shuffled()
    
    // Calculate the midpoint
    let midIndex = Int(Double(array.count + 1) * proportion)
    
    // Split the array into two halves
    let firstHalf = Array(shuffledArray[..<midIndex])
    let secondHalf = Array(shuffledArray[midIndex...])
    
    return (firstHalf, secondHalf)
}

// Compute Euclidean distance between two points
func distance(from a: [Double], to b: [Double]) -> Double {
    guard a.count == b.count else {
        print("\(a) and \(b) have different dimensions")
        return 0
    }
//    precondition(a.count == b.count, "Points must have same dimension.")
    let sum = zip(a, b).reduce(0.0) { $0 + pow($1.0 - $1.1, 2) }
    return sqrt(sum)
}

// Compute Manhattan distance between two points
//func distanceManhattan(from a: [Double], to b: [Double]) -> Double {
//    guard a.count == b.count else {
//        print("\(a) and \(b) have different dimensions")
//        return 0
//    }
////    precondition(a.count == b.count, "Points must have same dimension.")
//    let sum = zip(a, b).reduce(0.0) { $0 + abs($1.0 - $1.1) }
//    return sum
//}

// Compute the mean of a list of points
func mean(of points: [[Double]]) -> [Double] {
    guard !points.isEmpty else { return [] }
    let dim = points[0].count
    var mean: [Double] = Array(repeating: 0.0, count: dim)
    for p in points {
        for i in 0..<dim {
            mean[i] += p[i]
        }
    }
    return mean.map { $0 / Double(points.count) }
}

// Squared distance (for WCSS)
func squaredDistance(from a: [Double], to b: [Double]) -> Double {
    guard a.count == b.count else {
        return 0
    }
//    precondition(a.count == b.count, "Points must have same dimension.")
    return zip(a, b).reduce(0.0) { $0 + pow($1.0 - $1.1, 2) }
}

// MARK: - K-Means++ Initialization

func kMeansPlusPlusInit(points: [[Double]], k: Int) -> [[Double]] {
    precondition(!points.isEmpty && k > 0, "Invalid parameters for k-means++ initialization.")
    
    var centroids: [[Double]] = []
    
    // 1. Pick the first centroid randomly from the data
    guard let first = points.randomElement() else { return [] }
    centroids.append(first)
    
    // 2. Choose remaining k-1 centroids
    while centroids.count < k {
        // Compute distance squared to nearest centroid for each point
        let distances = points.map { point in
            centroids.map { squaredDistance(from: point, to: $0) }.min() ?? Double.greatestFiniteMagnitude
        }
        
        // Convert distances to probability distribution
        let total = distances.reduce(0, +)
        guard total > 0 else { break }
        let probabilities = distances.map { $0 / total }
        
        // Select a new centroid weighted by squared distance
        let r = Double.random(in: 0...1)
        var cumulative = 0.0
        for (i, p) in probabilities.enumerated() {
            cumulative += p
            if r <= cumulative {
                centroids.append(points[i])
                break
            }
        }
    }
    
    return centroids
}

func logit(_ x: Double) -> Double {
    guard x > 0 else { return -1.0e5 }
    guard x < 1 else { return 1.0e5 }
    return log(x / (1 - x))
}

func logistic(_ x: Double) -> Double {
    return 1/(1+exp(-x))
}


func kMeans(points: [String:Item],  k: Int, dim: Int, maxIterations: Int = 100, maxTries: Int = 50) -> ([[Double]], Double) {
    precondition(k > 0 && k <= points.count, "k must be between 1 and number of points.")
//    precondition(points.allSatisfy { $0.count == points[0].count }, "All points must have the same dimension.")
    var bestCentroids: [[Double]] = []
    var bestWCSS = Double.infinity
    // Randomly initialize centroids
//    var centroids: [[Double]] = Array(points.map { $0.value.skills } . shuffled() .prefix(k))
    for _ in 0..<maxTries {
        var centroids = kMeansPlusPlusInit(points: Array(points.map { $0.value.skills }), k: k)
        
        //    var centroids = (0..<k).map { _ in
        //        (0..<dim).map { _ in Double.random(in: 0...1) }
        //    }
        //    Array(points.values.skills).shuffled().prefix(k)
        var clusters = Array(repeating: [[Double]](), count: k)
        
        for i in 0..<maxIterations {
            // Step 1: Assign points to nearest centroid
            clusters = Array(repeating: [[Double]](), count: k)
            for (_,point) in points {
                let nearestIndex = centroids.enumerated()
                    .min(by: { distance(from: $0.element, to: point.skills) < distance(from: $1.element, to: point.skills) })!
                    .offset
                clusters[nearestIndex].append(point.skills)
            }
            
            // Step 2: Update centroids
            let newCentroids = clusters.map { mean(of: $0) }
            
            // Step 3: Check convergence
            let converged = zip(centroids, newCentroids).allSatisfy {
                distance(from: $0, to: $1) < 1e-6
            }
            if converged { print("Converged in \(i+1) iterations.")
                break }
            
            centroids = newCentroids
            for (i,centroid) in centroids.enumerated() {
                if centroid.isEmpty {
                    centroids[i] = (0..<dim).map { _ in Double.random(in: 0...1) }
                }
            }
        }
        
        var totalWCSS = 0.0
        for (i, cluster) in clusters.enumerated() {
            for point in cluster {
                totalWCSS += squaredDistance(from: point, to: centroids[i])
            }
        }
        if totalWCSS < bestWCSS {
            bestWCSS = totalWCSS
            bestCentroids = centroids
        }
    }
    
    for (_, item) in points {
        let nearestIndex = bestCentroids.enumerated()
            .min(by: { distance(from: $0.element, to: item.skills) < distance(from: $1.element, to: item.skills) })!
            .offset
        item.cluster = nearestIndex
    }
    return (bestCentroids, bestWCSS)
}
