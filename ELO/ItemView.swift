//
//  ItemView.swift
//  ELO
//
//  Created by Niels Taatgen on 27/09/2024.
//

import SwiftUI

enum MCType {
    case radio
    case menu
}

enum Question: Hashable {
    case text(prompt: String, answers: [String], points: Double, index: Int)
    case multipleChoice(prompt: String, options: [String], correct: Int, points: Double, type: MCType, index: Int)
    case realNumber(prompt: String, answer: Double, points: Double, index: Int)
    case intNumber(prompt: String, answer: Int, points: Double, index: Int)
}

struct ItemInfo {
    var title: String?
    var image: NSImage?
    var extraText: String?
    var questions: [Question] = []
    var name: String = ""
    
    func splitLine(line: String) -> (String, String)? {
        let index = line.firstIndex(of: ":")
        if index == nil { return nil }
        let indexPlusOne = line.index(after: index!)
//        print(String(line.prefix(upTo: index!)), line.suffix(from: indexPlusOne).trimmingCharacters(in: .whitespacesAndNewlines))
        return (String(line.prefix(upTo: index!)), line.suffix(from: indexPlusOne).trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    mutating func parseTextQuestion(argument: String, lines: [String], index: Int, order: Int) -> (Question, Int) {
        var answers: [String] = []
        var points = 1.0
        var i = index
        var done = false
        while i < lines.count && !done {
            if let (command, argument) = splitLine(line: lines[i]) {
                switch command {
                case "answer","answers": answers = argument.components(separatedBy: ",")
                    for i in 0..<answers.count {
                        answers[i] = answers[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                case "points": if let x = Double(argument) {
                    points = x
                }
                default:
                    i -= 1
                    done = true
                }
            }
            i += 1
        }
        return((Question.text(prompt: argument, answers: answers, points: points, index: order), i-1))
    }
    
    mutating func parseRealQuestion(argument: String, lines: [String], index: Int, order: Int) -> (Question, Int) {
        var answer: Double = 0
        var points = 1.0
        var i = index
        var done = false
        while i < lines.count && !done {
            if let (command, argument) = splitLine(line: lines[i]) {
                switch command {
                case "answer": if let x = Double(argument.replacingOccurrences(of: ",", with: ".")) {
                    answer = x
                }
                case "points": if let x = Double(argument) {
                    points = x
                }
                default:
                    i -= 1
                    done = true
                }
            }
            i += 1
        }
        return((Question.realNumber(prompt: argument, answer: answer, points: points, index: order), i-1))
    }

    mutating func parseIntQuestion(argument: String, lines: [String], index: Int, order: Int) -> (Question, Int) {
        var answer: Int = 0
        var points = 1.0
        var i = index
        var done = false
        while i < lines.count && !done {
            if let (command, argument) = splitLine(line: lines[i]) {
                switch command {
                case "answer": if let x = Int(argument) {
                    answer = x
                }
                case "points": if let x = Double(argument) {
                    points = x
                }
                default:
                    i -= 1
                    done = true
                }
            }
            i += 1
        }
        return((Question.intNumber(prompt: argument, answer: answer, points: points, index: order), i-1))
    }
    
    mutating func parseMCQuestion(argument: String, lines: [String], index: Int, type: MCType, order: Int) -> (Question, Int) {
        var answer: Int = 0
        var points = 1.0
        var i = index
        var options: [String] = []
        var done = false
        while i < lines.count && !done {
            if let (command, argument) = splitLine(line: lines[i]) {
                switch command {
                case "answer": if let x = Int(argument) {
                    answer = x
                }
                case "points": if let x = Double(argument) {
                    points = x
                }
                case "option": options.append(argument)
                default:
                    i -= 1
                    done = true
                }
            }
            i += 1
        }
        return ((Question.multipleChoice(prompt: argument, options: options, correct: answer, points: points, type: type, index: order), i-1))
    }

    
    init(name: String, loadPath: URL) {
        self.name = name
        let imgUrl = loadPath.appendingPathComponent("images/" + name + ".png")
        if let img = NSImage(contentsOf: imgUrl) {
            self.image = img
        }
        let url = loadPath.appendingPathComponent("items/" + name + ".txt")
        let text = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        guard text != nil else { return }
        let lines = text!.components(separatedBy: "\n")
        var lineIndex = 0
        var questionIndex = 0
        while lineIndex < lines.count {
             if let (command, argument) = splitLine(line: lines[lineIndex]) {
                 print("Command \(command)")
                switch command {
                case "title": self.title = argument
                case "text": self.extraText = argument
                case "question", "text-question": let (question, newIndex) = parseTextQuestion(argument: argument, lines: lines, index: lineIndex + 1, order: questionIndex)
                    lineIndex = newIndex
                    questions.append(question)
                    questionIndex += 1
                case "real-question": let (question, newIndex) = parseRealQuestion(argument: argument, lines: lines, index: lineIndex + 1, order: questionIndex)
                    lineIndex = newIndex
                    questions.append(question)
                    questionIndex += 1
                case "int-question": let (question, newIndex) = parseIntQuestion(argument: argument, lines: lines, index: lineIndex + 1, order: questionIndex)
                    lineIndex = newIndex
                    questions.append(question)
                    questionIndex += 1
                case "mc-question": let (question, newIndex) = parseMCQuestion(argument: argument, lines: lines, index: lineIndex + 1, type: .radio, order: questionIndex)
                    lineIndex = newIndex
                    questions.append(question)
                    questionIndex += 1
                case "menu-question": let (question, newIndex) = parseMCQuestion(argument: argument, lines: lines, index: lineIndex + 1, type: .menu, order: questionIndex)
                    lineIndex = newIndex
                    questions.append(question)
                    questionIndex += 1
                default: break
                }
            }
            lineIndex += 1
        }

    }
}


struct ItemView: View {
    var model: ELOViewModel
    var itemInfo: ItemInfo
    var groupsize: Int
    @State var feedback = [Color](repeating: Color.white, count: 10)
    @State var answerArray = [String](repeating: "", count: 10)
    @State var answerGiven = false
    var body: some View {
        VStack {
            if itemInfo.title != nil {
                Text(itemInfo.title!)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            }
            if itemInfo.image != nil {
                Image(nsImage: itemInfo.image!)
            }
            if itemInfo.extraText != nil {
                Text(itemInfo.extraText!)
            }
            VStack {
                ForEach(itemInfo.questions, id: \.self) { question in
                    HStack {
                        switch question {
                        case .text(let prompt, let answers, _, let qIndex):
                            Text(prompt)
                            TextField(answers[0], text: $answerArray[qIndex])
                                .overlay(Rectangle()
                                    .stroke(feedback[qIndex], lineWidth: 4))
                        case  .realNumber(let prompt, let answer, _, let qIndex):
                            Text(prompt)
                            TextField(String(answer), text: $answerArray[qIndex])
                                .overlay(Rectangle()
                                    .stroke(feedback[qIndex], lineWidth: 4))                        
                        case .intNumber(let prompt, let answer, _, let qIndex):
                            Text(prompt)
                            TextField(String(answer), text: $answerArray[qIndex])
                                .overlay(Rectangle()
                                    .stroke(feedback[qIndex], lineWidth: 4))
                        case .multipleChoice(prompt: let prompt, options: let options, _, _, .menu, let qIndex):
                            VStack {
                                Picker(selection: $answerArray[qIndex], label: Text(prompt)) {
                                    ForEach(options, id:\.self) { label in
                                        Text(label)
                                    }
                                }
                                .overlay(Rectangle()
                                    .stroke(feedback[qIndex], lineWidth: 1))
                            }
                            
                        case .multipleChoice(prompt: let prompt, options: let options, _, _, .radio, let qIndex):
                            VStack {
                                Picker(selection: $answerArray[qIndex], label: Text(prompt)) {
                                    ForEach(options, id:\.self) { label in
                                        Text(label)
                                    }
                                } .pickerStyle(RadioGroupPickerStyle())
                                    .overlay(Rectangle()
                                        .stroke(feedback[qIndex], lineWidth: 1))
                            }
                        }
                    }
                    .padding()
                }
                
            }.padding()
            HStack {
                Button("Submit") {
                    model.scoreSheet(answers: answerArray)
                    feedback = model.feedback
                    answerGiven = true
                }
                .disabled(answerGiven || itemInfo.questions.isEmpty)
                .padding()
                Button("Close") {
                    model.openSheet = false
                }
                .disabled(!answerGiven && !itemInfo.questions.isEmpty)
            }
        }
        
    }
}

//#Preview {
//    ItemView()
//}
