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
    var offsetParameter = 2.0
    var skillThreshold = 0.5
    let nItems = 16
    let nStudents = 2000
    var students: [String:Student] = [:]
    var items: [String:Item] = [:]
    var scores: [Score] = []
    var sortedKeys: [String] { Array(items.keys).sorted(by: <) }
    var studentKeys: [String] = []
    var results: [ModelData] = []
    var errors: [ModelData] = []
    var studentResults: [ModelData] = []
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
            let realSkill = Int.random(in: 0..<nItems)
            s.realSkills = integerToBinaryArray(realSkill, length: nSkills)
            s.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
            s.name +=  "s" + String(realSkill)
            students[s.name] = s
        }
        for (_,s) in students {
            for (_,it) in items {
                var result = true
                for i in 0..<nSkills {
                    result = result && (s.realSkills[i] == 1 || it.realSkills[i] == 0)
                }
                let score = Score(student: s, item: it, score: (result ? Double.random(in: 0.4...1.0) : Double.random(in: 0.0...0.6)))
//                let score = Score(student: s, item: it, score: (result ? 1.0 : 0.0))
                scores.append(score)
            }
        }
//        testRun()
    }

    func calcProb(studentDifficulty: Double, itemDifficulty: Double) -> Double {
        return 1 - itemDifficulty + itemDifficulty * studentDifficulty
    }
    
    func expectedScore(s: Student, it: Item) -> Double {
        var p: Double = 1
        var pmin: Double = 1
        for i in 0..<nSkills {
            let skillP = calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])
            p = p * skillP // worst case
            pmin = min(pmin, skillP) // best case
        }
        p = (p + pmin)/2
        return p
    }

    
    func oneItem(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
        let s = score.student
        let it = score.item
        let p = expectedScore(s: s, it: it)
        for i in 0..<nSkills {
            s.skills[i] = s.skills[i] + alphaS * (offsetParameter - calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])) * (score.score - p)
            it.skills[i] = it.skills[i] + alphaI * (offsetParameter - calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])) * (p - score.score)

            it.experiences += 1
            if s.skills[i] < 0 {s.skills[i] = 0}
            if it.skills[i] < 0 {it.skills[i] = 0}
            if s.skills[i] > 1 {s.skills[i] = 1}
            if it.skills[i] > 1 {it.skills[i] = 1}
        }
    }
    
    func twoItems(scoreIndex1: Int, scoreIndex2: Int, alpha: Double = 0.01) {
        // TODO: Find a better way to get two scores from the same student
        let item1 = scores[scoreIndex1]
        let item2 = scores[scoreIndex2]
        guard item1.student.name == item2.student.name else {
            print("Illegal call of twoItems")
            return
        }
//        var item2index: Int? = nil
//        var i = scoreIndex + 1
//        while item2index == nil && i < scores.count {
//            if item1.student.name == scores[i].student.name {
//                item2index = i
//            }
//            i += 1
//        }
//        if item2index == nil { return }
//        let item2 = scores[item2index!]
        let expected1 = expectedScore(s: item1.student, it: item1.item)
        let expected2 = expectedScore(s: item2.student, it: item2.item)
        if item1.score > expected1 && item2.score < expected2 { // item1 is easier than expected and item2 harder
            for i in 0..<nSkills {
//                if item1.item.skills[i] < item2.item.skills[i] { // was  >
                    item1.item.skills[i] -= alpha * (item1.score - expected1) // decrease
                    item2.item.skills[i] += alpha * (expected2 - item2.score) // increase
//                }
            }
        } else if item1.score < expected1 && item2.score > expected2 { // item1 is harder than expected and item2 easier
            for i in 0..<nSkills {
                if item1.item.skills[i] > item2.item.skills[i] { // was <
                    item1.item.skills[i] += alpha * (expected1 - item1.score) // increase
                    item2.item.skills[i] -= alpha * (item2.score - expected2) // decrease
                }
            }
        } 
        else if item1.score > expected1 && item2.score > expected2 { // both easier than expected
            for i in 0..<nSkills {
                if item1.item.skills[i] < item2.item.skills[i] {
                    item2.item.skills[i] -= alpha * (item2.score - expected2) // decrease item2
                } else {
                    item1.item.skills[i] -= alpha * (item1.score - expected1) // decrease item1
                }
            }
        } else if item1.score < expected1 && item2.score < expected2 { // both harder than expected
            for i in 0..<nSkills {
                if item1.item.skills[i] > item2.item.skills[i] {
                    item2.item.skills[i] += alpha * (expected2 - item2.score) // increase item2
                } else {
                    item1.item.skills[i] += alpha * (expected1 - item1.score) // increase item1
                }
            }
        }
    }
    
    func calculateError() -> Double {
        var error: Double = 0
        for score in scores {
            error += abs(score.score - expectedScore(s: score.student, it: score.item))
        }
        return error
    }
    
    
    func testRun() {
//        let sortedKeys = Array(items.keys).sorted(by: <)
        studentKeys = Array(Array<String>(students.keys).shuffled().prefix(20))
        var lineCounter = 0
        var counter = 0
        errors = []
        for j in 1...nEpochs {
            print("epoch", j)
            var order = Array(0..<scores.count)
            order.shuffle()
//            order.sort { scores[$0].student.name < scores[$1].student.name }
//            for i in 0..<(scores.count / 2) {
//                let j = Int.random(in: 0..<(scores.count / 2))
//                let tmp1 = order[i * 2]
//                order[i * 2] = order[j * 2]
//                order[j * 2] = tmp1
//                let tmp2 = order[i * 2 + 1]
//                order[i * 2 + 1] = order[j * 2 + 1]
//                order[j * 2 + 1] = tmp2
//            }
//            for i in 0..<scores.count {
//                print(scores[order[i]].student.name)
//            }
            for key in sortedKeys {
                for skills in 0..<nSkills {
                    let dp = ModelData(item: key, z: skills, x: lineCounter, y: items[key]!.skills[skills])
                    results.append(dp)
                }
            }
            for key in studentKeys {
                for skills in 0..<nSkills {
                    let dp = ModelData(item: key, z: skills, x: lineCounter, y: students[key]!.skills[skills])
                    studentResults.append(dp)
                }
            }
            lineCounter += 1
            for i in 0..<order.count {
                oneItem(score: scores[order[i]], alphaS: alphaStudents, alphaI: alphaItems)
//                if i < order.count - 1 && scores[order[i]].student.name == scores[order[i+1]].student.name {
//                    twoItems(scoreIndex1: order[i], scoreIndex2: order[i+1])
//                }
                counter += 1
                if counter == 1000 * nEpochs {
                    for key in sortedKeys {
                        for skills in 0..<nSkills {
                            let dp = ModelData(item: key, z: skills, x: lineCounter, y: items[key]!.skills[skills])
                            results.append(dp)
                        }
                    }
                    for key in studentKeys {
                        for skills in 0..<nSkills {
                            let dp = ModelData(item: key, z: skills, x: lineCounter, y: students[key]!.skills[skills])
                            studentResults.append(dp)
                        }
                    }
                    let dp = ModelData(item: "error", z: 0, x: lineCounter, y: calculateError())
                    errors.append(dp)
                    lineCounter += 1
                    counter = 0
//                    print(calculateError())
                }
            }
        }

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
