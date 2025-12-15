//
//  TaskFlowAIApp.swift
//  TaskFlowAI
//
//  Created by yuriy on 15. 12. 25.
//

import SwiftUI

@main
struct TaskFlowAIApp: App {
    private let viewModel: AgentViewModel = {
        let client = LLMAPIClient(
            baseURL: URL(string: "http://localhost:1234/v1/chat/completions")!,
            model: "meta-llama-3.1-8b-instruct",
            apiKey: nil
        )
        let planner = AgentPlanner(client: client)
        let executor = ToolExecutor()
        return AgentViewModel(planner: planner, executor: executor)
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
