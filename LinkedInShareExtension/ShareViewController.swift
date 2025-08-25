//
//  ShareViewController.swift
//  LinkedInShareExtension
//
//  Created by Gnanendra Naidu N on 19/06/25.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    let appGroupID = "group.com.einstein.common" // Your App Group

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = extensionItem.attachments {
                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
//                        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
//                            if let url = item as? URL {
//                                self.saveSharedLink(url.absoluteString)
//                            }
//                        }
                        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
                            if let url = item as? URL {
                                DispatchQueue.main.async {
                                    self.saveSharedLink(url.absoluteString)
                                }
                            }
                        }

                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
//                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
//                            if let text = item as? String {
//                                self.saveSharedLink(text)
//                            }
//                        }
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
                            if let text = item as? String {
                                DispatchQueue.main.async {
                                    self.saveSharedLink(text)
                                }
                            }
                        }

                    }
                }
            }
        }
    }

    func saveSharedLink(_ link: String) {
        print("Saving link: \(link)")
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            var existing = sharedDefaults.stringArray(forKey: "SharedLinks") ?? []
            existing.append(link)
            sharedDefaults.set(existing, forKey: "SharedLinks")
            sharedDefaults.synchronize()
            print("Link saved to shared defaults, \(existing)")

            // 🚀 Trigger API calls right after saving
            self.processLatestLink(link)

        } else {
            print("Failed to access UserDefaults with app group")
        }
    }

    /// Fire API calls for the latest shared link
    private func processLatestLink(_ link: String) {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.synchronize()
        let authToken = defaults?.string(forKey: "userEmail") ?? "not_found"

        let commentGenerator = LinkedInCommentGenerator(authToken: authToken)

        // Example: run all 4 tones in sequence
        let tones = ["Applaud", "Comment", "Agree", "Insight"]
        var results: [String: String] = [:]

        let group = DispatchGroup()

        for tone in tones {
            group.enter()
            commentGenerator.generateAIComment(link: link, tone: tone) { comment in
                results[tone] = comment ?? "⚠️ Error"
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("✅ All API calls finished: \(results)")
            // Save results back to shared defaults
            if let sharedDefaults = UserDefaults(suiteName: self.appGroupID) {
                sharedDefaults.set(results, forKey: "LatestResult")
                sharedDefaults.set(link, forKey: "LastProcessedLink")
                sharedDefaults.synchronize()
                print("Results saved to App Group")
            }
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }


    override func configurationItems() -> [Any]! {
        return []
    }
}

