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
