//  ContentView.swift
//  LinkedInCompanionApp
//
//  Created by Gnanendra Naidu N on 19/06/25.

import SwiftUI
import AVFoundation
import Speech
import UserNotifications
import GoogleSignInSwift
import GoogleSignIn
import AuthenticationServices
import StoreKit
import Combine
import Foundation



// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()
            VStack(spacing: 16) {
                Image("Einsteini Splash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 150)
            }
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var subscriptionStatus: String = ""
    @Published var remainingComments: Int = 0
    @Published var enableNotifications: Bool = true {
           didSet { updateNotifications() }
       }
    @Published var darkMode: Bool = false {
           didSet { updateAppearance() }
       }

       // MARK: - Dark Mode
       private func updateAppearance() {
           guard let scene = UIApplication.shared.connectedScenes
                   .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
           else { return }
           
           for window in scene.windows {
               window.overrideUserInterfaceStyle = darkMode ? .dark : .light
           }

           DualDefaults.set(darkMode, forKey: "darkMode")
           print("Dark Mode \(darkMode ? "enabled" : "disabled")")
       }

       // MARK: - Notifications
       private func updateNotifications() {
           DualDefaults.set(enableNotifications, forKey: "enableNotifications")

           if enableNotifications {
               // Request permission if needed
               UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                   if granted { print("Notifications enabled ✅") }
                   else { print("Notifications permission denied ❌") }
               }
           } else {
               // Optional: remove pending notifications
               UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
               print("Notifications disabled ❌")
           }
       }

       // MARK: - Load saved settings
       func loadSettings() {
           darkMode = DualDefaults.bool(forKey: "darkMode")
           enableNotifications = DualDefaults.bool(forKey: "enableNotifications")
       }


    init() {
        isLoggedIn = DualDefaults.string(forKey: "loggedInEmail") != nil
        subscriptionStatus = DualDefaults.string(forKey: "subscriptionStatus") ?? "Unknown"
        remainingComments = DualDefaults.integer(forKey: "remainingComments")
    }

    func logIn(email: String, name : String) {
        DualDefaults.set(name, forKey: "User_name")
        DualDefaults.set(email, forKey: "loggedInEmail")
        isLoggedIn = true
    }

    func logOut() {
        ["loggedInEmail", "subscriptionStatus", "remainingComments"].forEach {
                    DualDefaults.remove(forKey: $0)
                }
        subscriptionStatus = "Unknown"
        remainingComments = 0
        isLoggedIn = false
    }

    var loggedInEmail: String? {
        DualDefaults.string(forKey: "loggedInEmail")
    }
    var Username: String?{
        DualDefaults.string(forKey: "User_name")
    }

    func updateSubscriptionStatus(_ status: String) {
        subscriptionStatus = status
        DualDefaults.set(status, forKey: "subscriptionStatus")
    }

    func updateRemainingComments(_ count: Int) {
        remainingComments = count
        DualDefaults.set(count, forKey: "remainingComments")
    }
}


struct VerifyResponse: Codable {
    let success: Bool
    let msg: String?
    let error: String?
    let user: UserProfile?
}

struct UserProfile: Codable {
    let customerId: String?
    let firstName: String?
    let email: String?
}

class AuthService: ObservableObject{
    let baseURL = "https://backend.einsteini.ai/"
    @EnvironmentObject var appState: AppState
    
    func verifyAccount(email: String, token: String) async -> (success: Bool, message: String) {
        do {
            guard let url = URL(string: "\(baseURL)api/verify-account") else {
                return (false, "Invalid URL")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "email": email,
                "token": token
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return (false, "Invalid response")
            }
            
            let decoder = JSONDecoder()
            let verifyResponse = try decoder.decode(VerifyResponse.self, from: data)
            
            if httpResponse.statusCode == 200, verifyResponse.success {
                if let profile = verifyResponse.user {
                    let name = profile.firstName ?? "User"
                    let email = profile.email ?? email
                    
                    // ✅ Call app state log in
                    appState.logIn(email: email, name: name)
                    
                    // ✅ Persist session in UserDefaults
                    let defaults = UserDefaults.standard
                    if let customerId = profile.customerId {
                        defaults.set(customerId, forKey: "user_id")
                    }
                    defaults.set(name, forKey: "user_name")
                    defaults.set(email, forKey: "user_email")
                    defaults.set(true, forKey: "user_logged_in")
                }
                
                return (true, verifyResponse.msg ?? "Account verified successfully")
            } else {
                let errorMsg = verifyResponse.error ?? verifyResponse.msg ?? "Verification failed"
                return (false, errorMsg)
            }
            
        } catch {
            return (false, "Verification failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Keyboard Setup View
struct KeyboardSetupView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @State private var hasConfirmed = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "keyboard")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.purple)

            Text("Enable einsteini.ai Keyboard")
                .font(.title).bold()
                .multilineTextAlignment(.center)

            Text("To use our AI-powered keyboard, please add it and allow Full Access:")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Steps:")
                    .font(.headline)

                Text("""
                1. Open Settings  
                2. Go to General → Keyboard → Keyboards  
                3. Tap “Add New Keyboard…”, select “einsteini.ai”  
                4. Back in Keyboards list, tap “einsteini.ai” → Allow Full Access  
                """)
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)

            Button(action: {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)  // Frame inside label
                    .background(Color.purple)
                    .cornerRadius(22)
            }


            Toggle("I have enabled the keyboard", isOn: $hasConfirmed)
                .padding(.top, 12)

            Button(action: {
                requestPermissions()
                hasCompletedSetup = true
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(hasConfirmed ? Color.green : Color.gray)
                    .cornerRadius(22)
            }
            .disabled(!hasConfirmed)
            .padding(.top)
 // <-- Full frame tappable

            Spacer()
        }
        .padding()
    }

    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

