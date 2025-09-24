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

           UserDefaults.standard.set(darkMode, forKey: "darkMode")
           print("Dark Mode \(darkMode ? "enabled" : "disabled")")
       }

       // MARK: - Notifications
       private func updateNotifications() {
           UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")

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
           darkMode = UserDefaults.standard.bool(forKey: "darkMode")
           enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
       }


    init() {
        isLoggedIn = UserDefaults.standard.string(forKey: "loggedInEmail") != nil
        subscriptionStatus = UserDefaults.standard.string(forKey: "subscriptionStatus") ?? "Unknown"
        remainingComments = UserDefaults.standard.integer(forKey: "remainingComments")
    }

    func logIn(email: String, name : String) {
        UserDefaults.standard.set(name, forKey: "User_name")
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
    var Username: String?{
        UserDefaults.standard.string(forKey: "User_name")
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




//// MARK: - Main App View
//struct HomeView: View {
//    @EnvironmentObject var appState: AppState
//    
//    var body: some View {
//        VStack(spacing: 24) {
//            if let user_name = appState.Username {
//                Text("👋 Welcome back \(user_name)")
//                    .font(.title2)
//            } else {
//                Text("👋 Welcome back to")
//                    .font(.title2)
//            }
//            
//            Text("einsteini.ai")
//                .font(.largeTitle)
//                .fontWeight(.bold)
//                .foregroundColor(.purple)
//            
//            if let email = appState.loggedInEmail {
//                Text("Logged in as: \(email)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            
//            Text("💬 Remaining Comments: \(appState.remainingComments)")
//                .font(.subheadline)
//                .foregroundColor(.green)
//            
//            Divider().padding(.horizontal)
//        }
//        .navigationTitle("Home")
//    }
//}
//
//
//struct AIAssistantView: View {
//    @EnvironmentObject var appstate: AppState
//    var body: some View {
//        NavigationView {
//            Text("✨ AI Assistant Screen")
//                .navigationTitle("AI Assistant")
//        }
//    }
//}
//
//struct HistoryView: View {
//    @EnvironmentObject var appState: AppState
//    @State private var sharedLinks: [String] = []
//    @State private var latestResult: [String: String] = [:]
//    @State private var lastProcessedLink: String?
//    
//    var body: some View {
//        NavigationView {
//            Text("🕒 History Screen")
//                .navigationTitle("History")
//            Text("History")
//                .font(.headline)
//
//            if sharedLinks.isEmpty {
//                Text("No links shared yet.")
//                    .foregroundColor(.secondary)
//            } else {
//                // List of all shared links
//                Section(header: Text("Your Library")) {
//                    List(sharedLinks, id: \.self) { link in
//                        Text(link)
//                            .font(.footnote)
//                            .foregroundColor(.blue)
//                            .lineLimit(2)
//                    }
//                }
//                
//                // Latest API results (dictionary -> key/value list)
//                if !latestResult.isEmpty {
//                    Section(header: Text("Latest Results")) {
//                        List(latestResult.sorted(by: { $0.key < $1.key }), id: \.key) { tone, comment in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(tone)
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                Text(comment)
//                                    .font(.footnote)
//                                    .foregroundColor(.blue)
//                                    .lineLimit(2)
//                            }
//                        }
//                    }
//                } else {
//                    Text("No processed results yet.")
//                        .foregroundColor(.secondary)
//                }
//            }
//
//
//            HStack {
//                Button("🔄 Load") {
//                    loadSharedLinks()
//                }
//                .padding()
//                .background(Color.blue.opacity(0.1))
//                .cornerRadius(8)
//
//                Button("🗑 Clear") {
//                    clearSharedLinks()
//                }
//                .padding()
//                .background(Color.red.opacity(0.1))
//                .cornerRadius(8)
//            }
//
//            Button("Log out") {
//                appState.logOut()
//            }
//            .foregroundColor(.red)
//
//            Spacer()
//            
////            Text(try! AttributedString(markdown: "Login to Our Website [einsteini.ai](https://einsteini.ai) for subscription and other changes"))
////                .font(.subheadline)
////                .foregroundColor(.gray)
//        }
//        .padding()
//        .onAppear {
//            loadSharedLinks()
//            loadSubscriptionStatus()
//        }
//        }
//    func loadSharedLinks() {
//        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
//            sharedDefaults.synchronize()
//            
//            // Load all links (history)
//            sharedLinks = sharedDefaults.stringArray(forKey: "SharedLinks") ?? []
//            print("✅ Accessed shared links: \(sharedLinks)")
//            
//            // Load last processed link
//            lastProcessedLink = sharedDefaults.string(forKey: "LastProcessedLink")
//            print("✅ Last processed link: \(lastProcessedLink ?? "nil")")
//            
//            // Load latest API results
//            if let results = sharedDefaults.dictionary(forKey: "LatestResult") as? [String: String] {
//                latestResult = results
//                print("✅ Latest API results: \(results)")
//            } else {
//                print("⚠️ No processed results found.")
//            }
//            
//        } else {
//            print("❌ Failed to access UserDefaults with app group")
//        }
//    }
//
//    func clearSharedLinks() {
//        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
//            sharedDefaults.synchronize()
//            sharedDefaults.removeObject(forKey: "SharedLinks")
//            sharedDefaults.removeObject(forKey: "LastProcessedLink")
//            sharedDefaults.removeObject(forKey: "LatestResult")
//            sharedLinks = []
//            lastProcessedLink = ""
//            latestResult = [:]
//        }
//    }
//
//    func loadSubscriptionStatus() {
//        guard let email = appState.loggedInEmail else { return }
//
//        ApiService.shared.getSubscriptionType(email: email) { status, error in
//            if let status = status {
//                DispatchQueue.main.async {
//                    appState.updateSubscriptionStatus(status)
//                }
//            }
//        }
//
//        ApiService.shared.getRemainingComments(email: email) { count in
//            if let count = count {
//                DispatchQueue.main.async {
//                    appState.updateRemainingComments(count)
//                }
//            }
//        }
//    }
//
//}
//
////struct MainView: View {
////        @State private var selectedTab = 0
////        @State private var showMenu = false
////        
////        var body: some View {
////            TabView(selection: $selectedTab) {
////                
////                // Home Tab
////                HomeView()
////                    .tabItem {
////                        Label("Home", systemImage: "house")
////                    }
////                    .tag(0)
////                
////                // AI Assistant Tab
////                AIAssistantView()
////                    .tabItem {
////                        Label("AI Assistant", systemImage: "sparkles")
////                    }
////                    .tag(1)
////                
////                // History Tab
////                HistoryView()
////                    .tabItem {
////                        Label("History", systemImage: "clock.arrow.circlepath")
////                    }
////                    .tag(2)
////            }
////            .accentColor(.purple) // active tab color
////
////        }
////        
////    }
//struct MainView: View {
//    @State private var selectedTab = 0
//    @State private var showMenu = false
//    @EnvironmentObject var appState: AppState
//    
//    var body: some View {
//        ZStack {
//            // MARK: Side Menu (always there under the main screen)
//            SideMenuView(showMenu: $showMenu)
//                .offset(x: showMenu ? 0 : -250) // slide in/out
//                .zIndex(1)
//            
//            // MARK: Main Content with Tabs
//            TabView(selection: $selectedTab) {
//                
//                NavigationView {
//                    HomeView()
//                        .navigationBarTitle("Home", displayMode: .inline)
//                        .navigationBarItems(leading: menuButton)
//                }
//                .tabItem {
//                    Label("Home", systemImage: "house")
//                }
//                .tag(0)
//                
//                NavigationView {
//                    AIAssistantView()
//                        .navigationBarTitle("AI Assistant", displayMode: .inline)
//                        .navigationBarItems(leading: menuButton)
//                }
//                .tabItem {
//                    Label("AI Assistant", systemImage: "sparkles")
//                }
//                .tag(1)
//                
//                NavigationView {
//                    HistoryView()
//                        .navigationBarTitle("History", displayMode: .inline)
//                        .navigationBarItems(leading: menuButton)
//                }
//                .tabItem {
//                    Label("History", systemImage: "clock.arrow.circlepath")
//                }
//                .tag(2)
//            }
//            .accentColor(.purple)
//            .zIndex(0)
//            .onAppear {
//                // Always open on Home tab
//                selectedTab = 0
//            }
//        }
//    }
//    
//    // MARK: Hamburger Button
//    private var menuButton: some View {
//        Button(action: {
//            withAnimation {
//                showMenu.toggle()
//            }
//        }) {
//            Image(systemName: "line.horizontal.3")
//                .imageScale(.large)
//                .foregroundColor(.purple)
//        }
//    }
//}
//
//
//
//struct SideMenuView: View {
//    @Binding var showMenu: Bool
//    @EnvironmentObject var appState: AppState
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 24) {
//            // Profile section
//            VStack(alignment: .leading, spacing: 8) {
//                Circle()
//                    .fill(Color.purple)
//                    .frame(width: 60, height: 60)
//                    .overlay(Text(String(appState.Username?.prefix(1) ?? "U"))
//                                .font(.title)
//                                .foregroundColor(.white))
//
//                Text(appState.Username ?? "Guest User")
//                    .font(.headline)
//                    .foregroundColor(.white)
//
//                Text(appState.loggedInEmail ?? "")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            .padding(.bottom, 30)
//
//            // Menu items
//            menuItem(icon: "house", title: "Home")
//            menuItem(icon: "sparkles", title: "AI Assistant")
//            menuItem(icon: "clock.arrow.circlepath", title: "History")
//            menuItem(icon: "person", title: "Profile")
//            menuItem(icon: "gearshape", title: "Settings")
//            menuItem(icon: "creditcard", title: "Subscription")
//            menuItem(icon: "book", title: "Tutorial")
//
//            Spacer()
//        }
//        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(Color(red: 20/255, green: 22/255, blue: 37/255))
//        .edgesIgnoringSafeArea(.all)
//    }
//
//    private func menuItem(icon: String, title: String) -> some View {
//        Button(action: {
//            withAnimation { showMenu = false }
//            // TODO: handle navigation
//        }) {
//            HStack(spacing: 16) {
//                Image(systemName: icon)
//                    .foregroundColor(.white)
//                Text(title)
//                    .foregroundColor(.white)
//                    .font(.body)
//            }
//            .padding(.vertical, 8)
//        }
//    }
//}
//    
//

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
            // navigationTitle will be set by the NavigationView in MainView
        }
    }

}

