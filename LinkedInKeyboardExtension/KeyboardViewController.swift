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
        
        addBackToSystemKeyboardButton()
    }

    func addBackToSystemKeyboardButton() {
        let backButton = UIButton(type: .system)
        backButton.setTitle("🌐", for: .normal)   // Label it however you want
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.addTarget(self,
                             action: #selector(backToSystemKeyboard),
                             for: .touchUpInside)
        
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            backButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }

    @objc func backToSystemKeyboard() {
        self.advanceToNextInputMode()
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
    
    func addNextKeyboardButton() {
        let nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal) // looks like globe
        nextKeyboardButton.sizeToFit()
        
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        nextKeyboardButton.addTarget(self,
            action: #selector(handleInputModeList(from:with:)),
            for: .allTouchEvents)

        view.addSubview(nextKeyboardButton)
        
        // place it bottom left
        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
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

        let suggestions = ["👏 Applaud", "👍🏽 Agree", "💬 Comment", "👀 comment on  Insights"]

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
    
    
//    @objc func AIPressed(_ sender: UIButton) {
//        guard let title = sender.title(for: .normal) else { return }
//
//        let tone = title
//            .replacingOccurrences(of: "👏", with: "Applaud")
//            .replacingOccurrences(of: "💬", with: "Comment")
//            .replacingOccurrences(of: "👍🏽", with: "Agree")
//            .replacingOccurrences(of: "👀", with: "Insight")
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//
//        let defaults = UserDefaults(suiteName: "group.com.einstein.common")
//        let auth_token = defaults?.string(forKey: "userEmail")
//        guard let links = defaults?.stringArray(forKey: "SharedLinks"),
//              let lastLink = links.last else {
//            textDocumentProxy.insertText("❌ No link found.\n")
//            return
//        }
//
//        textDocumentProxy.insertText("🤖 Generating AI comment...\n")
//        let token: String
//        token = auth_token ?? "not found"
//        
//        let comment_generator = LinkedInCommentGenerator(authToken:token)
//        
//        comment_generator.generateAIComment(link: lastLink, tone: tone) { comment in
//            print(comment ?? "No comment generated.")
//            while self.textDocumentProxy.hasText {
//                self.textDocumentProxy.deleteBackward()
//            }
//            let rawResponse = (comment ?? "⚠️ Error from AI.")
//            var cleaned = rawResponse
//            
//            if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
//                    cleaned.removeFirst()
//                    cleaned.removeLast()
//                }
//
//                // Replace common escape sequences
//                cleaned = cleaned.replacingOccurrences(of: "\\n", with: " ")
//                                 .replacingOccurrences(of: "\\\"", with: " ")
//                                 .replacingOccurrences(of: "\\t", with: " ")
//                                 .replacingOccurrences(of: "\\\\", with: " ")
//            self.textDocumentProxy.insertText(cleaned)
//
//            self.toggleAIMode(show: false)
//        }
//        
//    }
    
    
    @objc func AIPressed(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }

        let tone = title
            .replacingOccurrences(of: "👏 ", with: "")
            .replacingOccurrences(of: "💬 ", with: "")
            .replacingOccurrences(of: "👍🏽 ", with: "")
            .replacingOccurrences(of: "👀 comment on  ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let defaults = UserDefaults(suiteName: "group.com.einstein.common")
        defaults?.synchronize()

        guard let lastLink = defaults?.string(forKey: "LastProcessedLink"),
              let results = defaults?.dictionary(forKey: "LatestResult") as? [String: String],
              let comment = results[tone] else {
            textDocumentProxy.insertText("❌ No processed result found.\n")
            return
        }

        // Clean + insert result
        var cleaned = comment
        if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") {
            cleaned.removeFirst()
            cleaned.removeLast()
        }
        cleaned = cleaned.replacingOccurrences(of: "\\n", with: " ")
                         .replacingOccurrences(of: "\\\"", with: " ")
                         .replacingOccurrences(of: "\\t", with: " ")
                         .replacingOccurrences(of: "\\\\", with: " ")

        while self.textDocumentProxy.hasText {
            self.textDocumentProxy.deleteBackward()
        }
        self.textDocumentProxy.insertText(cleaned)
        self.toggleAIMode(show: false)
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






