import Foundation
import UIKit

class LinkedInCommentGenerator {
    
    private static let baseURL = "https://backend.einsteini.ai/api"
    private static let scrapeBase = "https://backend.einsteini.ai"
    
    private var authToken : String?
    
    init(authToken: String?) {
        self.authToken = authToken
        
    }
    
    
    
    func generateComment(
        url: String,
        tone: String,
        includeEmoji: Bool,
        emojiText: String?,
        includeHashtag: Bool,
        hashtagText: String?,
        language: String? = "English",
        completion: @escaping (String?) -> Void
    ) {
        performScrape(for: url) { scraped in
            let postText = scraped?.content ?? ""
            let author = scraped?.author ?? "Unknown author"
            let prompt = self.buildPrompt(
                tone: tone,
                postText: postText,
                author: author,
                language: language ?? "English",
                includeEmoji: includeEmoji,
                emojiText: emojiText,
                includeHashtag: includeHashtag,
                hashtagText: hashtagText
            )
            self.callCommentAPI(prompt: prompt, email: self.authToken ?? "", completion: completion)        }
    }


    private func performScrape(for urlString: String, completion: @escaping ((content: String, author: String)?) -> Void) {
        // Construct query properly
        guard var components = URLComponents(string: "https://backend.einsteini.ai/scrape") else {
            completion(nil)
            return
        }

        components.queryItems = [
            URLQueryItem(name: "url", value: urlString)
        ]

        guard let requestURL = components.url else {
            completion(nil)
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 30.0

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let data = data else {
                print("⚠️ No data returned")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let content = (json["content"] as? String) ??
                                  (json["text"] as? String) ??
                                  String(data: data, encoding: .utf8) ?? ""
                    let author = (json["author"] as? String) ?? "Unknown author"
                    completion((content: content, author: author))
                } else {
                    let asString = String(data: data, encoding: .utf8) ?? ""
                    completion((content: asString, author: "Unknown author"))
                }
            } catch {
                print("⚠️ JSON parse error:", error.localizedDescription)
                let asString = String(data: data, encoding: .utf8) ?? ""
                completion((content: asString, author: "Unknown author"))
            }
        }.resume()
    }

    
    
    // MARK: - Helper function for showing alerts
    private func showAlert(on viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }

    private func callCommentAPI(prompt: String, email: String, completion: @escaping (String?) -> Void) {
        // Build the comment API URL safely
        let commentEndpoint = Self.baseURL.hasSuffix("/") ? "comment" : "/comment"
        guard let url = URL(string: Self.baseURL + commentEndpoint) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("android", forHTTPHeaderField: "x-app-platform")

        let body: [String: Any] = [
            
            "email": self.authToken ?? "gnanendranaidun101@gmail.com",
            "prompt": prompt,
            
            "requestContext": ["httpMethod": "POST"]
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                completion(nil)
                return
            }
            guard let data = data else {
                completion(nil)
                return
            }
            let respStr = String(data: data, encoding: .utf8)
            completion(respStr)
        }.resume()
    }

    private func buildPrompt(
        tone: String,
        postText: String,
        author: String,
        language: String,
        includeEmoji: Bool,
        emojiText: String?,
        includeHashtag: Bool,
        hashtagText: String?
    ) -> String {
        let t = tone
        var basePrompt: String
        switch t {
        case "applaud", " applaud", "Applaud", "Applaud ", " Applaud", " Applaud ":
            basePrompt = """
            Write a short, positive, and genuine comment in \(language) that applauds or congratulates the author for their post. Do not mention any products, companies, or ask any questions. Just express appreciation or applause in a friendly, human way.

            Post: \(postText)
            Author: \(author)
            """
        case "agree", " agree", "Agree", " Agree", " Agree ", "Agree ":
            basePrompt = """
            Generate a short (max 10 words) LinkedIn comment in \(language) that expresses agreement with a post by \(author). Avoid using quotation marks, emojis, or hashtags.

            Guidelines:
            1. Make the tone friendly and conversational.
            2. Acknowledge the main message of the post naturally.
            3. Keep it simple, relatable, and human.
            4. Avoid repeating the exact words of the post or being overly generic.

            Post: \(postText)
            Author: \(author)
            """
        case "fun", " fun", "Fun", " Fun", "Fun ", " Fun ":
            basePrompt = """
            Generate an engaging, genuine, and human-like fun comment in \(language) for this LinkedIn post:

            Post: \(postText)
            Author: \(author)

            Reply to this LinkedIn post with a comment that contains a touch of humor or amusement, while still being respectful and relevant.

            The comment should:
            - Feel human and simple.
            - Have a tinge of humor.
            - Not use quotes.
            - Be a very humorous person, like people can't help but laugh at your jokes.
            - Jokes must align with societal norms and LinkedIn terms and conditions.
            - Analyze the description and image (if provided) to relate to a similar experience or common situation.
            - Use varied language and structure to avoid repetitive phrasing.
            - Don't always start with "Wow".
            """
        case "perspective", " perspective ", " perspective", "Perspective", "Perspective ", " Perspective", " Perspective ":
            basePrompt = """
            Read the post by \(author) titled "\(postText)". Generate a thoughtful and unique comment in \(language) that offers a fresh perspective or expands on the author's ideas, ensuring it feels natural and conversational.

            Guidelines:
            1. Start by acknowledging or appreciating the author's viewpoint in a friendly, non-repetitive way.
            2. Offer a new perspective or build on the ideas presented without contradicting the author.
            3. Keep the tone positive and encouraging.
            4. Keep the language simple, friendly, and human-like.
            5. Avoid using any quotes, hashtags, or emojis.
            6. Keep the reply short, around 20-30 words.
            7. Make sure every comment generated feels personal and unique.

            Post: \(postText)
            Author: \(author)
            """
        case "question", " question", "Question", " Question", "Question ", " Question ":
            basePrompt = """
            Generate a unique, thoughtful, human-like question in \(language) for a LinkedIn post by \(author). The question should express genuine curiosity and encourage further discussion in a natural and professional manner.

            Guidelines:
            1. Start by acknowledging the author's post in a way that feels personal and tailored.
            2. Ask a specific, meaningful question that relates directly to the content of the post.
            3. Avoid generic phrases like "Great post" or "Nice work."
            4. Keep the tone conversational, warm, and professional.
            5. Ensure the language is clear and concise, limiting the question to under 30 words.
            6. No quotes, emojis, or hashtags.

            Post: \(postText)
            Author: \(author)
            """
        default:
            basePrompt = "Generate a short, friendly LinkedIn comment in \(language) for the post by \(author): \(postText)"
        }

        var additions = ""
        if includeEmoji{
            additions += "\n\nWhen producing the comment, Use Suitable emojis"
        }
        else{
            additions += "\n\nWhen producing the comment, Strictly Do not use any emojis"
        }
        if includeHashtag{
            additions += "\n\nWhen producing the comment, Use Suitable hashtags"
        }
        else{
            additions += "\n\nWhen producing the comment, Strictly Do not use any hashtags"
        }

        return basePrompt + additions
    }

}
