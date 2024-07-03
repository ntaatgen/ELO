//
//  ELOlogic.swift
//  ELO
//
//  Created by Niels Taatgen on 3/7/24.
//

import Foundation

class Student: Codable {
    var name: String
    var realSkills: [Double] = []
    var skills: [Double] = []
    
    init(name: String) {
        self.name = name
    }
}

class Item: Codable {
    var name: String
    var realSkills: [Double] = []
    var skills: [Double] = []
    var experiences = 0
    
    init(name: String) {
        self.name = name
    }
}

class Score: Codable {
    var student: String
    var item: String
    var score: Double
    var time: Int
    
    init(student: Student, item: Item, score: Double, time: Int = 0) {
        self.student = student.name
        self.item = item.name
        self.score = score
        self.time = time
    }
}

struct ModelData: Identifiable, Codable {
    var id = UUID()
    var item: String
    var z: Int
    var x: Int
    var y: Double
}

class ELOlogic: Codable {
    static let alphaItemsDefault = 0.005
    static let nSkillsDefault = 4
    static let alphaStudentsDefault = 0.05
    static let alphaHebbDefault = 0.025
    static let epochsDefault = 1000
    var nSkills = ELOlogic.nSkillsDefault
    static let maxSkills = 8
    var nEpochs = ELOlogic.epochsDefault
    var alphaItems = ELOlogic.alphaItemsDefault
    var alphaStudents = ELOlogic.alphaStudentsDefault
    var alphaHebb = ELOlogic.alphaHebbDefault
    var skillThreshold = 0.5
    static let nItems = 16
    static let nStudents = 2000
    var students: [String:Student] = [:]
    var lastLoadedStudents: [String] = []
    var items: [String:Item] = [:]
    var scores: [Score] = []
    var sortedKeys: [String] { Array(items.keys).sorted(by: <) }
    var studentKeys: [String] = []
    var results: [ModelData] = []
    var errors: [ModelData] = []
    var studentResults: [ModelData] = []
    var filename: URL? = nil
    var studentSampleSize = 50
    var synthetic = false
    var partialSynthetic = false
//    var regression = [[Double]]()
    var timeList: [Int] = [0]
    var lineCounter = 0
    var counter = 0
    
    func loadDataWithURL(_ filePath: URL) {
        filename = filePath
        students = [:]
        items = [:]
        scores = []
        results = []
        studentResults = []
        errors = []
        lineCounter = 0
        counter = 0
        synthetic = false
//        regression = Array(repeating: Array(repeating: 0, count: nSkills), count: nSkills)
        addDataWithURL(filePath)
    }
    