// ---------------------------
// HomeView (no NavigationView here)
// ---------------------------
struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView{
            VStack(spacing: 24) {
                Text("einsteini.ai")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                if let user_name = appState.Username {
                    Text("👋 Welcome back \(user_name)")
                        .font(.title2)
                } else {
                    Text("👋 Welcome back to")
                        .font(.title2)
                }
                
                
                
                if let email = appState.loggedInEmail {
                    Text("Logged in as: \(email)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text("💬 Remaining Comments: \(appState.remainingComments)")
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                Divider().padding(.horizontal)
            }
            .padding()
            .onAppear(){
                self.loadSubscriptionStatus()
            }
            // navigationTitle will be set by the NavigationView in MainView
        }
    }
    func loadSubscriptionStatus() {
        guard let email = appState.loggedInEmail else { return }

        ApiService.shared.getSubscriptionType(email: email) { status, error in
            if let status = status {
                DispatchQueue.main.async {
                    appState.updateSubscriptionStatus(status)
                }
            }
        }

        ApiService.shared.getRemainingComments(email: email) { count in
            if let count = count {
                DispatchQueue.main.async {
                    appState.updateRemainingComments(count)
                }
            }
        }
    }


}

// ---------------------------
// AIAssistantView (REPLACED)
// ---------------------------
struct AIAssistantView: View {
    enum Tab: String, CaseIterable, Identifiable {
        //case analyse = "Analyse Post"
        case create = "Create Post"
        //case about = "About Me"
        var id: String { rawValue }
    }
    
