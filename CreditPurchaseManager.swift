//
//  CreditPurchaseManager.swift
//  LinkedInCompanionApp
//
//  Created by Gnanendra Naidu N on 28/10/25.
//


import StoreKit

@MainActor
class CreditPurchaseManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isProcessing = false

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ["com.yourapp.credits300"])
            products = storeProducts
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    func purchaseCredits() async {
        guard let product = products.first else { return }
        isProcessing = true

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Payment succeeded ✅
                    await handleSuccessfulPurchase(transaction)
                    await transaction.finish()
                case .unverified(_, let error):
                    print("⚠️ Unverified transaction: \(error)")
                }
            case .userCancelled:
                print("❌ User cancelled purchase")
            default:
                break
            }
        } catch {
            print("❌ Purchase failed: \(error)")
        }
        isProcessing = false
    }

    private func handleSuccessfulPurchase(_ transaction: Transaction) async {
        // ✅ Call your backend function here
        await callBackendToAddCredits()
    }

    private func callBackendToAddCredits() async {
        guard let url = URL(string: "https://yourbackend.com/api/ABC") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // If needed, include user identifier
        let payload: [String: Any] = ["user_id": "USER_ID_HERE", "credits": 300]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Credits successfully added to backend.")
            } else {
                print("⚠️ Backend call failed.")
            }
        } catch {
            print("❌ Network error: \(error)")
        }
    }
}
