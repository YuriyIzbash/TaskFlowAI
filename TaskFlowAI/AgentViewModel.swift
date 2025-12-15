//
//  AgentViewModel.swift
//  TaskFlowAI
//
//  Coordinates planning and execution for the UI.
//

import Foundation
import Combine

@MainActor
final class AgentViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var logs: [String] = []
    @Published var isRunning: Bool = false
    @Published var errorMessage: String?

    private let planner: AgentPlanner
    private let executor: ToolExecutor

    init(planner: AgentPlanner, executor: ToolExecutor) {
        self.planner = planner
        self.executor = executor
    }

    func runAgent() {
        guard !isRunning else { return }
        logs.removeAll()
        errorMessage = nil

        isRunning = true

        Task {
            await execute()
        }
    }

    private func appendLog(_ message: String) {
        logs.append(message)
    }

    private func execute() async {
        do {
            let plan = try await planner.plan(for: inputText)
            if plan.steps.isEmpty {
                appendLog("No steps were planned.")
            }

            for step in plan.steps {
                let result = executor.run(step: step)
                let label: String
                switch step.tool {
                case .summarize:
                    label = "Summary"
                case .extractChecklist:
                    label = "Checklist"
                case .classify:
                    label = "Classification"
                }
                appendLog("\(label):\n\(result)")
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            appendLog("Error: \(errorMessage ?? "Unknown error")")
        }

        isRunning = false
    }
}

