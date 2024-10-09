//
//  ItemView.swift
//  ELO
//
//  Created by Niels Taatgen on 27/09/2024.
//

import SwiftUI


enum Question {
    case text(prompt: String, answers: [String], points: Double)
    case multipleChoice(prompt: String, options: [String], correct: Int, points: Double)
    case realNumber(prompt: String, answer: Double, points: Double)
    case intNumber(prompt: String, answer: Int, points: Double)
}

struct ItemInfo {
    var title: String?
    var image: NSImage?
    var extraText: String?
    var questions: [Question] = []
//    var answerArray: [String] = []
//    var answers: [String] = []
//    var points: [Double] = []
    var name: String = ""
    
    func splitLine(line: String) -> (String, String)? {
        let index = line.firstIndex(of: ":")
        if index == nil { return nil }
        let indexPlusOne = line.index(after: index!)
        print(String(line.prefix(upTo: index!)), line.suffix(from: indexPlusOne).trimmingCharacters(in: .whitespacesAndNewlines))
        return (String(line.prefix(upTo: index!)), line.suffix(from: indexPlusOne).trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    mutating func parseTextQuestion(argument: String, lines: [String], index: Int) -> (Question, Int) {
        var answers: [String] = []
        var points = 1.0
        var i = index
        var done = false
        while i < lines.count && !done {
            if let (command, argument) = splitLine(line: lines[i]) {
                switch command {
                case "answer","answers": answers = argument.components(separatedBy: ",")
                case "points": if let x = Double(argument) {
                    points = x
                }
                default:
                    i -= 1
                    done = true
                }
                i += 1
            }
        }
        return((Question.text(prompt: argument, answers: answers, points: points), i-1))
    }
    
    mutating func parseRealQuestion(argument: String, lines: [String], index: Int) -> (Question, Int) {
        var answer: Double = 0
        var points = 1.0
        var i = index
        var done = false
        while i < lines.count && !done {
            if let (command, argument) = splitLine(line: lines[i]) {
                switch command {
                case "answer": if let x = Double(argument) {
                    answer = x
                }
                case "points": if let x = Double(argument) {
                    points = x
                }
                default:
                    i -= 1
                    done = true
                }
                i += 1
            }
        }
        return((Question.realNumber(prompt: argument, answer: answer, points: points), i-1))
    }

    mutating func parseIntQuestion(argument: String, lines: [String], index: Int) -> (Question, Int) {
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
                i += 1
            }
        }
        return((Question.intNumber(prompt: argument, answer: answer, points: points), i-1))
    }
    
    mutating func parseMCQuestion(argument: String, lines: [String], index: Int) -> (Question, Int) {
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
                i += 1
            }
        }
        return ((Question.multipleChoice(prompt: argument, options: options, correct: answer, points: points), i-1))
    }

    
    init(name: String, loadPath: URL) {
        self.name = name
        let imgUrl = loadPath.appendingPathComponent("images/" + name + ".png")
        if let img = NSImage(contentsOf: imgUrl) {
            self.image = img
        }
        let url = loadPath.appendingPathComponent("items/" + name + ".txt")
//        print("URL = \(url)")
        let text = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        guard text != nil else { return }
        let lines = text!.components(separatedBy: "\n")
        var lineIndex = 0
        while lineIndex < lines.count {
             if let (command, argument) = splitLine(line: lines[lineIndex]) {
                 print("Command \(command)")
                switch command {
                case "title": self.title = argument
                case "text": self.extraText = argument
                case "question", "text-question": let (question, newIndex) = parseTextQuestion(argument: argument, lines: lines, index: lineIndex + 1)
                    lineIndex = newIndex
                    questions.append(question)
                case "real-question": let (question, newIndex) = parseRealQuestion(argument: argument, lines: lines, index: lineIndex + 1)
                    lineIndex = newIndex
                    questions.append(question)
                case "int-question": let (question, newIndex) = parseIntQuestion(argument: argument, lines: lines, index: lineIndex + 1)
                    lineIndex = newIndex
                    questions.append(question)
                case "mc-question": let (question, newIndex) = parseMCQuestion(argument: argument, lines: lines, index: lineIndex + 1)
                    lineIndex = newIndex
                    questions.append(question)
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
    @State var answerArray = [String](repeating: "", count: 10)
    var body: some View {
        VStack {
            if itemInfo.title != nil {
                Text(itemInfo.title!)
                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
            }
            if itemInfo.image == nil {
                Text("No Image")
            } else {
                Image(nsImage: itemInfo.image!)
            }
            if itemInfo.extraText != nil {
                Text(itemInfo.extraText!)
            }
            VStack {
                if groupsize > 0 {
                    ForEach(0 ..< groupsize) { index in
                        HStack {
                            switch itemInfo.questions[index] {
                            case .text(let prompt, _, _), .realNumber(let prompt, _, _),.intNumber(let prompt, _, _):
                                    Text(prompt)
                                    TextField("antwoord", text: $answerArray[index])
                            case .multipleChoice(prompt: let prompt, options: let options, _, _):
//                                selectedRB = options[0]
                                VStack {
                                    Picker(selection: $answerArray[index], label: Text(prompt)) {
                                        ForEach(options, id:\.self) {
                                            Text($0)
                                        }
                                    }.pickerStyle(RadioGroupPickerStyle())
                                }
                            }

                        }
                        .padding()
                    }
                }
            }.padding()
            
            Button("Submit") {
                model.openSheet = false
                model.scoreSheet(answers: answerArray)
            }
            .padding()
        }
        
    }
}

//#Preview {
//    ItemView()
//}
