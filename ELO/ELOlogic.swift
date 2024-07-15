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
    var m: [Double] = []
    var v: [Double] = []
    var t: Int = 1
    init(name: String, nSkills: Int) {
        self.name = name
        self.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
        self.m = (0..<nSkills).map {_ in 0 }
        self.v = (0..<nSkills).map {_ in 0 }
    }
}

class Item: Codable {
    var name: String
    var realSkills: [Double] = []
    var skills: [Double] = []
    var experiences = 0
    var m: [Double] = []
    var v: [Double] = []
    var t: Int = 1
    init(name: String, nSkills: Int) {
        self.name = name
        self.skills = (0..<nSkills).map { _ in .random(in: 0.4...0.6) }
        self.m = (0..<nSkills).map {_ in 0 }
        self.v = (0..<nSkills).map {_ in 0 }
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
    static let alphaItemsDefault = 0.001
    static let nSkillsDefault = 4
    static let alphaStudentsDefault = 0.05
    static let alphaHebbDefault = 1.0
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
    var timeList: [Int] = [0]
    var lineCounter = 0
    var counter = 0
    var showLastLoadedStudents = false
    
    /// Reset the model an load data from URL
    /// - Parameter filePath: The file to be loaded
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
        addDataWithURL(filePath)
    }
    
    
    
