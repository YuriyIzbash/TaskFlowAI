//
//  ToolExecutor.swift
//  TaskFlowAI
//
//  Runs local tool implementations deterministically.
//

import Foundation

struct ToolExecutor {
    func run(step: PlanResponse.Step) -> String {
        switch step.tool {
        case .summarize:
            return summarize(text: step.input)
        case .extractChecklist:
            return extractChecklist(text: step.input)
        case .classify:
            return classify(text: step.input)
        }
    }

    private func summarize(text: String) -> String {
        let delimiters: CharacterSet = [".", "!", "?"]
        let sentences = text
            .components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !sentences.isEmpty else { return text }

        let problemSentence = sentences[0]
        let decisionKeywords = ["will ", "agreed", "decided", "next", "by ", "report back", "scheduled"]
        let decisionSentence = sentences.dropFirst().first { sentence in
            let lower = sentence.lowercased()
            return decisionKeywords.contains { lower.contains($0) }
        }

        if let decisionSentence {
            return "\(problemSentence). \(decisionSentence)."
        } else if sentences.count > 1 {
            return sentences.prefix(2).joined(separator: ". ") + "."
        } else {
            return problemSentence + "."
        }
    }

    private func extractChecklist(text: String) -> String {
        let delimiters: CharacterSet = [".", "!", "?"]
        let sentences = text
            .components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var items: [String] = []

        for sentence in sentences {
            let lower = sentence.lowercased()
            let isAction =
                lower.contains(" will ") ||
                lower.hasPrefix("will ") ||
                lower.contains("need to ") ||
                lower.contains("needs to ") ||
                lower.contains("must ") ||
                lower.contains("should ") ||
                lower.contains("agreed to ")

            if !isAction { continue }

            var task = sentence.trimmingCharacters(in: .whitespacesAndNewlines)

            // Normalize by turning "<Who> will <do X>" into "<Who>: <do X>"
            if let range = sentence.range(of: " will ", options: [.caseInsensitive]) {
                let subject = sentence[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let remainder = sentence[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !subject.isEmpty && !remainder.isEmpty {
                    let normalizedSubject = (subject.lowercased() == "we") ? "Team" : subject
                    task = "\(normalizedSubject): \(remainder)"
                }
            } else if let range = sentence.range(of: "agreed to ", options: [.caseInsensitive]) {
                let subject = sentence[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let remainder = sentence[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainder.isEmpty {
                    let normalizedSubject = subject.isEmpty || subject.lowercased() == "we" ? "Team" : subject
                    task = "\(normalizedSubject): \(remainder)"
                }
            }

            task = task.trimmingCharacters(in: CharacterSet(charactersIn: ".!?:;"))

            items.append("- \(task)")
        }

        if items.isEmpty {
            return "No clear action items detected."
        }

        return items.joined(separator: "\n")
    }

    private func classify(text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("meeting") || lower.contains("sync") || lower.contains("recap") {
            if lower.contains("product") || lower.contains("onboarding") || lower.contains("feature") {
                return "product/planning meeting"
            }
            return "meeting"
        }
        if lower.contains("bug") || lower.contains("issue") || lower.contains("error") {
            return "issue triage"
        }
        if lower.contains("plan") || lower.contains("strategy") {
            return "planning"
        }
        if lower.contains("write") || lower.contains("draft") || lower.contains("copy") {
            return "content"
        }
        return "general"
    }
}