    @State private var selectedTab: Tab = .create
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("AI Tabs", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            switch selectedTab {
//            case .analyse:
//                AnalysePostView()
            case .create:
                CreatePostView()
//            case .about:
//                AboutMeView()
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

// MARK: - Shared UI Helpers
private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct OutputArea: View {
    let text: String
    let isLoading: Bool
    let error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Generating...")
                }
            }
            if let error = error, !error.isEmpty {
                Text(error)
                    .foregroundColor(.red)
            }
            if !text.isEmpty {
                TextEditor(text: .constant(text))
                    .frame(minHeight: 140)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Enums
private enum AITone: String, CaseIterable, Identifiable {
    case professional = "Professional"
    case friendly = "Friendly"
    case bold = "Bold"
    case neutral = "Neutral"
    case humorous = "Humorous"
    var id: String { rawValue }
}



private enum PostLength: String, CaseIterable, Identifiable {
    case short = "Short"
    case medium = "Medium"
    case long = "Long"
    var id: String { rawValue }
}

private enum SummaryType: String, CaseIterable, Identifiable {
    case concise = "Concise"
    case brief = "Brief"
    case detailed = "Detailed"
    var id: String { rawValue }
}

private enum Language: String, CaseIterable, Identifiable {
    case english = "English"
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case hindi = "Hindi"
    case japanese = "Japanese"
    var id: String { rawValue }
}

// MARK: - Analyse Post
private final class AnalysePostViewModel: ObservableObject {
    @Published var url: String = ""
    @Published var isValidURL: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var analysisError: String? = nil
    @Published var postPreview: String = "" // content preview
    
    // Action state
    enum Action { case none, comment, translate, summarise }
    @Published var selectedAction: Action = .none
    
    // Inputs
    @Published var commentOptions: String = ""
    @Published var tone: AITone = .professional
    @Published var selectedLanguage: Language = .english
    @Published var summaryType: SummaryType = .concise
    
    // Output
    @Published var isGenerating: Bool = false
    @Published var generationError: String? = nil
    @Published var output: String = ""
    
    // URL validation
    func validateURL(_ text: String) {
        url = text
        let pattern = #"^https?:\/\/(www\.)?linkedin\.com\/.*$"#
        isValidURL = text.range(of: pattern, options: .regularExpression) != nil
    }
    
    @MainActor
    func analyze() async {
        guard isValidURL else { return }
        isAnalyzing = true
        analysisError = nil
        postPreview = ""
        selectedAction = .none
        output = ""
        generationError = nil
        
        // Use LinkedInCommentGenerator scraping to fetch content preview
        let email = DualDefaults.string(forKey: "loggedInEmail") ?? UserDefaults.standard.string(forKey: "userEmail")
        let generator = LinkedInCommentGenerator(authToken: email)
        await withCheckedContinuation { continuation in
            generator.scrapeLinkedInPost(url: url) { postData in
                DispatchQueue.main.async {
                    self.isAnalyzing = false
                    if let data = postData, !data.content.lowercased().hasPrefix("error:") {
                        //
                        var t = data.content
                        
                        // 1. Remove HTML tags
                        t = t.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                        
                        // 2. Remove control characters
                        t = String(t.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) })
                        
                        // 3. Remove common LinkedIn UI tokens
                        let tokens = [
                            "Report this post", "Report this comment",
                            "Like", "Comment", "Share", "Copy",
                            "View Profile", "Connect", "See more comments",
                            "To view or add a comment, sign in",
                            "Reactions", "followers", "Posts", "Articles","\nShow less","Show more\n\"",
                        ]
                        
                        for token in tokens {
                            t = t.replacingOccurrences(of: token, with: " ", options: .caseInsensitive)
                        }
                        t = t.replacingOccurrences(of: "\\s+\n", with: " ")
                        
                        // 4. Collapse whitespace
                        t = t.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        //
                        self.postPreview = t.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                    } else {
                        self.analysisError = "Failed to analyze post. Please check the link and try again."
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    func generateForSelectedAction() async {
        guard !postPreview.isEmpty else {
            generationError = "Please analyze a post first."
            return
        }
        isGenerating = true
        generationError = nil
        output = ""
        
        // Call backend endpoints via LinkedInCommentGenerator
        do {
            switch selectedAction {
            case .comment:
                output = try await generateComment()
                await decrementCreditIfSuccess()
            case .translate:
                output = try await generateTranslation()
                await decrementCreditIfSuccess()
            case .summarise:
                output = try await generateSummary()
                await decrementCreditIfSuccess()
            case .none:
                generationError = "Select an action."
            }
        } catch {
            generationError = error.localizedDescription
        }
        isGenerating = false
    }
    
    private func generateComment() async throws -> String {
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? UserDefaults.standard.string(forKey: "user_email")
            ?? UserDefaults.standard.string(forKey: "userEmail")
        let generator = LinkedInCommentGenerator(authToken: email)
        
        let trimmed = String(postPreview.prefix(1200))
        let prompt = "Generate a \(tone.rawValue.lowercased()) tone comment for a LinkedIn post: \(trimmed)"
        
        return try await withCheckedThrowingContinuation { cont in
            generator.generatePersonalizedComment(prompt: prompt, email: email, tone: tone.rawValue, toneDetails: commentOptions) { response in
                DispatchQueue.main.async {
                    guard let response = response else {
                        cont.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                        return
                    }
                    cont.resume(returning: self.cleanAPIString(response))
                }
            }
        }
    }
    
    private func generateTranslation() async throws -> String {
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? UserDefaults.standard.string(forKey: "user_email")
            ?? UserDefaults.standard.string(forKey: "userEmail")
        let generator = LinkedInCommentGenerator(authToken: email)
        let text = String(postPreview.prefix(2000))
        return try await withCheckedThrowingContinuation { cont in
            generator.translate(text: text, targetLanguage: selectedLanguage.rawValue, email: email) { response in
                DispatchQueue.main.async {
                    guard let response = response else {
                        cont.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                        return
                    }
                    cont.resume(returning: self.cleanAPIString(response))
                }
            }
        }
    }
    
    private func generateSummary() async throws -> String {
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? UserDefaults.standard.string(forKey: "user_email")
            ?? UserDefaults.standard.string(forKey: "userEmail")
        let generator = LinkedInCommentGenerator(authToken: email)
        let text = String(postPreview.prefix(4000))
        return try await withCheckedThrowingContinuation { cont in
            generator.summarize(text: text, style: summaryType.rawValue, email: email) { response in
                DispatchQueue.main.async {
                    guard let response = response else {
                        cont.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                        return
                    }
                    cont.resume(returning: self.cleanAPIString(response))
                }
            }
        }
    }
    
    // Decrement 1 credit and refresh remaining count
    @MainActor
    private func decrementCreditIfSuccess() async {
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? UserDefaults.standard.string(forKey: "user_email")
            ?? UserDefaults.standard.string(forKey: "userEmail")
        guard let email = email, !email.isEmpty else { return }
        let generator = LinkedInCommentGenerator(authToken: email)
        await withCheckedContinuation { cont in
            generator.increaseComments(email: email, increment: -1) { _ in
                // refresh count
                ApiService.shared.getRemainingComments(email: email) { _ in
                    cont.resume()
                }
            }
        }
    }
    
    private func cleanAPIString(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: "\\n", with: "\n")
        t = t.replacingOccurrences(of: "\\t", with: " ")
        t = t.replacingOccurrences(of: "\\\"", with: "\"")
        t = t.replacingOccurrences(of: "\\\\", with: "\\")
        t = t.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
        return t
    }
}

private struct AnalysePostView: View {
    @StateObject private var vm = AnalysePostViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionCard(title: "Analyse LinkedIn Post") {
                    TextField("Paste LinkedIn post URL", text: Binding(
                        get: { vm.url },
                        set: { vm.validateURL($0) }
                    ))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)
                    
                    Button {
                        Task { await vm.analyze() }
                    } label: {
                        HStack {
                            if vm.isAnalyzing { ProgressView() }
                            Text("Analyze")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!vm.isValidURL || vm.isAnalyzing)
                    
                    if let error = vm.analysisError {
                        Text(error).foregroundColor(.red)
                    }
                    
                    if !vm.postPreview.isEmpty {
                        Text("Post Preview")
                            .font(.subheadline).bold()
                        TextEditor(text: .constant(vm.postPreview))
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        
                        HStack {
                            actionButton("Comment", systemImage: "text.bubble", action: { vm.selectedAction = .comment })
                            actionButton("Translate", systemImage: "character.book.closed", action: { vm.selectedAction = .translate })
                            actionButton("Summarise", systemImage: "list.bullet.rectangle", action: { vm.selectedAction = .summarise })
                        }
                    }
                }
                
                // Action-specific UI
                switch vm.selectedAction {
                case .comment:
                    SectionCard(title: "Generate Comment") {
                        TextField("Comment Options (optional)", text: $vm.commentOptions)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Tone", selection: $vm.tone) {
                            ForEach(AITone.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button {
                            Task { await vm.generateForSelectedAction() }
                        } label: {
                            HStack {
                                if vm.isGenerating { ProgressView() }
                                Text("Generate Comment")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isGenerating || vm.postPreview.isEmpty)
                        
                        OutputArea(text: vm.output, isLoading: vm.isGenerating, error: vm.generationError)
                    }
                case .translate:
                    SectionCard(title: "Translate Post") {
                        Picker("Language", selection: $vm.selectedLanguage) {
                            ForEach(Language.allCases) { lang in
                                Text(lang.rawValue).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button {
                            Task { await vm.generateForSelectedAction() }
                        } label: {
                            HStack {
                                if vm.isGenerating { ProgressView() }
                                Text("Generate Translation")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isGenerating || vm.postPreview.isEmpty)
                        
                        OutputArea(text: vm.output, isLoading: vm.isGenerating, error: vm.generationError)
                    }
                case .summarise:
                    SectionCard(title: "Summarise Post") {
                        Picker("Summary Type", selection: $vm.summaryType) {
                            ForEach(SummaryType.allCases) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Button {
                            Task { await vm.generateForSelectedAction() }
                        } label: {
                            HStack {
                                if vm.isGenerating { ProgressView() }
                                Text("Generate Summary")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isGenerating || vm.postPreview.isEmpty)
                        
                        OutputArea(text: vm.output, isLoading: vm.isGenerating, error: vm.generationError)
                    }
                case .none:
                    EmptyView()
                }
            }
        }
    }
    
    private func actionButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - Create Post
private final class CreatePostViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable { case new = "New Post", repost = "Repost"; var id: String { rawValue } }
    
    @Published var mode: Mode = .repost
    
    // New Post
    @Published var postTopic: String = ""
    @Published var tone: AITone = .professional
    @Published var length: PostLength = .medium
    @Published var keywords: String = ""
    
    // Repost
    @Published var repostLink: String = ""
    @Published var repostTone: AITone = .professional
    @Published var useemoji: Bool = true
    @Published var usehashtags: Bool = true
    @Published var repostLength: PostLength = .medium
    @Published var isValidRepostURL: Bool = false
    
    // Output
    @Published var isGenerating: Bool = false
    @Published var generationError: String? = nil
    @Published var output: String = ""
    
    func validateRepostURL(_ text: String) {
        repostLink = text
        let pattern = #"^https?:\/\/(www\.)?linkedin\.com\/.*$"#
        isValidRepostURL = text.range(of: pattern, options: .regularExpression) != nil
    }
    
    @MainActor
    func generate() async {
        isGenerating = true
        generationError = nil
        output = ""
        do {
            switch mode {
            case .new:
                guard !postTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post Topic is required"])
                }
                output = try await generateNewPost()
                await decrementCreditIfSuccess()
            case .repost:
                guard isValidRepostURL else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Valid LinkedIn URL is required"])
                }
                output = try await generateRepost()
                await decrementCreditIfSuccess()
            }
        } catch {
            generationError = error.localizedDescription
        }
        isGenerating = false
    }
    
    private func generateNewPost() async throws -> String {
        let generator = LinkedInCommentGenerator(authToken: DualDefaults.string(forKey: "loggedInEmail") ?? UserDefaults.standard.string(forKey: "userEmail"))
        return try await withCheckedThrowingContinuation { cont in
            generator.createPost(postTopic: postTopic, contentTone: tone.rawValue, postLength: length.rawValue) { response in
                DispatchQueue.main.async {
                    guard let response = response else {
                        cont.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                        return
                    }
                    
                    let extracted = self.extractGeneratedText(from: response, key: "post")
                    cont.resume(returning: extracted)
                }
            }
        }
    }
    
    private func generateRepost() async throws -> String {
        let generator = LinkedInCommentGenerator(authToken: DualDefaults.string(forKey: "loggedInEmail") ?? UserDefaults.standard.string(forKey: "userEmail"))
        return try await withCheckedThrowingContinuation { cont in
            generator.createRepost(postUrl: repostLink, contentTone: repostTone.rawValue, postLength: repostLength.rawValue, useemoji: useemoji, usehashtag: usehashtags) { response in
                DispatchQueue.main.async {
                    guard let response = response else {
                        cont.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                        return
                    }
                    let extracted = self.extractGeneratedText(from: response, key: "repost")
                    cont.resume(returning: extracted)
                }
            }
        }
    }
    func loadRepostLink() {
        let defaults = UserDefaults(suiteName: "group.com.einstein.common")
        let link = defaults?.string(forKey: "LastProcessedLink") ?? ""
        repostLink = link
        isValidRepostURL = !link.isEmpty
    }

    // Decrement 1 credit and refresh remaining count
    @MainActor
    private func decrementCreditIfSuccess() async {
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? UserDefaults.standard.string(forKey: "user_email")
            ?? UserDefaults.standard.string(forKey: "userEmail")
        guard let email = email, !email.isEmpty else { return }
        let generator = LinkedInCommentGenerator(authToken: email)
        await withCheckedContinuation { cont in
            generator.increaseComments(email: email, increment: -1) { _ in
                ApiService.shared.getRemainingComments(email: email) { _ in
                    cont.resume()
                }
            }
        }
    }
    
    private func cleanAPIString(_ s: String) -> String {
        return s
    }
    
    private func extractGeneratedText(from raw: String, key: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove wrapping quotes (if LLM returns stringified JSON)
        if s.hasPrefix("\""), s.hasSuffix("\"") {
            s = String(s.dropFirst().dropLast())
        }

        // Try JSON decode into dictionary
        if let data = s.data(using: .utf8) {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let value = dict[key] as? String {
                return value
            }
        }

        // If still wrapped as "{\"post\":\"text\"}"
        // Try one more pass after unescaping
        let unescaped = s
            .replacingOccurrences(of: #"\\n"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\\t"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\\\""#, with: "\"", options: .regularExpression)
            .replacingOccurrences(of: #"\\\\"#, with: "\\", options: .regularExpression)

        if let data2 = unescaped.data(using: .utf8),
           let dict2 = try? JSONSerialization.jsonObject(with: data2) as? [String: Any],
           let value2 = dict2[key] as? String {
            return value2
        }

        // Regex fallback
        if let range = s.range(of: "\"\(key)\"\\s*:\\s*\"(.+?)\"", options: .regularExpression) {
            let m = String(s[range])
            return m
                .replacingOccurrences(of: "\"\(key)\":", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"{} "))
        }

        return s
    }

    
    private struct PostEnvelope: Decodable {
        let post: String
    }
    private struct RepostEnvelope: Decodable {
        let repost: String
    }
}

private struct CreatePostView: View {
    @StateObject private var vm = CreatePostViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Mode", selection: $vm.mode) {
//                    Text("New Post").tag(CreatePostViewModel.Mode.new)
                    Text("Repost").tag(CreatePostViewModel.Mode.repost)
                }
                .pickerStyle(.segmented)
                
                if vm.mode == .new {
                    SectionCard(title: "New Post") {
                        TextField("Post Topic", text: $vm.postTopic)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Content Tone", selection: $vm.tone) {
                            ForEach(AITone.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }.pickerStyle(.menu)
                        
                        Picker("Post Length", selection: $vm.length) {
                            ForEach(PostLength.allCases) { l in
                                Text(l.rawValue).tag(l)
                            }
                        }.pickerStyle(.menu)
                        
                        TextField("Keywords (optional)", text: $vm.keywords)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            Task { await vm.generate() }
                        } label: {
                            HStack {
                                if vm.isGenerating { ProgressView() }
                                Text("Generate Post")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isGenerating || vm.postTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        OutputArea(text: vm.output, isLoading: vm.isGenerating, error: vm.generationError)
                    }
                } else {
                    SectionCard(title: "Repost") {
//                        TextField("Post Link", text: Binding(
//                            get: { vm.repostLink },
//                            set: { vm.validateRepostURL($0) }
//                        ))
//                        .textInputAutocapitalization(.never)
//                        .disableAutocorrection(true)
//                        .keyboardType(.URL)
//                        .textFieldStyle(.roundedBorder)
                        Text(vm.repostLink.isEmpty ? "Please share link" : vm.repostLink.prefix(100))
                                    .foregroundColor(vm.repostLink.isEmpty ? .gray : .primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .onAppear {
                                        vm.loadRepostLink()
                                    }
                        
                        Picker("Content Tone", selection: $vm.repostTone) {
                            ForEach(AITone.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }.pickerStyle(.menu)
                        
                        Picker("Post Length", selection: $vm.repostLength) {
                            ForEach(PostLength.allCases) { l in
                                Text(l.rawValue).tag(l)
                            }
                        }.pickerStyle(.menu)

                        Toggle("Use Emojis and Hashtags", isOn: $vm.usehashtags)
                            .toggleStyle(.switch) // default on most platforms
                            .padding(.horizontal)
                        
                        Button {
                            Task { await vm.generate() }
                        } label: {
                            HStack {
                                if vm.isGenerating { ProgressView() }
                                Text("Generate Repost")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(vm.isGenerating || !vm.isValidRepostURL)
                        
                        OutputArea(text: vm.output, isLoading: vm.isGenerating, error: vm.generationError)
                    }
                }
            }
        }
    }
}

// MARK: - About Me
private final class AboutMeViewModel: ObservableObject {
    @Published var industry: String = ""
    @Published var yearsOfExperience: String = ""
    @Published var keySkills: String = ""
    @Published var professionalGoal: String = ""
    
    @Published var isGenerating: Bool = false
    @Published var generationError: String? = nil
    @Published var output: String = ""
    
    @MainActor
    func generate() async {
        isGenerating = true
        generationError = nil
        output = ""
        do {
            guard !industry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Industry is required"])
            }
            guard !yearsOfExperience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Years of Experience is required"])
            }
            guard Int(yearsOfExperience) != nil else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Years of Experience must be a number"])
            }
            guard !keySkills.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Key Skills are required"])
            }
            guard !professionalGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Professional Goal is required"])
            }
            
            let generator = LinkedInCommentGenerator(authToken: DualDefaults.string(forKey: "loggedInEmail") ?? UserDefaults.standard.string(forKey: "userEmail"))
            output = try await withCheckedThrowingContinuation { cont in
                generator.createAboutMe(
                    industry: industry,
                    experience: yearsOfExperience,
                    skills: keySkills,
                    goal: professionalGoal
                ) { response in
                    DispatchQueue.main.async {
                        guard let response = response else {
                            cont.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response"]))
                            return
                        }
                        cont.resume(returning: self.cleanAPIString(response))
                    }
                }
            }
            await decrementCreditIfSuccess()
        } catch {
            generationError = error.localizedDescription
        }
        isGenerating = false
    }
    
    // Decrement 1 credit and refresh remaining count
    @MainActor
    private func decrementCreditIfSuccess() async {
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? UserDefaults.standard.string(forKey: "user_email")
            ?? UserDefaults.standard.string(forKey: "userEmail")
        guard let email = email, !email.isEmpty else { return }
        let generator = LinkedInCommentGenerator(authToken: email)
        await withCheckedContinuation { cont in
            generator.increaseComments(email: email, increment: -1) { _ in
                ApiService.shared.getRemainingComments(email: email) { _ in
                    cont.resume()
                }
            }
        }
    }
    
    private func cleanAPIString(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: "\\n", with: "\n")
        t = t.replacingOccurrences(of: "\\t", with: " ")
        t = t.replacingOccurrences(of: "\\\"", with: "\"")
        t = t.replacingOccurrences(of: "\\\\", with: "\\")
        t = t.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
        return t
    }
}

private struct AboutMeView: View {
    @StateObject private var vm = AboutMeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SectionCard(title: "About Me") {
                    TextField("Industry", text: $vm.industry)
                        .textFieldStyle(.roundedBorder)
                    TextField("Years of Experience", text: $vm.yearsOfExperience)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    TextField("Key Skills (comma separated)", text: $vm.keySkills)
                        .textFieldStyle(.roundedBorder)
                    TextField("Professional Goal", text: $vm.professionalGoal)
                        .textFieldStyle(.roundedBorder)
                    
                    Button {
                        Task { await vm.generate() }
                    } label: {
                        HStack {
                            if vm.isGenerating { ProgressView() }
                            Text("Generate About Me")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isGenerating)
                    
                    OutputArea(text: vm.output, isLoading: vm.isGenerating, error: vm.generationError)
                }
            }
        }
    }
}


@MainActor
final class StoreViewModel: ObservableObject {
    private let productIdentifier = "com.einsteini.linkedInCompanion.300comments"
    
