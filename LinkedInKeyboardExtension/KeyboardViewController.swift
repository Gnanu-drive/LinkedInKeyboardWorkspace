//
//  KeyboardViewController.swift
//  LinkedInKeyboardExtension
//
//  Created by Gnanendra Naidu N on 19/06/25.
//
import UIKit

class KeyboardViewController: UIInputViewController {
    
    // Our keyboard buttons and views
    var keyboardView: UIView!
    var aiButton: UIButton!
    var aiToolbar: UIView!
    var isAIMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }
    
    func setupKeyboard() {
        // Create main keyboard view
        keyboardView = UIView()
        keyboardView.backgroundColor = UIColor.systemGray6
        view.addSubview(keyboardView)
        
        // Set up constraints (this makes the keyboard fill the screen)
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
        // Create a simple keyboard with essential keys
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.distribution = .fillEqually
        
        // Row 1: Some letters
        let row1 = createKeyRow(["QQQ", "W", "E", "R", "T", "Y", "U", "I", "O", "P"])
        
        // Row 2: More letters
        let row2 = createKeyRow(["A", "S", "D", "F", "G", "H", "J", "K", "L"])
        
        // Row 3: Bottom letters
        let row3 = createKeyRow(["Z", "X", "C", "V", "B", "N", "M"])
        
        // Row 4: Special keys
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 8
        row4.distribution = .fillEqually
        
        // Create special buttons
        aiButton = createSpecialButton("🤖 AI", color: .systemBlue)
        aiButton.addTarget(self, action: #selector(aiButtonPressed), for: .touchUpInside)
        
        let spaceButton = createSpecialButton("space", color: .systemGray)
        spaceButton.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        
        let deleteButton = createSpecialButton("⌫", color: .systemRed)
        deleteButton.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
        
        // Add the "next keyboard" button (switches between keyboards)
//        let nextKeyboard = self.nextKeyboardButton
//        nextKeyboard.setTitle("🌐", for: .normal)
//        nextKeyboard.backgroundColor = .systemGray
//        nextKeyboard.layer.cornerRadius = 8
        
        row4.addArrangedSubview(aiButton)
        row4.addArrangedSubview(spaceButton)
        row4.addArrangedSubview(deleteButton)
//        row4.addArrangedSubview(nextKeyboard)
        
        // Add all rows to main stack
        mainStack.addArrangedSubview(row1)
        mainStack.addArrangedSubview(row2)
        mainStack.addArrangedSubview(row3)
        mainStack.addArrangedSubview(row4)
        
        keyboardView.addSubview(mainStack)
        
        // Position the keyboard
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: 10),
            mainStack.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -10),
            mainStack.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -10),
            mainStack.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 50) // Leave space for AI toolbar
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
        
        // When pressed, type the letter
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
        // Create AI suggestion toolbar (hidden by default)
        aiToolbar = UIView()
        aiToolbar.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        aiToolbar.layer.cornerRadius = 10
        aiToolbar.isHidden = true
        
        keyboardView.addSubview(aiToolbar)
        
        // Position toolbar at top
        aiToolbar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            aiToolbar.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: 10),
            aiToolbar.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -10),
            aiToolbar.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 10),
            aiToolbar.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add suggestion buttons
        let suggestionStack = UIStackView()
        suggestionStack.axis = .horizontal
        suggestionStack.spacing = 10
        suggestionStack.distribution = .fillEqually
        
        let suggestions = ["👍 Agree", "💡 Insight", "🤔 Question", "🔥 Great!"]
        
        for suggestion in suggestions {
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.setTitleColor(.systemBlue, for: .normal)
            button.backgroundColor = .white
            button.layer.cornerRadius = 15
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.addTarget(self, action: #selector(suggestionPressed(_:)), for: .touchUpInside)
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
    
    // MARK: - Button Actions
    
    @objc func letterPressed(_ sender: UIButton) {
        guard let letter = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(letter.lowercased())
    }
    
    @objc func aiButtonPressed() {
        isAIMode.toggle()
        aiToolbar.isHidden = !isAIMode
        
        // Change AI button color to show it's active
        if isAIMode {
            aiButton.backgroundColor = .systemGreen
            aiButton.setTitle("🤖 ON", for: .normal)
        } else {
            aiButton.backgroundColor = .systemBlue
            aiButton.setTitle("🤖 AI", for: .normal)
        }
    }
    
    @objc func spacePressed() {
        textDocumentProxy.insertText(" ")
    }
    
    @objc func deletePressed() {
        textDocumentProxy.deleteBackward()
    }
    
    @objc func suggestionPressed(_ sender: UIButton) {
        guard let suggestion = sender.title(for: .normal) else { return }
        
        // For MVP, we'll just insert pre-written responses
        let responses = [
            "👍 Agree": "I completely agree with your perspective on this!",
            "💡 Insight": "That's a great insight! I hadn't considered that angle before.",
            "🤔 Question": "Could you elaborate more on this point? I'd love to learn more.",
            "🔥 Great!": "This is absolutely fantastic! Thanks for sharing this valuable content."
        ]
        
        if let response = responses[suggestion] {
            textDocumentProxy.insertText(response)
        }
        
        // Hide AI toolbar after selection
        aiButtonPressed()
    }
}