// ---------------------------
// AIAssistantView (plain content)
// ---------------------------
struct AIAssistantView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text("✨ AI Assistant Screen")
                .font(.title2)
            Image(systemName: "timer") // Use a system icon
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Something great is on its way.💪🏽")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("We're working hard to bring you a new feature. Check back soon!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding()
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
            loadSubscriptionStatus()
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
// SettingsView - settings tab
// ---------------------------


struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Toggle("Enable Notifications", isOn: $appState.enableNotifications)
            Toggle("Dark Mode", isOn: $appState.darkMode)
            
            
            Divider()
            HStack{
                Image(systemName: "rectangle.portrait.and.arrow.right").foregroundColor(.red)
                Button("Log Out") {
                    appState.logOut()
                }
                .foregroundColor(.red)
            }
            HStack{
                Image(systemName: "trash").foregroundColor(.red)
                Button("Delete Account"){
                    let link: String?
                    link = "https://einsteini.ai"
                    if let urlString = link, let url = URL(string: urlString) {
                        // Open external link
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.red)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Settings")
    }
}

// ---------------------------
// SideMenuView - now accepts selectedTab binding
// ---------------------------
struct SideMenuView: View {
    @Binding var showMenu: Bool            // controls slide-in on small screens
    @Binding var selectedTab: Int         // 0 = Home, 1 = AI, 2 = History
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
            