    @Published var product: Product?
    @Published var isPurchased: Bool = false
    @Published var errorMessage: String? = nil
    
    var onPaymentSuccess: (() -> Void)? = nil
    
    init(){
        Task {
            await loadProduct()
            await updatePurchaseStatus()
        }
        listenForTransactions()
    }
    
    func loadProduct() async {
        do {
            if let loaded = try await Product.products(for: [productIdentifier]).first {
                product = loaded
            }
        } catch {
            errorMessage = "Failed to load product: \(error.localizedDescription)"
        }
    }
    
    func purchase() async {
        guard let product else { return }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                switch verificationResult {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchaseStatus()
                    errorMessage = nil
                    onPaymentSuccess?()
                case .unverified(_, let verificationError):
                    errorMessage = "Purchase verification failed: \(verificationError.localizedDescription)"
                }
            case .userCancelled, .pending:
                // No error message needed for user cancelled or pending
                break
            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }
    
    func updatePurchaseStatus() async {
        if let result = await Transaction.latest(for: productIdentifier) {
            switch result {
            case .verified(let transaction):
                isPurchased = (transaction.revocationDate == nil)
            default:
                isPurchased = false
            }
        } else {
            isPurchased = false
        }
        errorMessage = nil
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
            errorMessage = nil
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }
    
