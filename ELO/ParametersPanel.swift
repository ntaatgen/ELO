//
//  ParametersPanel.swift
//  ELO
//
//  Created by Niels Taatgen on 20/08/2025.
//

import SwiftUI

struct ParametersPanel: View {
    @ObservedObject var viewModel: ELOViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach($viewModel.draftParameters) { $param in
                HStack {
                    Text(param.name)
                        .frame(width: 120, alignment: .leading)
                    
                    switch param.type {
                    case .int, .double:
                        TextField("", text: Binding(
                            get: { param.value },
                            set: { newValue in
                                switch param.type {
                                case .int:
                                    if newValue.isEmpty || newValue.range(of: "^-?[0-9]*$", options: .regularExpression) != nil {
                                        param.value = newValue
                                    }
                                case .double:
                                    if newValue.isEmpty || newValue.range(of: "^-?[0-9]*\\.?[0-9]*$", options: .regularExpression) != nil {
                                        param.value = newValue
                                    }
                                default:
                                    break
                                }
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                        .multilineTextAlignment(.trailing)
                        
                    case .bool:
                        Toggle("", isOn: Binding(
                            get: { Bool(param.value) ?? false },
                            set: { param.value = $0 ? "true" : "false" }
                        ))
                        .toggleStyle(.checkbox)
                        .frame(width: 120, alignment: .leading)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    viewModel.cancelChanges()
                    dismiss()
                }
                Button("Confirm") {
                    viewModel.confirmChanges()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 340)
        .onAppear {
            viewModel.startEditing()
        }
    }
}
