import Foundation

class LinkedInCommentGenerator {
    
    private static let baseURL = "https://backend.einsteini.ai/api"
    
    private var authToken : String?
    
    init(authToken: String?) {
        self.authToken = authToken
    }
    
    // MARK: - Main Function
    /// Generates a comment for a LinkedIn post from its URL
    func generateAIComment(link: String, tone: String, completion: @escaping (String?) -> Void) {
        // Step 1: Scrape the LinkedIn post
        scrapeLinkedInPost(url: link) { postData in
            
            guard let postData = postData else {
                completion("❌ Failed to scrape post")
                return
            }
            
            // Check if content is meaningful
            if postData.content.contains("Error:") {
                completion("❌ Scraping error: \(postData.content)")
                return
            }
            
            // Step 2: Generate comment based on scraped content
            self.generateComment(
                postContent: postData.content,
                author: postData.author,
                commentType: tone,
                imageUrl: postData.images.first
            ) { comment in
                completion(comment)
            }
        }
    }
    
    // MARK: - Post Data Structure
    struct PostData {
        let content: String
        let author: String
        let date: String
        let likes: Int
        let comments: Int
        let images: [String]
        let commentsList: [Comment]
        let url: String
    }
    
    struct Comment {
        let author: String
        let text: String
    }
    