    private func listenForTransactions() {
        Task{
            for await update in Transaction.updates{
                if case .verified(let transaction) = update,
                   transaction.productID == productIdentifier {
                    await transaction.finish()
                    await updatePurchaseStatus()
                }
            }
        }
    }
}


// ---------------------------
// SubscriptionView (new view)
// ---------------------------
struct SubscriptionView: View {
    @StateObject private var storeVM = StoreViewModel()

    private static func updateUserData() {
        // Retrieve email from stored defaults (try multiple keys used in this app)
        let defaults = UserDefaults.standard
        let email = DualDefaults.string(forKey: "loggedInEmail")
            ?? defaults.string(forKey: "user_email")
            ?? defaults.string(forKey: "userEmail")

        guard let email = email, !email.isEmpty else {
            print("[Subscription] Cannot increase comments: missing email")
            return
        }

        guard let url = URL(string: "http://backend.einsteini.ai/increaseComments") else {
            print("[Subscription] Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "email": email,
            "increment": 300
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("[Subscription] Failed to encode payload: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[Subscription] Increase comments request failed: \(error.localizedDescription)")
                return
            }

            if let http = response as? HTTPURLResponse {
                let status = http.statusCode
                if status == 200 {
                    print("[Subscription] Successfully increased comments by 300 for \(email)")
                } else {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                    print("[Subscription] Server responded with status \(status): \(body)")
                }
            } else {
                print("[Subscription] Invalid response")
            }
        }.resume()
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Subscription Plans")
                .font(.title)
                .bold()
                .padding(.top)
            
            if let errorMessage = storeVM.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 1.0, green: 0.85, blue: 0.85))
                    .cornerRadius(8)
            }
            
            if let product = storeVM.product {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(product.displayPrice)
                    .font(.title2)
                    .foregroundColor(.purple)
                if storeVM.isPurchased {
                    Text("Purchased ✅")
                        .foregroundColor(.green)
                    Button("Restore Purchases") {
                        Task {
                            await storeVM.restorePurchases()
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Subscribe") {
                        Task { await storeVM.purchase() }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Restore Purchases") {
                        Task {
                            await storeVM.restorePurchases()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ProgressView("Loading...")
                Text("Try Later")
            }
            Spacer()
        }
        .padding()
        .onAppear {
            storeVM.onPaymentSuccess = {
                SubscriptionView.updateUserData()
            }
        }
    }
}


// ---------------------------
// HistoryView (cleaned & methods inside struct)
// ---------------------------
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var sharedLinks: [String] = []
    @State private var latestResult: [String: String] = [:]
    @State private var lastProcessedLink: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if sharedLinks.isEmpty {
                    Text("No links shared yet.")
                        .foregroundColor(.secondary)
                } else {
                    Section(header: Text("Your Library")) {
                        ForEach(sharedLinks, id: \.self) { link in
                            Text(link)
                                .font(.footnote)
                                .foregroundColor(.blue)
                                .lineLimit(2)
                                .padding(.vertical, 4)
                        }
                    }
                }

                if !latestResult.isEmpty {
                    Section(header: Text("Latest Results")) {
                        ForEach(latestResult.sorted(by: { $0.key < $1.key }), id: \.key) { tone, comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(comment)
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                } else {
                    Text("No processed results yet.")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Button("🔄 Load") {
                        loadSharedLinks()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                    Button("🗑 Clear") {
                        clearSharedLinks()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadSharedLinks()
        }
    }

    // MARK: - Helpers (kept from your original code)
    func loadSharedLinks() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
            sharedDefaults.synchronize()

            sharedLinks = sharedDefaults.stringArray(forKey: "SharedLinks") ?? []
            lastProcessedLink = sharedDefaults.string(forKey: "LastProcessedLink")

            if let results = sharedDefaults.dictionary(forKey: "LatestResult") as? [String: String] {
                latestResult = results
            }
        }
    }

    func clearSharedLinks() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
            sharedDefaults.synchronize()
            sharedDefaults.removeObject(forKey: "SharedLinks")
            sharedDefaults.removeObject(forKey: "LastProcessedLink")
            sharedDefaults.removeObject(forKey: "LatestResult")
            sharedLinks = []
            lastProcessedLink = nil
            latestResult = [:]
        }
    }

}

