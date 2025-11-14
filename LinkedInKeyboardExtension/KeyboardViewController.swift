import UIKit

class KeyboardViewController: UIInputViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // MARK: - Prompts
//    let prompts = [" Applaud ", "Agree", "Fun", " Perspective ", "Question", "Translate", "Personalize"]
    let prompts = [" Applaud ", " Agree ", " Fun ", " Perspective ", " Question ", "Translate"]
    private var nextKeyboardButton: UIButton!
    
    
    // MARK: - Translate UI data
    private let languages = ["English", "Spanish", "French", "German", "Hindi", "Japanese"]
    private let commentTypes = [" Applaud ", " Agree ", " Fun ", " Perspective ", " Question "]
    
    // UI references
    private var mainStack: UIStackView!
    private var translateView: UIView?
    private var languagePicker: UIPickerView!
    private var typePicker: UIPickerView!
    private var goButton: UIButton?
    
    private var personalizeView: UIView?
    private var personalizeToneInput: UITextField?
    
    // Selected indices (default 0)
    private var selectedLanguageIndex = 0
    private var selectedTypeIndex = 0
    
    //emoji and hashtags
    private var emojisToggle: UIButton!
    private var hashtagsToggle: UIButton!

    // States
    private var isEmojisEnabled = false
    private var isHashtagsEnabled = false
    
    private func createToggleButton(title: String, isOn: Bool, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = isOn ? .systemPurple : .systemGray
        button.layer.cornerRadius = 12
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPromptKeyboard()
        setupNextKeyboardButton()
        setupAlwaysVisibleToggles()
    }
    
    
    
    private func setupAlwaysVisibleToggles() {
        // Container at top or bottom (choose your position)
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center
        container.distribution = .fillEqually
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        
        // Create toggles
        emojisToggle = createToggleButton(title: "Emojis", isOn: isEmojisEnabled, action: #selector(toggleEmojis))
        hashtagsToggle = createToggleButton(title: "Hashtags", isOn: isHashtagsEnabled, action: #selector(toggleHashtags))
        
        container.addArrangedSubview(emojisToggle)
        container.addArrangedSubview(hashtagsToggle)
        
        // Layout
        NSLayoutConstraint.activate([
                container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),  // right edge
                container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),     // bottom edge
                container.widthAnchor.constraint(equalToConstant: 150),                             // width of stack
                container.heightAnchor.constraint(equalToConstant: 50)                            // height of stack (2 buttons + spacing)
            ])
        
        view.bringSubviewToFront(container)
    }
    
    @objc private func toggleEmojis() {
        isEmojisEnabled.toggle()
        emojisToggle.backgroundColor = isEmojisEnabled ? .systemPurple : .systemGray
    }

    @objc private func toggleHashtags() {
        isHashtagsEnabled.toggle()
        hashtagsToggle.backgroundColor = isHashtagsEnabled ? .systemPurple : .systemGray
    }

    
    private func setControls(hidden: Bool) {
        emojisToggle.isHidden = hidden
        hashtagsToggle.isHidden = hidden
        nextKeyboardButton.isHidden = hidden
    }

    
    
    
    // MARK: - Main prompt grid
    private func setupPromptKeyboard() {
        // Remove everything except nextKeyboardButton (if previously added)
        view.subviews.forEach { $0.removeFromSuperview() }
        
        mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.alignment = .center
        mainStack.distribution = .fillEqually
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // build rows (2 rows x 3 columns)
        for row in stride(from: 0, to: prompts.count, by: 3) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually
            
            for i in row..<min(row + 3, prompts.count) {
                let button = createPromptButton(title: prompts[i])
                rowStack.addArrangedSubview(button)
            }
            mainStack.addArrangedSubview(rowStack)
        }
        
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 10),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    private func createPromptButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.systemPurple, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.systemPurple.cgColor
        button.layer.cornerRadius = 15
        button.backgroundColor = .clear
