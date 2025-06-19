//
//  ContentView.swift
//  LinkedInCompanionApp
//
//  Created by Gnanendra Naidu N on 19/06/25.
//
import SwiftUI

struct ContentView: View {
    @State private var apiKey: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // App Icon
            Image(systemName: "keyboard")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Title
            Text("LinkedIn AI Keyboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Description
            Text("Add smart AI responses to your LinkedIn conversations")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Setup Steps
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("1.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Enter your OpenAI API Key below")
                }
                
                HStack {
                    Text("2.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Go to Settings → Keyboards → Add Keyboard")
                }
                
                HStack {
                    Text("3.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Select 'LinkedInKeyboard' and enable it")
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // API Key Input
            VStack(spacing: 15) {
                SecureField("Paste your OpenAI API Key here", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Save API Key") {
                    if apiKey.isEmpty {
                        alertMessage = "Please enter an API key"
                        showAlert = true
                    } else {
                        saveAPIKey(apiKey)
                        alertMessage = "API Key saved successfully!"
                        showAlert = true
                        apiKey = ""
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
                
                Button("Open iPhone Settings") {
                    openSettings()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .alert("Notice", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // Save API key to UserDefaults (simple storage)
    func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    // Open iPhone Settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
