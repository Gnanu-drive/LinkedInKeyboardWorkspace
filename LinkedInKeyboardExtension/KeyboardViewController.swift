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
    let color: UIColor = .white
    
    // MARK: - Keyboard State
    enum KeyboardMode {
        case alphabet, numbers, symbols
    }
    var keyboardMode: KeyboardMode = .alphabet
    var isShiftEnabled = false
    var isCapsLock = false
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    // MARK: - Setup
    func setupKeyboard() {
        keyboardView = UIView()
        keyboardView.backgroundColor = UIColor.systemGray4
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
        for sub in keyboardView.subviews { sub.removeFromSuperview() }
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.distribution = .fillEqually

        for row in layoutForCurrentMode() {
            mainStack.addArrangedSubview(row)
        }
        mainStack.addArrangedSubview(bottomRow())

        keyboardView.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStack.leftAnchor.constraint(equalTo: keyboardView.leftAnchor, constant: 10),
            mainStack.rightAnchor.constraint(equalTo: keyboardView.rightAnchor, constant: -10),
            mainStack.topAnchor.constraint(equalTo: keyboardView.topAnchor, constant: 50),
            mainStack.bottomAnchor.constraint(equalTo: keyboardView.bottomAnchor, constant: -10)
        ])
    }
    
    func layoutForCurrentMode() -> [UIStackView] {
        switch keyboardMode {
        case .alphabet:
            let row1 = createKeyRow(["Q","W","E","R","T","Y","U","I","O","P"])
            let row2 = createKeyRow(["A","S","D","F","G","H","J","K","L"])
            let row3 = createKeyRow(["⇧","123","Z","X","C","V","B","N","M","⌫"])
            return [row1, row2, row3]
            
        case .numbers:
            let row1 = createKeyRow(["1","2","3","4","5","6","7","8","9","0"])
            let row2 = createKeyRow(["-","/",":",";","(",")","₹","&","@","\""])
            let row3 = createKeyRow(["#+=",".",",","?","!","⌫"])
            return [row1, row2, row3]
            
        case .symbols:
            let row1 = createKeyRow(["[","]","{","}","#","%","^","*","+","="])
            let row2 = createKeyRow(["_","\\","|","~","<",">","€","£","¥","•"])
            let row3 = createKeyRow(["ABC",".",",","?","!","⌫"])
            return [row1, row2, row3]
        }
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
        
        // Style
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        if letter == "⌫" {
            button.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)
        } else if letter == "⇧" {
            button.addTarget(self, action: #selector(shiftPressed(_:)), for: .touchUpInside)
        } else if letter == "123" {
            button.addTarget(self, action: #selector(switchToNumbers), for: .touchUpInside)
        } else if letter == "#+=" {
            button.addTarget(self, action: #selector(switchToSymbols), for: .touchUpInside)
        } else if letter == "ABC" {
            button.addTarget(self, action: #selector(switchToAlphabet), for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(letterPressed(_:)), for: .touchUpInside)
        }
        styleKeyButton(button)
        return button
    }

    func createSpecialButton(_ title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 20
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        styleKeyButton(button)
        return button
    }

    func bottomRow() -> UIStackView {
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 6
        row4.distribution = .fill
        
        let globeButton = createSpecialButton("🌐", color: .lightGray)
        globeButton.addTarget(self, action: #selector(backToSystemKeyboard), for: .touchUpInside)
        globeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        aiButton = createSpecialButton("🤖 AI", color: .purple)
        aiButton.addTarget(self, action: #selector(aiButtonPressed), for: .touchUpInside)
        aiButton.widthAnchor.constraint(equalToConstant: 70).isActive = true
        
        let spaceButton = createSpecialButton("space", color: .lightGray)
        spaceButton.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        
        let returnButton = createSpecialButton("⏎", color: .lightGray)
        returnButton.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        returnButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        row4.addArrangedSubview(globeButton)
        row4.addArrangedSubview(aiButton)
        row4.addArrangedSubview(spaceButton)
        row4.addArrangedSubview(returnButton)
        return row4
    }
    
    // MARK: - Shift / Caps
    @objc func shiftPressed(_ sender: UIButton) {
        if isShiftEnabled {
            // Double tap → Caps Lock
            isCapsLock = true
            isShiftEnabled = false
            sender.backgroundColor = .systemBlue
        } else if isCapsLock {
            // Turn off Caps
            isCapsLock = false
            sender.backgroundColor = .white
        } else {
            // Enable Shift
            isShiftEnabled = true
            isCapsLock = false
            sender.backgroundColor = .systemGray4
        }
        updateKeyLabels()
    }

    
    // MARK: - Keyboard Mode Switching
    @objc func switchToNumbers() { keyboardMode = .numbers; setupBasicKeys() }
    @objc func switchToSymbols() { keyboardMode = .symbols; setupBasicKeys() }
    @objc func switchToAlphabet() { keyboardMode = .alphabet; setupBasicKeys() }

    
    // MARK: - AI Toolbar
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
    
    @objc func aiButtonPressed() {
        isAIMode.toggle()
        aiToolbar.isHidden = !isAIMode
        if isAIMode {
            aiButton.backgroundColor = .purple
            aiButton.setTitle("🤖 ON", for: .normal)
            populateLinkedInButtons()
        } else {
            aiButton.backgroundColor = .systemPurple
            aiButton.setTitle("🤖 AI", for: .normal)
            clearAIToolbar()
        }
    }
    
    func populateLinkedInButtons() {
        clearAIToolbar()
        let suggestions = ["👏 Applaud", "👍🏽 Agree", "💬 Comment", "👀 Insight"]
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.tag = 999
        for s in suggestions {
            let b = UIButton(type: .system)
            b.setTitle(s, for: .normal)
            b.setTitleColor(.systemBlue, for: .normal)
            b.backgroundColor = .white
            b.layer.cornerRadius = 18
            b.layer.borderWidth = 3
            b.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            b.addTarget(self, action: #selector(AIPressed(_:)), for: .touchUpInside)
            stack.addArrangedSubview(b)
        }
        aiToolbar.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leftAnchor.constraint(equalTo: aiToolbar.leftAnchor, constant: 10),
            stack.rightAnchor.constraint(equalTo: aiToolbar.rightAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: aiToolbar.topAnchor, constant: 5),
            stack.bottomAnchor.constraint(equalTo: aiToolbar.bottomAnchor, constant: -5)
        ])
    }
    
    func clearAIToolbar() {
        for s in aiToolbar.subviews where s.tag == 999 {
            s.removeFromSuperview()
        }
    }
    
    
        @objc func AIPressed(_ sender: UIButton) {
            guard let title = sender.title(for: .normal) else { return }
    
            let tone = title
                .replacingOccurrences(of: "👏 ", with: "")
                .replacingOccurrences(of: "💬 ", with: "")
                .replacingOccurrences(of: "👍🏽 ", with: "")
                .replacingOccurrences(of: "👀 ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
    
            let defaults = UserDefaults(suiteName: "group.com.einstein.common")
            defaults?.synchronize()
    
            guard let _ = defaults?.string(forKey: "LastProcessedLink"),
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
            aiButtonPressed()
        }

    // MARK: - Key Actions
    @objc func letterPressed(_ sender: UIButton) {
        guard let letter = sender.title(for: .normal) else { return }
        var output = letter
        
        if isShiftEnabled && !isCapsLock {
            output = output.uppercased()
            isShiftEnabled = false // reset shift after one key
            updateKeyLabels()
        } else if isCapsLock {
            output = output.uppercased()
        } else {
            output = output.lowercased()
        }
        
        textDocumentProxy.insertText(output)
    }

    
    func updateKeyLabels() {
        for sub in keyboardView.subviews {
            if let mainStack = sub as? UIStackView {
                for case let row as UIStackView in mainStack.arrangedSubviews {
                    for case let button as UIButton in row.arrangedSubviews {
                        guard let title = button.title(for: .normal) else { continue }
                        
                        // Skip special keys
                        if ["⇧","⌫","space","⏎","🌐","🤖 AI","123","#+=","ABC"].contains(title) {
                            continue
                        }
                        
                        if isCapsLock || isShiftEnabled {
                            button.setTitle(title.uppercased(), for: .normal)
                        } else {
                            button.setTitle(title.lowercased(), for: .normal)
                        }
                    }
                }
            }
        }
    }

    
    @objc func spacePressed() { textDocumentProxy.insertText(" ") }
    @objc func deletePressed() { textDocumentProxy.deleteBackward() }
    @objc func returnPressed() { textDocumentProxy.insertText("\n") }
    @objc func backToSystemKeyboard() { advanceToNextInputMode() }
    
    func styleKeyButton(_ button: UIButton) {
        button.backgroundColor = .white
    
        let title = button.title(for: .normal)
        
        if "🤖 AI" == title { button.backgroundColor = .systemPurple}
        else
        if ["⇧","⌫","space","⏎","🌐","123","#+=","ABC"].contains(title) {
                button.backgroundColor = .systemGray3
        }
            
        button.layer.cornerRadius = 6   // rounded edges
        button.layer.masksToBounds = false   // 🔥 allow shadow outside bounds
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.clear.cgColor
        
        
        // stronger, thicker shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.3   // 0.3–0.5 looks natural (not too dark)
        button.layer.shadowOffset = CGSize(width: 0, height: 3)  // more depth
        button.layer.shadowRadius = 4      // blur spread
        
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // text style
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
    }

}