    /// Add data to the model from URL
    /// - Parameter filePath: The file to be added
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
                let newStudent = Student(name: student, nSkills: nSkills)
                students[student] = newStudent
                lastLoadedStudents.append(student)
            }
            if items[item] == nil {
                let newItem = Item(name: item, nSkills: nSkills)
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
            scores.append(newScore)
        }
        if showLastLoadedStudents {
            studentKeys = Array(Array<String>(lastLoadedStudents).shuffled().prefix(studentSampleSize))
        } else {
            studentKeys = Array(Array<String>(students.keys).shuffled().prefix(studentSampleSize))
        }
    }
    
    /// Reset the model
    func resetModel() {
        students = [:]
        items = [:]
        scores = []
        results = []
        studentResults = []
        errors = []
        synthetic = false
        lineCounter = 0
        counter = 0
    }
    
    /// Convert an integer to a binary representation
    /// - Parameters:
    ///   - number: The integer to convert
    ///   - length: the number of digits in the binary number
    /// - Returns: An array with binary digits
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
    
    
    /// Initialize the model with generated data. The data covers all possible combinations of skills.
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
        for i in 0..<ELOlogic.nItems {
            
            let j = Item(name: String(format: "%03d", i), nSkills: nSkills)
            j.realSkills = integerToBinaryArray(i, length: nSkills)
            items[j.name] = j
        }
        for i in 0..<ELOlogic.nStudents {
            let s = Student(name: String(format: "%04d",i), nSkills: nSkills)
            let realSkill = Int.random(in: 0..<ELOlogic.nItems)
            s.realSkills = integerToBinaryArray(realSkill, length: nSkills)
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
    
    /// Initialize the model with generated data. The data covers only a subset of possible combinations of skills.
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
            let j = Item(name: String(format: "%03d-%03d", i, itemSet[i]), nSkills: nSkills)
            j.realSkills = integerToBinaryArray(itemSet[i], length: nSkills)
            j.experiences = 0
            items[j.name] = j
        }
        for i in 0..<ELOlogic.nStudents {
            let s = Student(name: String(format: "%04d",i), nSkills: nSkills)
            let realSkill = itemSet[Int.random(in: 0..<itemSet.count)]
            s.realSkills = integerToBinaryArray(realSkill, length: nSkills)
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
    
    /// Calculate the predicted score base on a single skill, given a student score and an item score.
    /// - Parameters:
    ///   - studentDifficulty: The student score, between 0 and 1.
    ///   - itemDifficulty: The item score, between 0 and 1.
    /// - Returns: The expected score for one skill.
    func calcProb(studentDifficulty: Double, itemDifficulty: Double) -> Double {
        return 1 - itemDifficulty + itemDifficulty * studentDifficulty
    }
    
    
    /// Expected score for a student and item
    /// - Parameters:
    ///   - s: The student
    ///   - it: The item
    ///   - leaveOut: Optionally: leave one vector item out, necessary for calculating the gradient
    /// - Returns: The expected score.
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
    

    
    /// Add to two numbers, but keep them between a lowerbound and an upperbound
    /// - Parameters:
    ///   - num1: The first number
    ///   - num2: The second number
    ///   - lwb: The lowerbound, 0 by default
    ///   - upb: The upperbound, 1 by default
    /// - Returns: The bounded sum
    func boundedAdd(_ num1: Double, _ num2: Double, lwb: Double = 0.0, upb: Double = 1.0) -> Double {
        let s = num1 + num2
        if s < lwb { return lwb }
        else if s > upb { return upb }
        else { return s }
    }
    
//
//    func oneItem(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
//        let s = students[score.student]!
//        let it = items[score.item]!
//        let error = score.score - expectedScore(s: s, it: it)
//        var expectedWithoutSkill: [Double] = []
//        for i in 0..<nSkills {
//            expectedWithoutSkill.append(expectedScore(s: s, it: it, leaveOut: i))
//        }
//        for i in 0..<nSkills {
//            it.skills[i] = boundedAdd(it.skills[i], alphaI * expectedWithoutSkill[i] * error * (s.skills[i] - 1), upb: 1.0)
//            s.skills[i] = boundedAdd(s.skills[i], alphaS * expectedWithoutSkill[i] * error * it.skills[i],lwb: 0.0)
//        }
//        /// Add some "Hebbian" learning
//        if score.score > 0.7 {
//            for i in 0..<nSkills {
//                if it.skills[i] < s.skills[i] {
//                    it.skills[i] += alphaI * alphaHebb * (s.skills[i] - it.skills[i]) * (score.score - 0.5) * 2
//                }
//            }
//        }
//        
//        it.experiences += 1
//    }
    
    /// Update the model based on a single datapoint using Adam optimization
    /// - Parameters:
    ///   - score: The datapoint used for the update
    ///   - alpha: The alpha parameter for Adam, 0.001 by default
    ///   - beta1: The beta1 parameter for Adam, 0.9 by default
    ///   - beta2: The beta2 parameter for Adam, 0.99 by default
    ///   - epsilon: The epsilon parameter, 1e-8 by default
    ///   - alphaHebb: Learning multiplier (with alpha) to control the Hebbian learning.
    func oneItemAdam(score: Score, alpha: Double = 0.001, beta1: Double = 0.9, beta2: Double = 0.999, epsilon: Double = 1e-8, alphaHebb: Double = 1.0) {
        let s = students[score.student]!
        let it = items[score.item]!
        let error = expectedScore(s: s, it: it) - score.score
        var expectedWithoutSkill: [Double] = []
        for i in 0..<nSkills {
            expectedWithoutSkill.append(expectedScore(s: s, it: it, leaveOut: i))
        }
        for i in 0..<nSkills {
            it.m[i] = beta1 * it.m[i] + (1 - beta1) * expectedWithoutSkill[i] * (s.skills[i] - 1) * error
            it.v[i] = beta2 * it.v[i] + (1 - beta2) * pow(expectedWithoutSkill[i] * (s.skills[i] - 1) * error, 2)
            let mhatI = it.m[i] / (1 - pow(beta1, Double(it.t)))
            let vhatI = it.v[i] / (1 - pow(beta2, Double(it.t)))
            
            s.m[i] = beta1 * s.m[i] + (1 - beta1) * expectedWithoutSkill[i] * it.skills[i] * error
            s.v[i] = beta2 * s.v[i] + (1 - beta2) * pow(expectedWithoutSkill[i] * it.skills[i] * error, 2)
            let mhatS = s.m[i] / (1 - pow(beta1, Double(s.t)))
            let vhatS = s.v[i] / (1 - pow(beta2, Double(s.t)))
            
            it.skills[i] = boundedAdd(it.skills[i], -alpha * mhatI / (sqrt(vhatI) + epsilon))
            s.skills[i] = boundedAdd(s.skills[i],  -alpha * mhatS / (sqrt(vhatS) + epsilon))
        }
        it.t += 1
        s.t += 1
        /// Add some "Hebbian" learning
        if score.score > 0.7 {
            for i in 0..<nSkills {
                if it.skills[i] < s.skills[i] {
                    it.skills[i] += alpha * alphaHebb * (s.skills[i] - it.skills[i]) * (score.score - 0.5)
                }
            }
        }
        it.experiences += 1

    }

    
    /// Calculate the average error per datapoint, either of the whole dataset, or the last loaded students.
    ///     /// - Returns: The average error
    func calculateError() -> Double {
        var error: Double = 0
        var count: Int = 0
        for score in scores {
            if !showLastLoadedStudents || lastLoadedStudents.contains(score.student) {
                error += abs(score.score - expectedScore(s: students[score.student]!, it: items[score.item]!))
                count += 1
            }
        }
        return error/Double(count)
    }
    
    /// Update the model for nEpoch epochs.
    /// - Parameter time: If set, only process datapoints at that time, if nil process all datapoints
    func calculateModel(time: Int?) {
        DispatchQueue.global().async { [self] () -> Void in
            for j in 0..<nEpochs {
                print("epoch", j)
                var order = Array(0..<scores.count)
                order.shuffle()
                if nEpochs < 20 || j % (nEpochs/10) == 0 {
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
                    if time == nil || scores[order[i]].time == time! {
//                        oneItem(score: scores[order[i]], alphaS: alphaStudents, alphaI: alphaItems)
                        oneItemAdam(score: scores[order[i]], alpha: alphaItems, alphaHebb: alphaHebb)
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
    
    /// Same as calculateModel, except it does not run in the background and does not update the View.
    /// - Parameter time: If set, only process datapoints at that time, if nil process all datapoints
    func calculateModelForBatch(time: Int!) {
            for j in 0..<nEpochs {
                print("epoch", j)
                var order = Array(0..<scores.count)
                order.shuffle()
                if nEpochs < 20 || j % (nEpochs/10) == 0 {
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
                    if time == nil || scores[order[i]].time == time! {
                        oneItemAdam(score: scores[order[i]], alpha: alphaItems, alphaHebb: alphaHebb)
//                        oneItem(score: scores[order[i]], alphaS: alphaStudents, alphaI: alphaItems)
                    }
                }

                
            }
            
            for key in sortedKeys {
                print(key,items[key]!.skills)
            }
                self.counter = self.nEpochs
    }

}
