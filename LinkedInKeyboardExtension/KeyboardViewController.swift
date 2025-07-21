//
//  KeyboardViewController.swift
//  LinkedInKeyboardExtension
//
//  Created by Gnanendra Naidu N on 19/06/25.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    var keyboardView: UIView!
    var aiButton: UIButton!
    var aiToolbar: UIView!
    var isAIMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    // MARK: - Setup
    func setupKeyboard() {
        keyboardView = UIView()
        keyboardView.backgroundColor = UIColor.systemGray6
        view.addSubview(keyboardView)
        
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: view.leftAnchor),
            keyboardView.rightAnchor.constraint(equalTo: view.rightAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupBasicKeys()
        setupAIToolbar()
    }

    func setupBasicKeys() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.distribution = .fillEqually

        let row1 = createKeyRow(["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
        let row2 = createKeyRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"])
        let row3 = createKeyRow(["Z", "X", "C", "V", "B", "N", "M"])
        
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 8
        row4.distribution = .fillEqually

        aiButton = createSpecialButton("🤖 AI", color: .systemBlue)
        aiButton.addTarget(self, action: #selector(aiButtonPressed), for: .touchUpInside)

        let spaceButton = createSpecialButton("space", color: .systemGray)
        spaceButton.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)

        let deleteButton = createSpecialButton("⌫", color: .systemRed)
        deleteButton.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)

        row4.addArrangedSubview(aiButton)
        row4.addArrangedSubview(spaceButton)
        row4.addArrangedSubview(deleteButton)

        mainStack.addArrangedSubview(row1)
        mainStack.addArrangedSubview(row2)
        mainStack.addArrangedSubview(row3)
        mainStack.addArrangedSubview(row4)

        keyboardView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: 10),
            mainStack.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -10),
            mainStack.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 50),
            mainStack.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -10)
        ])
    }

    func createKeyRow(_ letters: [String]) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fillEqually

        for letter in letters {
            let button = createLetterButton(letter)
            stackView.addArrangedSubview(button)
        }

        return stackView
    }

    func createLetterButton(_ letter: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(letter, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.addTarget(self, action: #selector(letterPressed(_:)), for: .touchUpInside)
        return button
    }

    func createSpecialButton(_ title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 8
        return button
    }

    func setupAIToolbar() {
        aiToolbar = UIView()
        aiToolbar.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        aiToolbar.layer.cornerRadius = 10
        aiToolbar.isHidden = true

        keyboardView.addSubview(aiToolbar)
        aiToolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            aiToolbar.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: 10),
            aiToolbar.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -10),
            aiToolbar.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 10),
            aiToolbar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - AI Button Action

    @objc func aiButtonPressed() {
        isAIMode.toggle()
        aiToolbar.isHidden = !isAIMode

        if isAIMode {
            aiButton.backgroundColor = .systemGreen
            aiButton.setTitle("🤖 ON", for: .normal)
            populateLinkedInButtons()
        } else {
            aiButton.backgroundColor = .systemBlue
            aiButton.setTitle("🤖 AI", for: .normal)
            clearAIToolbar()
        }
    }


    func toggleAIMode(show: Bool) {
        isAIMode = show
        aiToolbar.isHidden = !show

        if show {
            aiButton.backgroundColor = .systemGreen
            aiButton.setTitle("🤖 ON", for: .normal)
            populateLinkedInButtons()
        } else {
            aiButton.backgroundColor = .systemBlue
            aiButton.setTitle("🤖 AI", for: .normal)
            clearAIToolbar()
        }
    }

    func populateLinkedInButtons() {
        clearAIToolbar()

        let suggestions = ["👏 Applaud", "👍🏽 agree", "💬 Comment", "👀 comment on  Insights"]

        let suggestionStack = UIStackView()
        suggestionStack.axis = .horizontal
        suggestionStack.spacing = 10
        suggestionStack.distribution = .fillEqually
        suggestionStack.tag = 999  // So we can remove later

        for title in suggestions {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.systemPurple, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 15
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.addTarget(self, action: #selector(AIPressed(_:)), for: .touchUpInside)
            suggestionStack.addArrangedSubview(button)
        }

        aiToolbar.addSubview(suggestionStack)

        suggestionStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionStack.leftAnchor.constraint(equalTo: aiToolbar.leftAnchor, constant: 10),
            suggestionStack.rightAnchor.constraint(equalTo: aiToolbar.rightAnchor, constant: -10),
            suggestionStack.topAnchor.constraint(equalTo: aiToolbar.topAnchor, constant: 5),
            suggestionStack.bottomAnchor.constraint(equalTo: aiToolbar.bottomAnchor, constant: -5)
        ])
    }

    func clearAIToolbar() {
        for subview in aiToolbar.subviews {
            if subview.tag == 999 {
                subview.removeFromSuperview()
            }
        }
    }
    
    
    
    func generateAIComment(link: String, tone: String, completion: @escaping (String?) -> Void) {
        let apiKey = ProcessInfo.processInfo.environment["GROQ_API_KEY"] ?? ""
        print(apiKey)
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        print(url)
        print(apiKey)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        You are a LinkedIn Expert and have broad expertise.
        This is the post link: "\(link)"
        Understand the post like an expert and read images if available.
        Generate a professional comment to the post in the "\(tone)" tone.
        ONLY RESPOND WITH A COMMENT.
        """

        let body: [String: Any] = [
            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 1,
            "top_p": 1,
            "max_tokens": 512,
            "stream": false // We don't stream here
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion("❌ Failed to encode request.")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion("❌ Network error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                completion("❌ No data received.")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: String],
                   let content = message["content"] {
                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    completion("❌ Unexpected response.\(body)this is the api key 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")
                }
            } catch {
                completion("❌ Failed to parse JSON.")
            }

        }.resume()
    }

    @objc func AIPressed(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }

        let tone = title
            .replacingOccurrences(of: "👏", with: "Applaud")
            .replacingOccurrences(of: "💬", with: "Comment")
            .replacingOccurrences(of: "👍🏽", with: "Agree")
            .replacingOccurrences(of: "👀", with: "Insight")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let defaults = UserDefaults(suiteName: "group.com.einstein.common")
        guard let links = defaults?.stringArray(forKey: "SharedLinks"),
              let lastLink = links.last else {
            textDocumentProxy.insertText("❌ No link found.\n")
            return
        }

        textDocumentProxy.insertText("🤖 Generating AI comment...\n")

        generateAIComment(link: lastLink, tone: tone) { aiReply in
            DispatchQueue.main.async {
                // Clear existing text and insert new content
                while self.textDocumentProxy.hasText {
                    self.textDocumentProxy.deleteBackward()
                }
                let clearResponse = (aiReply ?? "⚠️ Error from AI.").trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                self.textDocumentProxy.insertText(clearResponse)

                self.toggleAIMode(show: false)
            }
        }
    }


    // MARK: - Other Keyboard Actions

    @objc func letterPressed(_ sender: UIButton) {
        guard let letter = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(letter.lowercased())
    }

    @objc func spacePressed() {
        textDocumentProxy.insertText(" ")
    }

    @objc func deletePressed() {
        textDocumentProxy.deleteBackward()
    }
}

