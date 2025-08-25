//
//  AIWorker.swift
//  LinkedInCompanionApp
//
//  Created by Gnanendra Naidu N on 20/08/25.
//
// AIWorker.swift
import Foundation

class AIWorker {
    static let shared = AIWorker()

    func processRequests() {
        let defaults = UserDefaults(suiteName: "group.com.einstein.common")

        if let request = defaults?.dictionary(forKey: "AIRequest") as? [String: String],
           let link = request["link"],
           let tone = request["tone"] {

            let token = defaults?.string(forKey: "userEmail") ?? ""

            let commentGenerator = LinkedInCommentGenerator(authToken: token)
            commentGenerator.generateAIComment(link: link, tone: tone) { comment in
                let cleaned = comment ?? "⚠️ Error from AI."
                defaults?.set(cleaned, forKey: "AIResponse")
                //defaults?.removeObject(forKey: "AIRequest") // ✅ clear request after processing
                defaults?.synchronize()
            }
        }
    }
}
