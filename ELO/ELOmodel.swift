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
    mutating func rerun() {
        logic.rerun()
        update()
        selected = 0
    }
    
    
//    func runTest() {
//        logic.testLogic()
//    }
    
}
