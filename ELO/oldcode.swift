//
//  oldcode.swift
//  ELO
//
//  Created by Niels Taatgen on 22/05/2024.
//

import Foundation

//    func oneItem(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
//        let s = score.student
//        let it = score.item
//        let p = expectedScore(s: s, it: it)
//        for i in 0..<nSkills {
//
//            s.skills[i] = s.skills[i] + alphaS * (offsetParameter - calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])) * (score.score - p)
//            it.skills[i] = it.skills[i] + alphaI * (offsetParameter - calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])) * (p - score.score)
//
//            if s.skills[i] < 0 {s.skills[i] = 0}
//            if it.skills[i] < 0 {it.skills[i] = 0}
//            if s.skills[i] > 1 {s.skills[i] = 1}
//            if it.skills[i] > 1 {it.skills[i] = 1}
//        }
//        it.experiences += 1
//    }
    

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

//    func twoItems(scoreIndex1: Int, scoreIndex2: Int, alpha: Double = 0.01) {
//        let item1 = scores[scoreIndex1]
//        let item2 = scores[scoreIndex2]
//        guard item1.student.name == item2.student.name else {
//            print("Illegal call of twoItems")
//            return
//        }
//
//        let expected1 = expectedScore(s: item1.student, it: item1.item)
//        let expected2 = expectedScore(s: item2.student, it: item2.item)
//        if item1.score > expected1 && item2.score < expected2 { // item1 is easier than expected and item2 harder
//            for i in 0..<nSkills {
////                if item1.item.skills[i] < item2.item.skills[i] { // was  >
//                    item1.item.skills[i] -= alpha * (item1.score - expected1) // decrease
//                    item2.item.skills[i] += alpha * (expected2 - item2.score) // increase
////                }
//            }
//        } else if item1.score < expected1 && item2.score > expected2 { // item1 is harder than expected and item2 easier
//            for i in 0..<nSkills {
//                if item1.item.skills[i] > item2.item.skills[i] { // was <
//                    item1.item.skills[i] += alpha * (expected1 - item1.score) // increase
//                    item2.item.skills[i] -= alpha * (item2.score - expected2) // decrease
//                }
//            }
//        }
//        else if item1.score > expected1 && item2.score > expected2 { // both easier than expected
//            for i in 0..<nSkills {
//                if item1.item.skills[i] < item2.item.skills[i] {
//                    item2.item.skills[i] -= alpha * (item2.score - expected2) // decrease item2
//                } else {
//                    item1.item.skills[i] -= alpha * (item1.score - expected1) // decrease item1
//                }
//            }
//        } else if item1.score < expected1 && item2.score < expected2 { // both harder than expected
//            for i in 0..<nSkills {
//                if item1.item.skills[i] > item2.item.skills[i] {
//                    item2.item.skills[i] += alpha * (expected2 - item2.score) // increase item2
//                } else {
//                    item1.item.skills[i] += alpha * (expected1 - item1.score) // increase item1
//                }
//            }
//        }
//    }


//func expectedScoreOld(s: Student, it: Item, leaveOut: Int? = nil) -> Double {
//    var p: Double = 1
//    var pmin: Double = 1
//    for i in 0..<nSkills {
//        if leaveOut == nil || leaveOut! != i {
//            let skillP = calcProb(studentDifficulty: s.skills[i], itemDifficulty: it.skills[i])
//            p = p * skillP // worst case
//            pmin = min(pmin, skillP) // best case
//        }
//    }
////        p = (p + pmin)/2
//    return p
//}

func relu(_ x:Double) -> Double {
    return x > 0 ? x : 0
}

//    func correctForRegression(skills: [Double], index: Int) -> Double {
//        var result = skills[index]
//        for j in 0..<skills.count {
//            if index != j {
//                result += relu(regression[index][j] * skills[j])
//            }
//        }
//        result = boundedAdd(result, 0)
//        return result
//    }

//    func correctForRegression(skills: [Double]) -> [Double] {
//        var newSkills = skills
//        for i in 0..<skills.count {
//            for j in 0..<skills.count {
//                if i != j {
//                    newSkills[i] += relu(regression[i][j] * skills[j])
//                }
//            }
//            newSkills[i] = boundedAdd(newSkills[i], 0)
//        }
//        return newSkills
//    }


func sigmoid(_ x: Double) -> Double {
    return 1 / (1 + exp(-x*10))
}