//        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        button.addTarget(self, action: #selector(promptTapped(_:)), for: .touchUpInside)
        return button
    }

    
    
    // MARK: - Globe (Next keyboard)
    private func setupNextKeyboardButton() {
        nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        view.addSubview(nextKeyboardButton)
        
        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Prompt tapped
    @objc private func promptTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        
        // Translated Comment -> show translate layout
        if title == "Translate" {
            showTranslateLayout()
            return
        }
        if title == "Personalize"{
            personalizeTapped()
            return
        }
        
        // normal prompt flow
        startGenerationForTone(tone: title, sender: sender)
    }
    
    // MARK: - Show translate layout (two pickers side-by-side + Back + Go)
    private func showTranslateLayout() {
        // Hide main grid
        mainStack.isHidden = true
        // Hide toggle buttons when showing Translate layout
        setControls(hidden: true)

        
        // Create translate view fresh
        translateView?.removeFromSuperview()
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        translateView = container
        
        // Language picker
        languagePicker = UIPickerView()
        languagePicker.delegate = self
        languagePicker.dataSource = self
        languagePicker.translatesAutoresizingMaskIntoConstraints = false
        languagePicker.selectRow(selectedLanguageIndex, inComponent: 0, animated: false)
        
        // Type picker
        typePicker = UIPickerView()
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.translatesAutoresizingMaskIntoConstraints = false
        typePicker.selectRow(selectedTypeIndex, inComponent: 0, animated: false)
        
        // Column stacks with label + picker
        let leftStack = UIStackView(arrangedSubviews: [makeLabel("Language"), languagePicker])
        leftStack.axis = .vertical
        leftStack.spacing = 8
        
        let rightStack = UIStackView(arrangedSubviews: [makeLabel("Comment Type"), typePicker])
        rightStack.axis = .vertical
        rightStack.spacing = 8
        
        let sideBySide = UIStackView(arrangedSubviews: [leftStack, rightStack])
        sideBySide.axis = .horizontal
        sideBySide.spacing = 12
        sideBySide.distribution = .fillEqually
        sideBySide.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        backButton.addTarget(self, action: #selector(backToMainMenu), for: .touchUpInside)
        
        let go = UIButton(type: .system)
        go.setTitle("Go", for: .normal)
        go.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        go.layer.cornerRadius = 12
        go.layer.borderWidth = 1
        go.layer.borderColor = UIColor.systemPurple.cgColor
//        go.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        go.addTarget(self, action: #selector(goPressed), for: .touchUpInside)
        go.translatesAutoresizingMaskIntoConstraints = false
        self.goButton = go

        
        let buttonRow = UIStackView(arrangedSubviews: [backButton, UIView(), go]) // spacer in middle
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.alignment = .center
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        
        // Vertical stack
        let vstack = UIStackView(arrangedSubviews: [sideBySide, buttonRow])
        vstack.axis = .vertical
        vstack.spacing = 16
        vstack.alignment = .fill
        vstack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(vstack)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            vstack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            vstack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            vstack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 12),
            vstack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -12),
            
            languagePicker.heightAnchor.constraint(equalToConstant: 120),
            typePicker.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Make sure the globe button stays on top
        view.bringSubviewToFront(nextKeyboardButton)
    }
    
    private func makeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        l.textAlignment = .center
        return l
    }
    
    @objc private func backToMainMenu() {
        
        translateView?.removeFromSuperview()
        translateView = nil
        mainStack.isHidden = false
        
        // Show toggle buttons again
        setControls(hidden: false)
    }
    
    // MARK: - Go pressed (start generation for translated comment)
    @objc private func goPressed(_ sender: UIButton) {
        // read picker selections
        clearKeyboardText()
        selectedLanguageIndex = languagePicker.selectedRow(inComponent: 0)
        selectedTypeIndex = typePicker.selectedRow(inComponent: 0)
        let language = languages[selectedLanguageIndex]
        let type = commentTypes[selectedTypeIndex]
        
        // nice human-facing tone for display & also pass machine-friendly tone to backend
        let displayTone = "Translated Comment — \(language) / \(type)"
        
        
        
        // show loading on go button
        sender.setTitle("…", for: .normal)
        sender.isEnabled = false
        
        // Begin same generation flow (sender passed so button will restore)
        startGenerationForTone(tone: type, sender: nil, displayMessage: displayTone, language: language)
        
        sender.setTitle("Go", for: .normal)
        sender.isEnabled = true
        
        
    }
    
    @objc private func personalizeTapped() {
        // 1. Hide main keyboard grid
        mainStack.isHidden = true
        
        // 2. Remove any existing personalize view
        personalizeView?.removeFromSuperview()
        
        // 3. Create container view
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        personalizeView = container
        
        // 4. Tone input
        let toneLabel = makeLabel("Tone")
        let toneInput = UITextField()
        toneInput.borderStyle = .roundedRect
        toneInput.placeholder = "Professional"
        
        // 5. Details box
        let detailsLabel = makeLabel("Details")
        let detailsBox = UITextView()
        detailsBox.isEditable = false
        detailsBox.text = """
        Pick a style — professional, casual, semi-formal, or technical —
        and einsteini will rewrite your message to sound just right.
        """
        detailsBox.font = UIFont.systemFont(ofSize: 14)
        detailsBox.layer.borderWidth = 1
        detailsBox.layer.borderColor = UIColor.systemGray.cgColor
        detailsBox.layer.cornerRadius = 8
        detailsBox.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        // 6. Buttons row
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.addTarget(self, action: #selector(backToMainMenu), for: .touchUpInside)
        
        let generateButton = UIButton(type: .system)
        generateButton.setTitle("Generate", for: .normal)
        generateButton.backgroundColor = .systemGreen
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.layer.cornerRadius = 12
        generateButton.addTarget(self, action: #selector(generatePersonalizedComment), for: .touchUpInside)
        
        let buttonsRow = UIStackView(arrangedSubviews: [backButton, UIView(), generateButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 12
        buttonsRow.alignment = .center
        
        // 7. Vertical stack
        let vStack = UIStackView(arrangedSubviews: [toneLabel, toneInput, detailsLabel, detailsBox, buttonsRow])
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.alignment = .fill
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(vStack)
        
        // 8. Layout constraints
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            vStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            vStack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        // Keep globe button on top
        view.bringSubviewToFront(nextKeyboardButton)
        
        // Optional: store reference to tone input for later
        personalizeToneInput = toneInput
    }
    
    @objc private func generatePersonalizedComment() {
        clearKeyboardText()
        
        // Get user input from tone field
        let tone = personalizeToneInput?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Professional"
        
        // Send to your existing generation function
        startGenerationForTone(
            tone: "Personalized - \(tone)",
            sender: nil,
            displayMessage: "Personalized — \(tone)"
        )
    }


    
    // MARK: - Generation core
    private func startGenerationForTone(tone: String, sender: UIButton?, displayMessage: String? = nil, language: String? = "English") {
        let originalTitle = sender?.currentTitle ?? nil
        
        // quick tap animation if a sender (visual)
        if let s = sender {
            UIView.animate(withDuration: 0.08, animations: { s.alpha = 0.5 }) { _ in UIView.animate(withDuration: 0.08) { s.alpha = 1.0 } }
            s.setTitle("…", for: .normal)
            s.isEnabled = false
        }
        
        // Clear current keyboard text and write "Generating comment for "TONE"..."
        clearKeyboardText()
        let display = displayMessage ?? tone
        textDocumentProxy.insertText("Generating comment for \"\(display)\"...")
        
        // retrieve last link (app and extension share app group)
        let defaults = UserDefaults(suiteName: "group.com.einstein.common")
        let link = defaults?.string(forKey: "LastProcessedLink") ?? ""
        
        let authToken = defaults?.string(forKey: "loggedInEmail") ?? "not_found"
        let commentGenerator = LinkedInCommentGenerator(authToken: authToken)
        
        commentGenerator.generateComment(url: link, tone: tone, includeEmoji: isEmojisEnabled, emojiText: nil, includeHashtag: isHashtagsEnabled, hashtagText: nil, language: language) { comment in
            DispatchQueue.main.async {
                if let comment = comment {
                    self.clearKeyboardText()
                    if let sharedDefaults = UserDefaults(suiteName: "group.com.einstein.common") {
                        sharedDefaults.set([tone: comment], forKey: "LatestResult")
                        sharedDefaults.set(link, forKey: "LastProcessedLink")
                        
//                         Clean comment: unescape, trim surrounding quotes
                        var cleaned = comment
                        cleaned = cleaned.replacingOccurrences(of: "\\n", with: " ")
                        cleaned = cleaned.replacingOccurrences(of: "\\\"", with: "\"")
                        cleaned = cleaned.replacingOccurrences(of: "\\t", with: " ")
                        cleaned = cleaned.replacingOccurrences(of: "\\\\", with: " ")
                        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
        
                        // Insert final comment
                        self.textDocumentProxy.insertText(cleaned + " ")
        
                        // Restore sender button (if any)
                        if let s = sender {
                            s.setTitle(originalTitle, for: .normal)
                            s.isEnabled = true
                        }
                    }
                }
            }
        }
        
 
        
    }
    
    // MARK: - Clear keyboard text (delete chars before cursor)
    
    private func clearKeyboardText() {
        if let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty {
            textDocumentProxy.deleteBackward()
            // Call recursively
            clearKeyboardText()
        }
    }

    
  
    
    // MARK: - UIPicker DataSource / Delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerView == languagePicker ? languages.count : commentTypes.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerView == languagePicker ? languages[row] : commentTypes[row]
    }
}