// ---------------------------
// SettingsView - settings tab
// ---------------------------

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showDeleteSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Toggle("Enable Notifications", isOn: $appState.enableNotifications)
            Toggle("Dark Mode", isOn: $appState.darkMode)
            
            Divider()
            
            VStack (alignment: .leading, spacing: 12) {
                Text("SUBSCRIPTION")
                    .font(.headline)
                Text("Purchases and subscription management occur on our website.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button(action: {
                    if let url = URL(string: "https://app.einsteini.ai/pricing") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Manage Subscription on Web")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Text("DANGER ZONE")
                .font(.headline)
                .foregroundColor(.red)
            
            HStack {
                Image(systemName: "trash").foregroundColor(.red)
                Button("Delete Account") {
                    showDeleteSheet = true
                }
                .foregroundColor(.red)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
        .sheet(isPresented: $showDeleteSheet) {
            DeleteInfoSheet()
                .presentationDetents([.medium, .large]) // makes it look like popup
        }
    }
}

struct DeleteInfoSheet: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Important Instructions")
                        .font(.title2).bold()
                    
                    Text("• After deleting your account, you cannot recover it.")
                    Text("• You will lose access to your data and history.")
                    Text("• You can permanently delete your account on the web using the link below.")

                    Spacer(minLength: 30)

                    Button(action: {
                        // IMPORTANT: This must link directly to the exact deletion page, not a generic page.
                        if let url = URL(string: "https://app.einsteini.ai/account/delete") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Go to Account Deletion")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}




// ---------------------------
// SideMenuView - now accepts selectedTab binding
// ---------------------------
struct SideMenuView: View {
    @Binding var showMenu: Bool            // controls slide-in on small screens
    @Binding var selectedTab: Int         // 0 = Home, 1 = AI, 2 = History, 3=Settings, 4=Subscription
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Profile section
            VStack(alignment: .leading, spacing: 8) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 60, height: 60)
                    .overlay(Text(String(appState.Username?.prefix(1) ?? "U"))
                                .font(.title)
                                .foregroundColor(.white))

                Text(appState.Username ?? "Guest User")
                    .font(.headline)
                    .foregroundColor(.white)

                Text(appState.loggedInEmail ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)

            // Menu items that change the selected tab
            menuItem(icon: "house", title: "Home", index: 0)
            menuItem(icon: "sparkles", title: "AI Assistant", index: 1)
            menuItem(icon: "clock.arrow.circlepath", title: "History", index: 2)
            menuItem(icon: "cart", title: "Subscription", index: 4)
            menuItem(icon: "gearshape", title: "Settings", index: 3)

            Divider().background(Color.white.opacity(0.2))

            // Other static menu items
            menuItem(icon: "book", title: "Tutorial", link: "https://einsteini.ai")
            Spacer()
            HStack{
                Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.red)
                Button("Log out") {
                    appState.logOut()
                }
                .foregroundColor(.red)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 20/255, green: 22/255, blue: 37/255))
        .foregroundColor(.white)
    }

    @ViewBuilder
    private func menuItem(icon: String, title: String, index: Int? = nil,  link: String? = nil, color: Color? = .white) -> some View {
        Button(action: {
            if let idx = index {
                // switch to requested tab
                selectedTab = idx
                withAnimation {
                    showMenu = false // hide on compact screens
                }
            } else if let urlString = link, let url = URL(string: urlString) {
                // Open external link
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(color)
                    .font(.body)
            }
            .padding(.vertical, 8)
        }
    }
}