func derivativeOfSigmoid(_ x: Double) -> Double {
    return sigmoid(x) * (1 - sigmoid(x))
}

func oneItemAlt2(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
    let s = students[score.student]!
    let it = items[score.item]!
    let error = score.score - expectedScore(s: s, it: it)
    var expectedWithoutSkill: [Double] = []
    for i in 0..<nSkills {
        expectedWithoutSkill.append(expectedScore(s: s, it: it, leaveOut: i))
    }
    for i in 0..<nSkills {
        it.skills[i] = boundedAdd(it.skills[i], alphaI * derivativeOfSigmoid((it.skills[i] - 0.5) * 5) * expectedWithoutSkill[i] * error * (s.skills[i] - 1), upb: 0.9)
        s.skills[i] = boundedAdd(s.skills[i], alphaS * derivativeOfSigmoid((s.skills[i] - 0.5) * 5) * expectedWithoutSkill[i] * error *  it.skills[i], lwb: 0.1)
    }
    it.experiences += 1
//        if false {
//            let alpha = 0.00001
//            for i in 0..<nSkills {
//                for j in 0..<nSkills {
//                    regression[i][j] = boundedAdd(regression[i][j], alpha * error * calcDeltaRegression(i: i, j: j, s: s, it: it))
//                }
//            }
//        }
//        updateRegressionItem(it: it)
}

func oneItemAlt(score:Score, alphaS: Double = 0.5, alphaI: Double = 0.05) {
    let s = students[score.student]!
    let it = items[score.item]!
    let error = score.score - expectedScore(s: s, it: it)
//        print(expectedScore(s: s, it: it))
    var expectedWithoutSkill: [Double] = []
    for i in 0..<nSkills {
        expectedWithoutSkill.append(expectedScore(s: s, it: it, leaveOut: i))
    }
    for i in 0..<nSkills {
        it.skills[i] = boundedAdd(it.skills[i], -alphaI * expectedWithoutSkill[i] * error * derivativeOfSigmoid(s.skills[i] - it.skills[i]))
        s.skills[i] = boundedAdd(s.skills[i], alphaS  * expectedWithoutSkill[i] * error *  derivativeOfSigmoid(s.skills[i] - it.skills[i]))
    }
    it.experiences += 1
//        if false {
//            let alpha = 0.00001
//            for i in 0..<nSkills {
//                for j in 0..<nSkills {
//                    regression[i][j] = boundedAdd(regression[i][j], alpha * error * calcDeltaRegression(i: i, j: j, s: s, it: it))
//                }
//            }
//        }
//        updateRegressionItem(it: it)
}
        
func updateRegressionOld(s: Student, alpha: Double = 0.01) {
    for i in 0..<nSkills {
        var expected = regression[i][i]
        for j in 0..<nSkills {
            if i != j {
                expected += regression[i][j] * s.skills[j]
            }
        }
        let error = s.skills[i] - expected
        regression[i][i] += alpha * error
        for j in 0..<nSkills {
            if i != j {
                regression[i][j] += alpha * error * s.skills[j]
            }
        }
    }
}

func updateRegression(s: Student, alpha: Double = 0.01) {
    for i in 0..<nSkills {
        for j in 0..<nSkills {
            if i != j {
                regression[i][j] += alpha * ( (s.skills[i] - s.skills[j]) - regression[i][j])
            }
        }
    }
}

func updateRegressionItem(it: Item, alpha: Double = 0.01) {
    for i in 0..<nSkills {
        for j in 0..<nSkills {
            if i != j {
                regression[i][j] += alpha * ( (it.skills[i] - it.skills[j]) - regression[i][j])
            }
        }
    }
}

func calcDeltaRegression(i: Int, j: Int, s: Student, it: Item) -> Double {
    let delta = 0.01
    var x = 1.0
    for k in 0..<nSkills {
        x *= expectedScore(s: s, it: it, leaveOut: k)
    }
    regression[i][j] += delta
    var xPlusDelta = 1.0
    for k in 0..<nSkills {
        xPlusDelta *= expectedScore(s: s, it: it, leaveOut: k)
    }
    regression[i][j] -= delta
    return (xPlusDelta - x) / delta
}
func expectedScoreAlt(s: Student, it: Item, leaveOut: Int? = nil) -> Double {
    var p: Double = 1
    for i in 0..<nSkills {
        if leaveOut == nil || leaveOut! != i {
            let skillP = sigmoid(s.skills[i] - it.skills[i])
            p = p * skillP
        }
    }
    return p
}
