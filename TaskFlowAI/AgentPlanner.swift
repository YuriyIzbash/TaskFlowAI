//
//  AgentPlanner.swift
//  TaskFlowAI
//
//  Responsible for calling the LLM with a strict system prompt and decoding the plan.
//

import Foundation

struct PlanResponse: Codable {
    struct Step: Codable {
        let tool: Tool
        let input: String
    }
    let steps: [Step]
}

enum Tool: String, Codable, CaseIterable {
    case summarize
    case extractChecklist
    case classify
}

enum AgentError: LocalizedError {
    case emptyInput
    case invalidPlan(String)
    case network(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please provide a task for the agent."
        case .invalidPlan(let reason):
            return "The plan was invalid: \(reason)"
        case .network(let error):
            return error.localizedDescription
        }
    }
}

struct AgentPlanner {
    private let client: LLMAPIClient
    
    init(client: LLMAPIClient) {
        self.client = client
    }
    
    func plan(for userInput: String) async throws -> PlanResponse {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AgentError.emptyInput
        }
        
        do {
            let raw = try await client.send(systemPrompt: systemPrompt, userPrompt: userInput)
            let plan = try JSONDecoder().decode(PlanResponse.self, from: Data(raw.utf8))
            return plan
        } catch let error as DecodingError {
            throw AgentError.invalidPlan("Failed to decode JSON: \(error.localizedDescription)")
        } catch let error as AgentError {
            throw error
        } catch {
            throw AgentError.network(error)
        }
    }
}

let systemPrompt = """
You are an automation planner.
You must respond with ONE JSON object only. No explanations, no extra keys, no comments.

Allowed tools (exact names):
- summarize(text)
- extractChecklist(text)
- classify(text)

Response schema (strict):
{
  "steps": [
    {
      "tool": "summarize",
      "input": "string"
    }
  ]
}

Rules:
- "tool" must be one of: "summarize", "extractChecklist", "classify".
- "input" must be the exact text the tool should process.
- Use the minimum number of steps needed.
- For meeting-like recap text, usually plan three steps: summarize, extractChecklist, classify, all on the full text.
- Do not add any keys other than "steps", "tool", and "input".
"""

