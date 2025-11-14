////
////  ShareViewController.swift
////  LinkedInShareExtension
////
//
//import UIKit
//import Social
//import UniformTypeIdentifiers
//
//class ShareViewController: UIViewController {
//    
//    let appGroupID = "group.com.einstein.common" // Your App Group
//    var sharedLink: String?
//    
//    // UI elements
//    private let toneSelector: UISegmentedControl = {
//        let tones = ["Applaud", "Comment", "Agree", "Insight"]
//        let sc = UISegmentedControl(items: tones)
//        sc.selectedSegmentIndex = UISegmentedControl.noSegment
//        sc.translatesAutoresizingMaskIntoConstraints = false
//        return sc
//    }()
//    
//    private let resultTextView: UITextView = {
//        let tv = UITextView()
//        tv.font = UIFont.systemFont(ofSize: 16)
//        tv.isEditable = false
//        tv.layer.borderColor = UIColor.lightGray.cgColor
//        tv.layer.borderWidth = 1
//        tv.layer.cornerRadius = 8
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        return tv
//    }()
//    
//    private let copyButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setTitle("Copy & Done", for: .normal)
//        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        btn.backgroundColor = UIColor.systemBlue
//        btn.setTitleColor(.white, for: .normal)
//        btn.layer.cornerRadius = 8
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.backgroundColor = .systemBackground
//        setupUI()
//        loadSharedLink()
//    }
//    private func saveSharedLink(_ link: String) {
//            print("Saving link: \(link)")
//            if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
//                var existing = sharedDefaults.stringArray(forKey: "SharedLinks") ?? []
//                existing.append(link)
//                sharedDefaults.set(existing, forKey: "SharedLinks")
//                sharedDefaults.synchronize()
//                print("Link saved to shared defaults, \(existing)")
//    
//            } else {
//                print("Failed to access UserDefaults with app group")
//            }
//        }
//    
//    
//    private func setupUI() {
//        view.addSubview(toneSelector)
//        view.addSubview(resultTextView)
//        view.addSubview(copyButton)
//        
//        toneSelector.addTarget(self, action: #selector(toneChanged(_:)), for: .valueChanged)
//        copyButton.addTarget(self, action: #selector(copyAndDone), for: .touchUpInside)
//        
//        NSLayoutConstraint.activate([
//            toneSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
//            toneSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
//            toneSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
//            
//            resultTextView.topAnchor.constraint(equalTo: toneSelector.bottomAnchor, constant: 12),
//            resultTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
//            resultTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
//            resultTextView.heightAnchor.constraint(equalToConstant: 150),
//            
//            copyButton.topAnchor.constraint(equalTo: resultTextView.bottomAnchor, constant: 12),
//            copyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            copyButton.widthAnchor.constraint(equalToConstant: 160),
//            copyButton.heightAnchor.constraint(equalToConstant: 44)
//        ])
//    }
//    
//    private func loadSharedLink() {
//        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem {
//            if let attachments = extensionItem.attachments {
//                for provider in attachments {
//                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
//                        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
//                            if let url = item as? URL {
//                                DispatchQueue.main.async {
//                                    self.sharedLink = url.absoluteString
//                                }
//                            }
//                        }
//                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
//                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
//                            if let text = item as? String {
//                                DispatchQueue.main.async {
//                                    self.sharedLink = text
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    @objc private func toneChanged(_ sender: UISegmentedControl) {
//        guard let link = sharedLink else {
//            resultTextView.text = "❌ No link found."
//            return
//        }
//        
//        let tones = ["Applaud", "Comment", "Agree", "Insight"]
//        let selectedTone = tones[sender.selectedSegmentIndex]
//        
//        resultTextView.text = "⏳ Generating comment for \(selectedTone)..."
//        generateForTone(selectedTone, link: link)
//    }
//    
//    private func generateForTone(_ tone: String, link: String) {
//        let defaults = UserDefaults(suiteName: appGroupID)
//        let authToken = defaults?.string(forKey: "userEmail") ?? "not_found"
//
//        let commentGenerator = LinkedInCommentGenerator(authToken: authToken)
//
//        commentGenerator.generateAIComment(link: link, tone: tone) { comment in
//            DispatchQueue.main.async {
//                if let comment = comment {
//                    self.resultTextView.text = comment
//                    if let sharedDefaults = UserDefaults(suiteName: self.appGroupID) {
//                        sharedDefaults.set([tone:comment], forKey: "LatestResult")
//                        sharedDefaults.set(tone, forKey: "LatestTone")
//                        sharedDefaults.set(link, forKey: "LastProcessedLink")
//                        self.saveSharedLink(link)
//                        
//                        sharedDefaults.synchronize()
//                    }
//                } else {
//                    self.resultTextView.text = "⚠️ Error generating comment."
//                }
//            }
//        }
//    }
//
//    
//    @objc private func copyAndDone() {
//        UIPasteboard.general.string = resultTextView.text
//        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
//    }
//}

//
//  ShareViewController.swift
//  LinkedInShareExtension
//
//  Created by Gnanendra Naidu N on 19/06/25.
//  simplified: only capture shared link and store it in app group defaults
import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    private let appGroupID = "group.com.einstein.common"

    override func viewDidLoad() {
        super.viewDidLoad()
        handleShare()
    }

    private func handleShare() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        for item in items {
            if let attachments = item.attachments {
                for attachment in attachments {
                    if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (data, error) in
                            if let url = data as? URL {
                                self.saveLink(url.absoluteString)
                            } else if let s = data as? String, let url = URL(string: s) {
                                self.saveLink(url.absoluteString)
                            }

                            // ✅ Force quick dismissal (within 0.3s)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.close()
                            }
                        }
                        return
                    }
                }
            }
        }
        close()
    }

    private func saveLink(_ link: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        var list = defaults.stringArray(forKey: "SharedLinks") ?? []
        list.append(link)
        defaults.set(list, forKey: "SharedLinks")
        defaults.set(link, forKey: "LastProcessedLink")
    }

    private func close() {
        self.extensionContext?.completeRequest(returningItems: nil)
    }
}