    func addDataWithURL(_ filePath: URL) {
        var dataFileContents: String? = nil
        do {
            dataFileContents = try String(contentsOf: filePath, encoding: String.Encoding.utf8)
            
        } catch let error as NSError {
            print("Error \(error) in adding data.")
        }
        guard dataFileContents != nil else {
            print("failed to load data from \(filePath)")
            return
        }
        lastLoadedStudents = []
        let lines:[String] = dataFileContents!.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: ",")
            if parts.count == 0 {
                continue
            }
            if parts.count != 3 && parts.count != 4 {
                print("line with wrong number of items: \(parts)")
                continue
            }
            let student = parts[0].replacingOccurrences(of: "\"", with: "")
            let item = parts[1].replacingOccurrences(of: "\"", with: "")
            guard let score = Double(parts[2]) else {
                print("Score is not a number")
                continue
            }
            if students[student] == nil {
                let newStudent = Student(name: student)
                newStudent.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
                students[student] = newStudent
                lastLoadedStudents.append(student)
            }
            if items[item] == nil {
                let newItem = Item(name: item)
                newItem.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
                items[item] = newItem
                print("Adding \(item)")
            }
            let newScore = Score(student: students[student]!, item: items[item]!, score: score)
            if parts.count == 4 {
                if let time = Int(parts[3]) {
                    newScore.time = time
                    if !timeList.contains(time) {
                        timeList.append(time)
                        timeList.sort { $0 < $1 }
                    }
                }
            }
//            print(parts.count,newScore.time)
            scores.append(newScore)
        }
        studentKeys = Array(Array<String>(lastLoadedStudents).shuffled().prefix(studentSampleSize))
    }
    
    func resetModel() {
//        if synthetic && partialSynthetic {
//            generateDataReduced()
//            return
//        } else if synthetic {
//            generateDataFull()
//            return
//        }
//        for (_,student) in students {
//            student.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
//        }
//        for (_,item) in items {
//            item.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
//        }
        students = [:]
        items = [:]
        scores = []
        results = []
        studentResults = []
        errors = []
        synthetic = false
        lineCounter = 0
        counter = 0
//        regression = Array(repeating: Array(repeating: 0, count: nSkills), count: nSkills)
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
    
    
    func generateDataFull() {
        students = [:]
        items = [:]
        scores = []
        results = []
        synthetic = true
        partialSynthetic = false
        studentResults = []
        errors = []
        synthetic = false
        lineCounter = 0
        counter = 0
//        regression = Array(repeating: Array(repeating: 0, count: nSkills), count: nSkills)
        for i in 0..<ELOlogic.nItems {
            
            let j = Item(name: String(format: "%03d", i))
            j.realSkills = integerToBinaryArray(i, length: nSkills)
            j.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
            j.experiences = 0
            items[j.name] = j
        }
        for i in 0..<ELOlogic.nStudents {
            let s = Student(name: String(format: "%04d",i))
            let realSkill = Int.random(in: 0..<ELOlogic.nItems)
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
        nSkills = 4
        studentKeys = Array<String>(students.keys)
    }
    
    func generateDataReduced() {
        students = [:]
        items = [:]
        scores = []
        results = []
        synthetic = true
        partialSynthetic = true
        studentResults = []
        errors = []
        synthetic = false
        lineCounter = 0
        counter = 0
//        regression = Array(repeating: Array(repeating: 0, count: nSkills), count: nSkills)
        let itemSet = [0, 0, 0, 2, 2, 2, 2, 6, 6, 10, 10, 14, 14, 14, 11, 11, 15, 15, 15]
        for i in 0..<itemSet.count {
            let j = Item(name: String(format: "%03d-%03d", i, itemSet[i]))
            j.realSkills = integerToBinaryArray(itemSet[i], length: nSkills)
            j.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
            j.experiences = 0
            items[j.name] = j
        }
        for i in 0..<ELOlogic.nStudents {
            let s = Student(name: String(format: "%04d",i))
            let realSkill = itemSet[Int.random(in: 0..<itemSet.count)]
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
                let score = Score(student: s, item: it, score: (result ? Double.random(in: 0.6...1.0) : Double.random(in: 0.0...0.4)))
//                                let score = Score(student: s, item: it, score: (result ? 1.0 : 0.0))
                scores.append(score)
            }
        }
        nSkills = 4
        studentKeys = Array<String>(students.keys)

    }
    func calcProb(studentDifficulty: Double, itemDifficulty: Double) -> Double {
        return 1 - itemDifficulty + itemDifficulty * studentDifficulty
    }
    
    
    func expectedScore(s: Student, it: Item, leaveOut: Int? = nil) -> Double {
        var p: Double = 1
        for i in 0..<nSkills {
            if leaveOut == nil || leaveOut! != i {
                let skillP = calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])
                p = p * skillP
            }
        }
        return p
    }
    

    
    func boundedAdd(_ num1: Double, _ num2: Double, lwb: Double = 0.0, upb: Double = 1.0) -> Double {
        let s = num1 + num2
        if s < lwb { return lwb }
        else if s > upb { return upb }
        else { return s }
    }
    

    func oneItem(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
        let s = students[score.student]!
        let it = items[score.item]!
        let error = score.score - expectedScore(s: s, it: it)
        var expectedWithoutSkill: [Double] = []
        for i in 0..<nSkills {
            expectedWithoutSkill.append(expectedScore(s: s, it: it, leaveOut: i))
        }
        for i in 0..<nSkills {
            it.skills[i] = boundedAdd(it.skills[i], alphaI * expectedWithoutSkill[i] * error * (s.skills[i] - 1), upb: 1.0)
            s.skills[i] = boundedAdd(s.skills[i], alphaS * expectedWithoutSkill[i] * error * it.skills[i],lwb: 0.0)
        }
        /// Add some "Hebbian" learning
        if score.score > 0.7 {
            for i in 0..<nSkills {
                if it.skills[i] < s.skills[i] {
                    it.skills[i] += alphaI * alphaHebb * (s.skills[i] - it.skills[i]) * (score.score - 0.5) * 2
                }
            }
        }
        
        it.experiences += 1
    }
    

       
    func calculateError() -> Double {
        var error: Double = 0
        for score in scores {
            error += abs(score.score - expectedScore(s: students[score.student]!, it: items[score.item]!))
        }
        return error
    }
    
    func calculateErrorOnLastAdd() -> Double {
        var error: Double = 0
        var count: Int = 0
        for score in scores {
            if lastLoadedStudents.contains(score.student) {
                error += abs(score.score - expectedScore(s: students[score.student]!, it: items[score.item]!))
                count += 1
            }
        }
        return error/Double(count)
    }
    
    func calculateModel(time: Int) {
        DispatchQueue.global().async { [self] () -> Void in
            
            for j in 0..<nEpochs {
                print("epoch", j)
                var order = Array(0..<scores.count)
                order.shuffle()
                if j % (nEpochs/10) == 0 {
                    for key in sortedKeys {
                        if items[key]!.experiences > 0 {
                            for skills in 0..<nSkills {
                                let dp = ModelData(item: key, z: skills, x: lineCounter, y: items[key]!.skills[skills])
                                results.append(dp)
                            }
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
                    lineCounter += (nEpochs/10)
                }

                for i in 0..<order.count {
                    if scores[order[i]].time == time {
                        oneItem(score: scores[order[i]], alphaS: alphaStudents, alphaI: alphaItems)
                    }
                }
                if j % 100 == 0 {
                    DispatchQueue.main.async {
                        self.counter = j
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateGraph"), object: nil)
                    }
                } else {
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "runDone"), object: nil)
                    }
                }
                
            }
            
            for key in sortedKeys {
                print(key,items[key]!.skills)
            }
            DispatchQueue.main.async {
                self.counter = self.nEpochs
                NotificationCenter.default.post(name: Notification.Name(rawValue: "updateGraph"), object: nil)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "endRun"), object: nil)

            }
        }
    }
    
    func calculateModelForBatch(time: Int) {            
            for j in 0..<nEpochs {
                print("epoch", j)
                var order = Array(0..<scores.count)
                order.shuffle()
                if j % (nEpochs/10) == 0 {
                    for key in sortedKeys {
                        if items[key]!.experiences > 0 {
                            for skills in 0..<nSkills {
                                let dp = ModelData(item: key, z: skills, x: lineCounter, y: items[key]!.skills[skills])
                                results.append(dp)
                            }
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
                    lineCounter += (nEpochs/10)
                }

                for i in 0..<order.count {
                    if scores[order[i]].time == time {
                        oneItem(score: scores[order[i]], alphaS: alphaStudents, alphaI: alphaItems)
                    }
                }

                
            }
            
            for key in sortedKeys {
                print(key,items[key]!.skills)
            }
                self.counter = self.nEpochs
    }

    
    func run(time: Int) {
            self.calculateModel(time: time)
    }
}
