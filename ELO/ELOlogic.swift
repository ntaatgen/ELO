//
//  ELOlogic.swift
//  ELO
//
//  Created by Niels Taatgen on 3/7/24.
//

import Foundation

class Student {
    var name: String
    var realSkills: [Double] = []
    var skills: [Double] = []
    
    init(name: String) {
        self.name = name
    }
}

class Item {
    var name: String
    var realSkills: [Double] = []
    var skills: [Double] = []
    var experiences = 2
    
    init(name: String) {
        self.name = name
    }
}

class Score {
    var student: Student
    var item: Item
    var score: Double
    
    init(student: Student, item: Item, score: Double) {
        self.student = student
        self.item = item
        self.score = score
    }
}

struct ModelData: Identifiable {
    var id = UUID()
    var item: String
    var z: Int
    var x: Int
    var y: Double
}

class ELOlogic {
    
    let nSkills = 4
    var nEpochs = 1
    var alphaItems = 0.005
    var alphaStudents = 0.05
    var skillThreshold = 0.5
    let nItems = 16
    let nStudents = 2000
    var students: [String:Student] = [:]
    var items: [String:Item] = [:]
    var scores: [Score] = []
    var sortedKeys: [String] { Array(items.keys).sorted(by: <) }

    var results: [ModelData] = []
    
    var filename: URL? = nil
    
    var synthetic = false
    
    func loadDataWithString(_ filePath: URL) {
        filename = filePath
        students = [:]
        items = [:]
        scores = []
        results = []
        synthetic = false
        let dataFileContents = try? String(contentsOf: filePath, encoding: String.Encoding.utf8)
        guard dataFileContents != nil else {
            print("failed to load data")
            return
        }
        let lines:[String] = dataFileContents!.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: ",")
            if parts.count != 3 {
                print("line with fewer than three items")
                return
            }
            let student = parts[0].replacingOccurrences(of: "\"", with: "")
            let item = parts[1].replacingOccurrences(of: "\"", with: "")
            guard let score = Double(parts[2]) else {
                print("Score is not a number")
                return
            }
            if students[student] == nil {
                let newStudent = Student(name: student)
                newStudent.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
                students[student] = newStudent
            }
            if items[item] == nil {
                let newItem = Item(name: item)
                newItem.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
                items[item] = newItem
            }
            let newScore = Score(student: students[student]!, item: items[item]!, score: score)
            scores.append(newScore)
        }
//        testRun()
    }
    
    func integerToBinaryArray(_ number: Int, length: Int) -> [Double] {
        var binaryArray = [Double]()
        var num = number
        
        // Calculate binary representation
        while num > 0 {
            binaryArray.insert(Double(num % 2), at: 0)
            num /= 2
        }
        
        // Pad leading zeros if necessary
        let paddingCount = max(length - binaryArray.count, 0)
        binaryArray = Array(repeating: 0, count: paddingCount) + binaryArray
        
        return binaryArray
    }


    func generateData() {
        students = [:]
        items = [:]
        scores = []
        results = []
        synthetic = true
        for i in 0..<nItems {

            let j = Item(name: String(format: "%03d", i))
            j.realSkills = integerToBinaryArray(i, length: nSkills)
            j.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
            j.experiences = 5
            items[j.name] = j
        }
        for i in 0..<nStudents {
            let s = Student(name: String(format: "%04d",i))
            s.realSkills = integerToBinaryArray(Int.random(in: 0..<nItems), length: nSkills)
            s.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
            students[s.name] = s
        }
        for (_,s) in students {
            for (_,it) in items {
                var result = true
                for i in 0..<nSkills {
                    result = result && (s.realSkills[i] == 1 || it.realSkills[i] == 0)
                }
                let score = Score(student: s, item: it, score: (result ? Double.random(in: 0.4...1.0) : Double.random(in: 0.0...0.6)))
                scores.append(score)
            }
        }
//        testRun()
    }

    func calcProb(studentDifficulty: Double, itemDifficulty: Double) -> Double {
        return 1 - itemDifficulty + itemDifficulty * studentDifficulty
    }

    
    func oneItem(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
        let s = score.student
        let it = score.item
        var p: Double = 1
        var pmax: Double = 1
        for i in 0..<nSkills {
            let skillP = calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])
            p = p * skillP // worst case
            pmax = min(pmax, skillP) // best case
        }
        p = (p + pmax)/2
//        p = pmax
        for i in 0..<nSkills {
//            if score.score > p {
            s.skills[i] = s.skills[i] + alphaS * (1.5 - calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])) * (score.score - p)
            it.skills[i] = it.skills[i] + alphaI * (1.5 - calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])) * (p - score.score)

            it.experiences += 1
            if s.skills[i] < 0 {s.skills[i] = 0}
            if it.skills[i] < 0 {it.skills[i] = 0}
            if s.skills[i] > 1 {s.skills[i] = 1}
            if it.skills[i] > 1 {it.skills[i] = 1}
        }
    }
    
    
    func testRun() {
        let sortedKeys = Array(items.keys).sorted(by: <)
        var lineCounter = 0
        var counter = 0
        for j in 1...nEpochs {
            print("epoch", j)
            var order = Array(0..<scores.count)
            order.shuffle()
            for key in sortedKeys {
//                print(lineCounter,key,items[key]!.skills[0],items[key]!.skills[1],items[key]!.skills[2],items[key]!.skills[3] )
                lineCounter += 1
                for skills in 0..<nSkills {
                    let dp = ModelData(item: key, z: skills, x: lineCounter, y: items[key]!.skills[skills])
                    results.append(dp)
                }
            }
            for i in order {
                oneItem(score: scores[i], alphaS: alphaStudents, alphaI: alphaItems)
                counter += 1
                if counter == 1000 * nEpochs {
                    for key in sortedKeys {
//                        print(lineCounter,key,items[key]!.skills[0],items[key]!.skills[1],items[key]!.skills[2],items[key]!.skills[3] )
                        for skills in 0..<nSkills {
                            let dp = ModelData(item: key, z: skills, x: lineCounter, y: items[key]!.skills[skills])
                            results.append(dp)
                        }
                    }
                    lineCounter += 1
                    counter = 0
                }
            }
        }
//        for (_,item) in items {
//            item.skills = item.skills.map { round($0 * 10)/10 }
//        }
//        for (_,student) in students {
//            student.skills = student.skills.map { round($0 * 10)/10 }
//        }
        for key in sortedKeys {
            print(key,items[key]!.skills[0],items[key]!.skills[1],items[key]!.skills[2],items[key]!.skills[3] )
        }
        for _ in 1...20 {
            let student = scores[Int.random(in: 0..<scores.count)].student
            print(student.name, student.skills)
        }
    }
    
    func rerun() {
        if synthetic {
            generateData()
        } else {
            guard filename != nil else {return}
            loadDataWithString(filename!)
        }
        testRun()
    }
}