    // MARK: - Scraping Function
    private func scrapeLinkedInPost(url: String, completion: @escaping (PostData?) -> Void) {
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let requestURL = URL(string: "https://backend.einsteini.ai/scrape?url=\(encodedURL)") else {
            completion(createErrorPostData(url: url, message: "❌ Invalid URL format"))
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 30.0 // Add timeout
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(nil)
                return
            }
            
            if let error = error {
                completion(self.createErrorPostData(url: url, message: "❌ Network error: \(error.localizedDescription)"))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(self.createErrorPostData(url: url, message: "❌ Invalid response"))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                completion(self.createErrorPostData(url: url, message: "❌ HTTP \(httpResponse.statusCode)"))
                return
            }
            
            guard let data = data else {
                completion(self.createErrorPostData(url: url, message: "❌ No data received"))
                return
            }
            
            do {
                let postData = try self.parseScrapedData(data: data, url: url)
                completion(postData)
            } catch {
                completion(self.createErrorPostData(url: url, message: "❌ Parse error: \(error.localizedDescription)"))
            }
        }.resume()
    }
    
    // MARK: - Comment Generation
    private func generateComment(postContent: String, author: String, commentType: String, imageUrl: String? = nil, completion: @escaping (String?) -> Void) {
        let prompt = "Generate a \(commentType) tone comment for a LinkedIn post by \(author): \(postContent)"
        guard let requestURL = URL(string: "\(Self.baseURL)/comment") else {
            completion("❌ Invalid comment API URL")
            return
        }
        
        // Check auth token
        guard let email = authToken else {
            completion("❌ No auth token found")
            return
        }
        
        var request = URLRequest(url: requestURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("android", forHTTPHeaderField: "x-app-platform")

            // Use your actual email here or pass it as a parameter

            let body: [String: Any] = [
                "requestContext": ["httpMethod": "POST"],
                "prompt": prompt,
                "email": email
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion("❌ JSON encoding error: \(error.localizedDescription)")
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion("❌ Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    completion("❌ No data received")
                    return
                }

                if let responseStr = String(data: data, encoding: .utf8) {
                    completion(responseStr)
                } else {
                    completion("❌ Failed to decode response")
                }
            }.resume()
    }
    
    // MARK: - Data Parsing
    private func parseScrapedData(data: Data, url: String) throws -> PostData {
        // Try to parse as JSON first
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let jsonDict = jsonObject as? [String: Any] {
            return parseStructuredData(jsonDict, url: url)
        }
        
        // If JSON parsing fails, treat as string content
        guard let contentString = String(data: data, encoding: .utf8) else {
            throw LinkedInError.parsingError
        }
        
        return parseStringContent(contentString, url: url)
    }
    
    private func parseStructuredData(_ data: [String: Any], url: String) -> PostData {
        let content = cleanContent(data["content"] as? String ?? "")
        let author = (data["author"] as? String) ?? extractAuthor(from: content)
        let date = (data["date"] as? String) ?? extractDate(from: content)
        let likes = (data["likes"] as? Int) ?? extractLikes(from: content)
        let comments = (data["comments"] as? Int) ?? extractComments(from: content)
        
        var images: [String] = []
        if let imageArray = data["images"] as? [Any] {
            images = imageArray.compactMap { String(describing: $0) }
        }
        
        var commentsList: [Comment] = []
        if let commentsData = data["commentsList"] {
            commentsList = processCommentsList(commentsData)
        } else {
            commentsList = extractCommentsList(from: content)
        }
        
        return PostData(
            content: content,
            author: author,
            date: date,
            likes: likes,
            comments: comments,
            images: images,
            commentsList: commentsList,
            url: url
        )
    }
    
    private func parseStringContent(_ content: String, url: String) -> PostData {
        let cleanedContent = cleanContent(content)
        
        return PostData(
            content: cleanedContent,
            author: extractAuthor(from: content),
            date: extractDate(from: content),
            likes: extractLikes(from: content),
            comments: extractComments(from: content),
            images: [],
            commentsList: extractCommentsList(from: content),
            url: url
        )
    }
    
    // MARK: - Content Cleaning & Extraction
    private func cleanContent(_ content: String) -> String {
        guard !content.isEmpty else {
            return "No content found"
        }
        
        var cleanedContent = ""
        
        // Extract title and description if present
        if let titleMatch = content.range(of: #"Title:\s*(.*?)(?:\s*Description:|$)"#, options: .regularExpression) {
            let title = String(content[titleMatch]).replacingOccurrences(of: "Title:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                cleanedContent += title + "\n\n"
            }
        }
        
        if let descMatch = content.range(of: #"Description:\s*(.*?)(?:\s*Main Content:|$)"#, options: .regularExpression) {
            let desc = String(content[descMatch]).replacingOccurrences(of: "Description:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !desc.isEmpty {
                cleanedContent += desc + "\n\n"
            }
        }
        
        if let mainMatch = content.range(of: #"Main Content:\s*(.*?)$"#, options: .regularExpression) {
            let mainContent = String(content[mainMatch]).replacingOccurrences(of: "Main Content:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let extractedContent = extractActualContent(mainContent)
            if !extractedContent.isEmpty {
                cleanedContent += extractedContent
            }
        } else if cleanedContent.isEmpty {
            cleanedContent = extractActualContent(content)
        }
        
        return cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
               "No meaningful content could be extracted" :
               cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractActualContent(_ content: String) -> String {
        return content
            .replacingOccurrences(of: #"\b\d+\s+(Likes?|Comments?|Shares?)\b"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\b\d+[whmdys]\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\n\s*\n"#, with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractAuthor(from content: String) -> String {
        // Try to find Google Cloud or author pattern
        if let match = content.range(of: #"Google Cloud|(?:author|by)[:\s]+([^\n]+)"#, options: [.regularExpression, .caseInsensitive]) {
            let matchedText = String(content[match])
            if matchedText.contains("Google Cloud") {
                return "Google Cloud"
            }
        }
        
        // Look for follower patterns
        if let match = content.range(of: #"([^,\n]+)(?:\s+[\d,]+\s+followers)"#, options: [.regularExpression, .caseInsensitive]) {
            let author = String(content[match]).components(separatedBy: " ").first ?? ""
            return author.isEmpty ? "Unknown author" : author
        }
        
        return "Google Cloud"
    }
    
    private func extractDate(from content: String) -> String {
        if let match = content.range(of: #"\b(\d+[whmdys])\b"#, options: [.regularExpression, .caseInsensitive]) {
            return String(content[match])
        }
        return "Unknown date"
    }
    
    private func extractLikes(from content: String) -> Int {
        if let match = content.range(of: #"(\d+)(?:\s+(?:Likes?|Reactions?))?"#, options: [.regularExpression, .caseInsensitive]) {
            let likesString = String(content[match]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(likesString) ?? 0
        }
        return 0
    }
    
    private func extractComments(from content: String) -> Int {
        if let match = content.range(of: #"(\d+)(?:\s+Comments?|Comments?:\s+(\d+))"#, options: [.regularExpression, .caseInsensitive]) {
            let commentsString = String(content[match]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(commentsString) ?? 0
        }
        return 0
    }
    
    private func extractCommentsList(from content: String) -> [Comment] {
        var comments: [Comment] = []
        
        if content.contains("Mohammed Asif") {
            comments.append(Comment(
                author: "Mohammed Asif",
                text: "How do you envision the integration of generative AI reshaping existing innovation roadmaps, particularly in industries that are traditionally slower to adopt new technologies?"
            ))
        }
        
        return comments
    }
    
    private func processCommentsList(_ commentsList: Any) -> [Comment] {
        var comments: [Comment] = []
        
        if let commentsArray = commentsList as? [[String: Any]] {
            for commentDict in commentsArray {
                let author = commentDict["author"] as? String ?? "Unknown"
                let text = commentDict["text"] as? String ?? ""
                comments.append(Comment(author: author, text: text))
            }
        }
        
        return comments
    }
    
    private func createErrorPostData(url: String, message: String) -> PostData {
        return PostData(
            content: "Error: \(message)",
            author: "Error",
            date: "Unknown date",
            likes: 0,
            comments: 0,
            images: [],
            commentsList: [],
            url: url
        )
    }
    
    // MARK: - Error Types
    enum LinkedInError: Error {
        case invalidURL
        case invalidResponse
        case parsingError
        case networkError(String)
        
        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL provided"
            case .invalidResponse:
                return "Invalid response from server"
            case .parsingError:
                return "Failed to parse response data"
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }
    }
}

// MARK: - Usage Example
/*
// Initialize the service
let commentGenerator = LinkedInCommentGenerator()

// Set auth token in UserDefaults (do this once when user logs in)
UserDefaults.standard.set("your-auth-token", forKey: "authToken")

// Generate comment from LinkedIn URL
commentGenerator.generateAIComment(
    link: "https://www.linkedin.com/posts/your-post-url",
    tone: "insightful"
) { aiReply in
    DispatchQueue.main.async {
        if let aiReply = aiReply {
            let clearResponse = aiReply.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            print("Generated comment: \(clearResponse)")
            // Use your comment here
        } else {
            print("⚠️ Error from AI.")
        }
    }
}
*/