            menuItem(icon: "trash", title: "Delete Account", link: "https://einsteini.ai", color: .red ).foregroundColor(.red)

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
    @State private var selectedTab = 1
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


//// ---------------------------
//// MainView - adaptive layout
//// ---------------------------
//struct MainView: View {
//    @State private var selectedTab = 1
//    @State private var showMenu = false
//    @EnvironmentObject var appState: AppState
//
//    var body: some View {
//        GeometryReader { geo in
//            let isWide = geo.size.width >= 700
//
//            HStack(spacing: 0) {
//                if isWide {
//                    // Permanent sidebar on wide screens
//                    SideMenuView(showMenu: .constant(true), selectedTab: $selectedTab)
//                        .frame(width: 260)
//                        .transition(.move(edge: .leading))
//                }
//
//                ZStack {
//                    // Main tabs (each tab is wrapped in a NavigationView so it has a nav bar)
//                    TabView(selection: $selectedTab) {
//
//                        NavigationView {
//                            HomeView()
//                                .navigationTitle("Home")
//                                .toolbar {
//                                    ToolbarItem(placement: .navigationBarLeading) {
//                                        // Only show hamburger on compact screens
//                                        if !isWide {
//                                            menuButton
//                                        }
//                                    }
//                                }
//                        }
//                        .tabItem {
//                            Label("Home", systemImage: "house")
//                        }
//                        .tag(0)
//
//                        NavigationView {
//                            AIAssistantView()
//                                .navigationTitle("AI Assistant")
//                                .toolbar {
//                                    ToolbarItem(placement: .navigationBarLeading) {
//                                        if !isWide { menuButton }
//                                    }
//                                }
//                        }
//                        .tabItem {
//                            Label("AI Assistant", systemImage: "sparkles")
//                        }
//                        .tag(1)
//
//                        NavigationView {
//                            HistoryView()
//                                .navigationTitle("History")
//                                .toolbar {
//                                    ToolbarItem(placement: .navigationBarLeading) {
//                                        if !isWide { menuButton }
//                                    }
//                                }
//                        }
//                        .tabItem {
//                            Label("History", systemImage: "clock.arrow.circlepath")
//                        }
//                        .tag(2)
//                    }
//                    .accentColor(.purple)
//
//                    // Overlay for slide-in menu on compact screens
//                    if !isWide {
//                        Color.black.opacity(showMenu ? 0.3 : 0)
//                            .ignoresSafeArea()
//                            .animation(.easeInOut, value: showMenu)
//                            .onTapGesture {
//                                withAnimation { showMenu = false }
//                            }
//
//                        HStack {
//                            if showMenu {
//                                SideMenuView(showMenu: $showMenu, selectedTab: $selectedTab)
//                                    .frame(width: 260)
//                                    .transition(.move(edge: .leading))
//                            }
//                            Spacer()
//                        }
//                        .animation(.easeInOut, value: showMenu)
//                    }
//                } // ZStack
//            } // HStack
//            .onAppear {
//                // always start on Home tab
//                selectedTab = 0
//            }
//        } // GeometryReader
//    }
//
//    private var menuButton: some View {
//        Button(action: {
//            withAnimation { showMenu.toggle() }
//        }) {
//            Image(systemName: "line.horizontal.3")
//                .imageScale(.large)
//                .foregroundColor(.purple)
//        }
//    }
//}

    
    
//struct MainAppView: View {
//    @EnvironmentObject var appState: AppState
//    @State private var sharedLinks: [String] = []
//    @State private var latestResult: [String: String] = [:]
//    @State private var lastProcessedLink: String?
//    @State private var showApiTest = false
//    
//    var body: some View {
//        
//        VStack(spacing: 24) {
//            if let user_name = appState.Username {
//                Text("👋 Welcome back \(user_name)")
//                    .font(.title2)
//            }
//            else{
//                Text("👋 Welcome back to")
//                    .font(.title2)
//            }
//            
//            
//            Text("einsteini.ai")
//                .font(.largeTitle)
//                .fontWeight(.bold)
//                .foregroundColor(.purple)
//            
//            if let email = appState.loggedInEmail {
//                Text("Logged in as: \(email)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//            
//            Group {
//                //                Text("📦 Subscription Status: \(appState.subscriptionStatus)")
//                //                    .font(.subheadline)
//                //                    .foregroundColor(.blue)
//                
//                Text("💬 Remaining Comments: \(appState.remainingComments)")
//                    .font(.subheadline)
//                    .foregroundColor(.green)
//            }
//            
//            Divider().padding(.horizontal)
//            
//            Text("History")
//                .font(.headline)
//            
//            if sharedLinks.isEmpty {
//                Text("No links shared yet.")
//                    .foregroundColor(.secondary)
//            } else {
//                // List of all shared links
//                Section(header: Text("Your Library")) {
//                    List(sharedLinks, id: \.self) { link in
//                        Text(link)
//                            .font(.footnote)
//                            .foregroundColor(.blue)
//                            .lineLimit(2)
//                    }
//                }
//                
//                // Latest API results (dictionary -> key/value list)
//                if !latestResult.isEmpty {
//                    Section(header: Text("Latest Results")) {
//                        List(latestResult.sorted(by: { $0.key < $1.key }), id: \.key) { tone, comment in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(tone)
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                                Text(comment)
//                                    .font(.footnote)
//                                    .foregroundColor(.blue)
//                                    .lineLimit(2)
//                            }
//                        }
//                    }
//                } else {
//                    Text("No processed results yet.")
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            
//            HStack {
//                Button("🔄 Load") {
//                    loadSharedLinks()
//                }
//                .padding()
//                .background(Color.blue.opacity(0.1))
//                .cornerRadius(8)
//                
//                Button("🗑 Clear") {
//                    clearSharedLinks()
//                }
//                .padding()
//                .background(Color.red.opacity(0.1))
//                .cornerRadius(8)
//            }
//            
//            Button("Log out") {
//                appState.logOut()
//            }
//            .foregroundColor(.red)
//            
//            Spacer()
//            
//            //            Text(try! AttributedString(markdown: "Login to Our Website [einsteini.ai](https://einsteini.ai) for subscription and other changes"))
//            //                .font(.subheadline)
//            //                .foregroundColor(.gray)
//        }
//        .padding()
//        .onAppear {
//            loadSharedLinks()
//            loadSubscriptionStatus()
//        }
//    }
//    
//    func loadSharedLinks() {
//        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
//            sharedDefaults.synchronize()
//            
//            // Load all links (history)
//            sharedLinks = sharedDefaults.stringArray(forKey: "SharedLinks") ?? []
//            print("✅ Accessed shared links: \(sharedLinks)")
//            
//            // Load last processed link
//            lastProcessedLink = sharedDefaults.string(forKey: "LastProcessedLink")
//            print("✅ Last processed link: \(lastProcessedLink ?? "nil")")
//            
//            // Load latest API results
//            if let results = sharedDefaults.dictionary(forKey: "LatestResult") as? [String: String] {
//                latestResult = results
//                print("✅ Latest API results: \(results)")
//            } else {
//                print("⚠️ No processed results found.")
//            }
//            
//        } else {
//            print("❌ Failed to access UserDefaults with app group")
//        }
//    }
//    
//    func clearSharedLinks() {
//        if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
//            sharedDefaults.synchronize()
//            sharedDefaults.removeObject(forKey: "SharedLinks")
//            sharedDefaults.removeObject(forKey: "LastProcessedLink")
//            sharedDefaults.removeObject(forKey: "LatestResult")
//            sharedLinks = []
//            lastProcessedLink = ""
//            latestResult = [:]
//        }
//    }
//    
//    func loadSubscriptionStatus() {
//        guard let email = appState.loggedInEmail else { return }
//        
//        ApiService.shared.getSubscriptionType(email: email) { status, error in
//            if let status = status {
//                DispatchQueue.main.async {
//                    appState.updateSubscriptionStatus(status)
//                }
//            }
//        }
//        
//        ApiService.shared.getRemainingComments(email: email) { count in
//            if let count = count {
//                DispatchQueue.main.async {
//                    appState.updateRemainingComments(count)
//                }
//            }
//        }
//    }
//}
    

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