// ---------------------------
// MainView - adaptive layout
// ---------------------------
struct MainView: View {
    @State private var selectedTab = 0
    @State private var showMenu = false
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width >= 700

            HStack(spacing: 0) {
                if isWide {
                    // Permanent sidebar on wide screens
                    SideMenuView(showMenu: .constant(true), selectedTab: $selectedTab)
                        .frame(width: 260)
                        .transition(.move(edge: .leading))
                }

                ZStack {
                    // Main tabs (each tab is wrapped in a NavigationView so it has a nav bar)
                    TabView(selection: $selectedTab) {

                        NavigationView {
                            HomeView()
                                .navigationTitle("Home")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        // Only show hamburger on compact screens
                                        if !isWide {
                                            menuButton
                                        }
                                    }
                                }
                        }
                        .applyNavigationStyle() // 👈 Fix for iPad
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }
                        .tag(0)

                        NavigationView {
                            AIAssistantView()
                                .navigationTitle("AI Assistant")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        if !isWide { menuButton }
                                    }
                                }
                        }
                        .applyNavigationStyle() // 👈 Fix for iPad
                        .tabItem {
                            Label("AI Assistant", systemImage: "sparkles")
                        }
                        .tag(1)

                        NavigationView {
                            HistoryView()
                                .navigationTitle("History")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        if !isWide { menuButton }
                                    }
                                }
                        }
                        .applyNavigationStyle() // 👈 Fix for iPad
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        .tag(2)
                        
                        NavigationView {
                            SettingsView()
                                .navigationTitle("⚙️ Settings")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        if !isWide { menuButton }
                                    }
                                }
                        }
                        .applyNavigationStyle()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .tag(3)
                        
                        NavigationView {
                            SubscriptionView()
                                .navigationTitle("Subscription")
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        if !isWide { menuButton }
                                    }
                                }
                        }
                        .applyNavigationStyle()
                        .tabItem {
                            Label("Subscription", systemImage: "cart")
                        }
                        .tag(4)
                    }
                    .accentColor(.purple)

                    // Overlay for slide-in menu on compact screens
                    if !isWide {
                        Color.black.opacity(showMenu ? 0.3 : 0)
                            .ignoresSafeArea()
                            .animation(.easeInOut, value: showMenu)
                            .onTapGesture {
                                withAnimation { showMenu = false }
                            }

                        HStack {
                            if showMenu {
                                SideMenuView(showMenu: $showMenu, selectedTab: $selectedTab)
                                    .frame(width: 260)
                                    .transition(.move(edge: .leading))
                            }
                            Spacer()
                        }
                        .animation(.easeInOut, value: showMenu)
                    }
                } // ZStack
            } // HStack
            .onAppear {
                // always start on Home tab
                selectedTab = 0
            }
        } // GeometryReader
    }

    private var menuButton: some View {
        Button(action: {
            withAnimation { showMenu.toggle() }
        }) {
            Image(systemName: "line.horizontal.3")
                .imageScale(.large)
                .foregroundColor(.purple)
        }
    }
}

// ---------------------------
// Navigation Style Helper
// ---------------------------
extension View {
    func applyNavigationStyle() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return AnyView(self.navigationViewStyle(StackNavigationViewStyle()))
        } else {
            return AnyView(self)
        }
    }
}


struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Login to einsteini.ai")
                .font(.largeTitle.bold())

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if isLoading {
                ProgressView()
            }

            Button(action: {
                isLoading = true
                loginManually(email: email, password: password) { result in
                    DispatchQueue.main.async {
                        isLoading = false
                        if result["success"] as? Bool == true {
                            appState.logIn(email: email, name: "")
                            
                            Task {
                                let verification = await authService.verifyAccount(
                                    email: email,
                                    token: email
                                )
                                
                                if !verification.success {
                                    errorMessage = "Login failed. Please check your credentials."
                                }
                            }
                        } else {
                            errorMessage = "Login failed. Please check your credentials."
                        }
                    }
                }
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Divider().padding(.vertical)

            GoogleSignInButton(action: handleGoogleSignIn)
                .frame(height: 44)
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.email, .fullName]
                },
                onCompletion: handleAppleSignIn
            )
            .frame(height: 44)
            .cornerRadius(8)


            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    func loginManually(email: String, password: String, completion: @escaping ([String: Any]) -> Void) {
        print("Attempting login for email: \(email)")

        guard let url = URL(string: "https://backend.einsteini.ai/login") else {
            completion([
                "success": false,
                "message": "Invalid URL",
                "error": "Bad endpoint"
            ])
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error encoding body: \(error)")
            completion([
                "success": false,
                "message": "Invalid request body",
                "error": error.localizedDescription
            ])
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Login failed with error: \(error)")
                completion([
                    "success": false,
                    "message": "Login failed",
                    "error": error.localizedDescription
                ])
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion([
                    "success": false,
                    "message": "No response",
                    "error": "Invalid response object"
                ])
                return
            }
            
            print("Login response status: \(httpResponse.statusCode)")
            
            guard let data = data else {
                completion([
                    "success": false,
                    "message": "No data",
                    "error": "Empty response body"
                ])
                return
            }
            
            var json: Any?
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                print("Error parsing JSON: \(error)")
                completion([
                    "success": false,
                    "message": "Invalid server response",
                    "error": "Failed to parse server response"
                ])
                return
            }

            guard let responseData = json as? [String: Any] else {
                completion([
                    "success": false,
                    "message": "Unexpected response format",
                    "error": "Non-dictionary response"
                ])
                return
            }

            if httpResponse.statusCode == 200 {
                if responseData["requireVerification"] as? Bool == true {
                    completion([
                        "success": false,
                        "message": responseData["msg"] as? String ?? "Account not verified. Please check your email for the verification code.",
                        "requireVerification": true,
                        "email": email
                    ])
                    return
                }
                
                if responseData["success"] as? Bool == true {
                    if let customerId = responseData["customerId"] as? String {
                        DualDefaults.set(customerId, forKey: "auth_token")
                        print("Auth token (customerId) saved successfully")
                    }

                    // ✅ You requested this exact code:
                    DualDefaults.set(true, forKey: "isLoggedIn")
                    DualDefaults.set(email, forKey: "userEmail")

                    completion([
                        "success": true,
                        "message": responseData["msg"] as? String ?? "Login successful",
                        "user": ["email": email]
                    ])
                    return
                } else {
                    let errorMsg = responseData["error"] as? String ?? responseData["msg"] as? String ?? "Authentication failed"
                    completion([
                        "success": false,
                        "message": errorMsg,
                        "error": errorMsg
                    ])
                    return
                }
            } else {
                let errorMsg = responseData["error"] as? String ?? responseData["msg"] as? String ?? "Authentication failed"
                print("Login failed: \(httpResponse.statusCode)")
                print("Response: \(String(data: data, encoding: .utf8) ?? "")")
                completion([
                    "success": false,
                    "message": errorMsg,
                    "error": "Login failed"
                ])
                return
            }
        }
        
        task.resume()
    }

    func handleGoogleSignIn() {
        guard let presentingVC = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "No root view controller"
            return
        }

        // ✅ FIX: Save config and pass it into signIn()
        let config = GIDConfiguration(clientID: "940646244947-fij3eakntc9shdjkqsha2r1uc412992o.apps.googleusercontent.com")

        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                }
                return
            }

            guard let user = result?.user,
                  let profile = user.profile else {
                DispatchQueue.main.async {
                    errorMessage = "Google profile missing."
                }
                return
            }

            let body = ["name": profile.name, "email": profile.email]
            var request = URLRequest(url: URL(string: "https://backend.einsteini.ai/api/sociallogin")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            URLSession.shared.dataTask(with: request) { _, _, _ in
                DispatchQueue.main.async {
                    appState.logIn(email: profile.email, name : profile.name)
                }
            }.resume()
        }
    }
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                let email = appleIDCredential.email ?? ""
                let fullName = [
                    appleIDCredential.fullName?.givenName,
                    appleIDCredential.fullName?.familyName
                ]
                .compactMap { $0 }
                .joined(separator: " ")
                
                let userData: [String: Any] = [
                    "name": fullName.isEmpty ? "Apple User" : fullName,
                    "email": email
                ]

                var request = URLRequest(url: URL(string: "https://backend.einsteini.ai/api/sociallogin")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try? JSONSerialization.data(withJSONObject: userData)

                URLSession.shared.dataTask(with: request) { _, _, _ in
                    DispatchQueue.main.async {
                        appState.logIn(email: email, name: email)
                        Task {
                            let verification = await authService.verifyAccount(
                                email: email,
                                token: email
                            )
                            
                            if !verification.success {
                                errorMessage = "Login failed. Please check your credentials."
                            }
                        }
                    }
                }.resume()
            }

        case .failure(let error):
            DispatchQueue.main.async {
                errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
        }
    }


}





// MARK: - Content View Root
struct ContentView: View {
    @State private var showSplash = true
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @StateObject var appState = AppState()

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
            } else {
                if !hasCompletedSetup {
                    KeyboardSetupView()
                } else if appState.isLoggedIn {
                    MainView()
                        .environmentObject(appState)
                } else {
                    LoginView()
                        .environmentObject(appState)
                        .environmentObject(AuthService())
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
