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

    init() {
        isLoggedIn = UserDefaults.standard.string(forKey: "loggedInEmail") != nil
        subscriptionStatus = UserDefaults.standard.string(forKey: "subscriptionStatus") ?? "Unknown"
        remainingComments = UserDefaults.standard.integer(forKey: "remainingComments")
    }

    func logIn(email: String) {
        UserDefaults.standard.set(email, forKey: "loggedInEmail")
        isLoggedIn = true
    }

    func logOut() {
        UserDefaults.standard.removeObject(forKey: "loggedInEmail")
        UserDefaults.standard.removeObject(forKey: "subscriptionStatus")
        UserDefaults.standard.removeObject(forKey: "remainingComments")
        subscriptionStatus = "Unknown"
        remainingComments = 0
        isLoggedIn = false
    }

    var loggedInEmail: String? {
        UserDefaults.standard.string(forKey: "loggedInEmail")
    }

    func updateSubscriptionStatus(_ status: String) {
        subscriptionStatus = status
        UserDefaults.standard.set(status, forKey: "subscriptionStatus")
    }

    func updateRemainingComments(_ count: Int) {
        remainingComments = count
        UserDefaults.standard.set(count, forKey: "remainingComments")
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

            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(22)

            Toggle("I have enabled the keyboard", isOn: $hasConfirmed)
                .padding(.top, 12)

            Button("Continue") {
                requestPermissions()
                hasCompletedSetup = true
            }
            .disabled(!hasConfirmed)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(hasConfirmed ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(22)
            .padding(.top)

            Spacer()
        }
        .padding()
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        if #available(iOS 17, *) {
            AVAudioApplication.requestRecordPermission { granted in
                print(granted ? "Microphone access granted" : "Microphone access denied")
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print(granted ? "Microphone access granted" : "Microphone access denied")
            }
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

// MARK: - Main App View

struct ApiTestView: View {
    @State private var previewText: String = "Loading..."
    
    let apiURL = "https://backend.einsteini.ai/scrape?url=https://www.linkedin.com/posts/project-jatayu-rvce_project-jatayu-had-the-privilege-and-honour-ugcPost-7353267182069260291-Gw-R?utm_source=share&utm_medium=member_desktop&rcm=ACoAAEg_wbIBgVA5wmxmco4Y7S6l6lZo5wW5xHg"

    var body: some View {
        VStack(spacing: 20) {
            Text("API Response Preview")
                .font(.headline)

            ScrollView {
                Text(previewText)
                    .font(.body)
                    .padding()
            }
        }
        .onAppear {
            fetchPreview()
        }
        .padding()
    }
    
    func fetchPreview() {
        guard let url = URL(string: apiURL) else {
            previewText = "Invalid URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    previewText = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                let shortPreview: String
                if responseString.count > 150 {
                    let index = responseString.index(responseString.startIndex, offsetBy: 150)
                    shortPreview = String(responseString[..<index]) + "..."
                } else {
                    shortPreview = responseString
                }
                DispatchQueue.main.async {
                    previewText = shortPreview
                }
            } else {
                DispatchQueue.main.async {
                    previewText = "No valid response received"
                }
            }
        }.resume()
    }
}

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @State private var sharedLinks: [String] = []
    @State private var latestResult: [String: String] = [:]
    @State private var lastProcessedLink: String?
    @State private var showApiTest = false

    var body: some View {
        
        VStack(spacing: 24) {
            Text("👋 Welcome back to")
                .font(.title2)

            Text("einsteini.ai")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            if let email = appState.loggedInEmail {
                Text("Logged in as: \(email)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Button("🔎 Open API Test View") {
                showApiTest = true
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            .sheet(isPresented: $showApiTest) {
                ApiTestView()
            }

            Group {
                Text("📦 Subscription Status: \(appState.subscriptionStatus)")
                    .font(.subheadline)
                    .foregroundColor(.blue)

                Text("💬 Remaining Comments: \(appState.remainingComments)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            Divider().padding(.horizontal)

            Text("Shared Links")
                .font(.headline)

            if sharedLinks.isEmpty {
                Text("No links shared yet.")
                    .foregroundColor(.secondary)
            } else {
                // List of all shared links
                Section(header: Text("Shared Links")) {
                    List(sharedLinks, id: \.self) { link in
                        Text(link)
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .lineLimit(2)
                    }
                }
                
                // Latest API results (dictionary -> key/value list)
                if !latestResult.isEmpty {
                    Section(header: Text("Latest Results")) {
                        List(latestResult.sorted(by: { $0.key < $1.key }), id: \.key) { tone, comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(comment)
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                    .lineLimit(2)
                            }
                        }
                    }
                } else {
                    Text("No processed results yet.")
                        .foregroundColor(.secondary)
                }
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

            Button("Log out") {
                appState.logOut()
            }
            .foregroundColor(.red)

            Spacer()
            
            Text(try! AttributedString(markdown: "Login to Our Website [einsteini.ai](https://einsteini.ai) for subscription and other changes"))
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .onAppear {
            loadSharedLinks()
            loadSubscriptionStatus()
        }
    }

    func loadSharedLinks() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
            sharedDefaults.synchronize()
            
            // Load all links (history)
            sharedLinks = sharedDefaults.stringArray(forKey: "SharedLinks") ?? []
            print("✅ Accessed shared links: \(sharedLinks)")
            
            // Load last processed link
            lastProcessedLink = sharedDefaults.string(forKey: "LastProcessedLink")
            print("✅ Last processed link: \(lastProcessedLink ?? "nil")")
            
            // Load latest API results
            if let results = sharedDefaults.dictionary(forKey: "LatestResult") as? [String: String] {
                latestResult = results
                print("✅ Latest API results: \(results)")
            } else {
                print("⚠️ No processed results found.")
            }
            
        } else {
            print("❌ Failed to access UserDefaults with app group")
        }
    }

    func clearSharedLinks() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
            sharedDefaults.synchronize()
            sharedDefaults.removeObject(forKey: "SharedLinks")
            sharedDefaults.removeObject(forKey: "LastProcessedLink")
            sharedDefaults.removeObject(forKey: "LatestResult")
            sharedLinks = []
            lastProcessedLink = ""
            latestResult = [:]
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

struct LoginView: View {
    @EnvironmentObject var appState: AppState
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
                            appState.logIn(email: email)
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
                        UserDefaults.standard.set(customerId, forKey: "auth_token")
                        print("Auth token (customerId) saved successfully")
                    }

                    // ✅ You requested this exact code:
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(email, forKey: "userEmail")

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
                    appState.logIn(email: profile.email)
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
                        appState.logIn(email: email)
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
                    MainAppView()
                        .environmentObject(appState)
                } else {
                    LoginView()
                        .environmentObject(appState)
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
