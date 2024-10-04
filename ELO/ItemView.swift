//
//  ItemView.swift
//  ELO
//
//  Created by Niels Taatgen on 27/09/2024.
//

import SwiftUI

struct ItemInfo {
    var title: String?
    var image: NSImage?
    var extraText: String?
    var answerArray: [String] = []
    var answers: [String] = []
    var points: [Double] = []
    var name: String = ""
    
    mutating func read(name: String, loadPath: URL) {
        self.name = name
        self.title = nil
        self.image = nil
        self.extraText = nil
        self.answerArray = []
        self.answers = []
        self.points = []
        let imgUrl = loadPath.appendingPathComponent("images/" + name + ".png")
        if let img = NSImage(contentsOf: imgUrl) {
            self.image = img
        }
        let url = loadPath.appendingPathComponent("items/" + name + ".txt")
//        print("URL = \(url)")
        let text = try? String(contentsOf: url, encoding: String.Encoding.utf8)
        guard text != nil else { return }
        let lines = text!.components(separatedBy: "\n")
        for line in lines {
            let index = line.firstIndex(of: ":")
            if index == nil { continue }
            let indexPlusOne = line.index(after: index!)
            let command = line.prefix(upTo: index!)
//            print("Command is: \(command)")
            let argument = String(line.suffix(from: indexPlusOne)).trimmingCharacters(in: .whitespacesAndNewlines)
//            print("Argument is: \(argument)")
            switch command {
            case "title": self.title = argument
            case "text": self.extraText = argument
            case "question": self.answerArray.append(argument)
            case "answer": self.answers.append(argument)
            case "points": if let value = Double(argument) {
                self.points.append(value)
            }
            default: break
            }
        }
        if answerArray.count != answers.count {
            print("Error in file \(name): different counts for queries and answers")
        }
        if answers.count != points.count {
            print("Error in file \(name): different counts for points and answers")
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
                            Text(itemInfo.answerArray[index])
                            TextField(itemInfo.answerArray[index], text: $answerArray[index])
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
