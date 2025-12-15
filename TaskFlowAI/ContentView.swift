//
//  ContentView.swift
//  TaskFlowAI
//
//  Created by yuriy on 15. 12. 25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AgentViewModel

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Task")
                    .font(.headline)
                TextEditor(text: $viewModel.inputText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
            }

            Button {
                viewModel.runAgent()
            } label: {
                HStack {
                    if viewModel.isRunning {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(viewModel.isRunning ? "Processing..." : "Process with AI")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isRunning || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            VStack(alignment: .leading, spacing: 8) {
                Text("Summarized Tasks")
                    .font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(viewModel.logs.enumerated()), id: \.offset) { item in
                            Text(item.element)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView(
        viewModel: AgentViewModel(
            planner: AgentPlanner(
                client: LLMAPIClient(
                    baseURL: URL(string: "https://api.openai.com/v1/chat/completions")!,
                    model: "gpt-4o-mini",
                    apiKey: "demo-key"
                )
            ),
            executor: ToolExecutor()
        )
    )
}
