## Purpose
This file captures actionable, repository-specific guidance for AI coding agents working on LinkedInKeyboardWorkspace. Focus on the app+extensions architecture, integration points, data flows, and concrete patterns to avoid guesswork.

**Big Picture**
- **Mobile targets:** This repo contains an iOS companion app (`LinkedInCompanionApp`) plus two extensions: a custom keyboard (`LinkedInKeyboardExtension`) and a share extension (`LinkedInShareExtension`). Each target is intended to interoperate via an App Group.
- **Backend-driven content:** AI/comment generation is performed by calling a backend API at `https://backend.einsteini.ai/api` (see `LinkedInCommentGenerator.swift` and `ApiService.swift`). Many files assume the backend shape and endpoints (e.g. `/comment`, `/scrape`, `/summarize`).

**Communication & Shared State**
- App group identifier: `group.com.einstein.common`. Use this `suiteName` for `UserDefaults(suiteName:)` to share data between the app and extensions.
- Shared keys to watch for and use exactly as-is:
  - `AIRequest` / `AIResponse` — keyboard → companion worker handshake (see `AIWorker.swift`).
  - `SharedLinks`, `LastProcessedLink`, `LatestResult`, `LatestTone` — share extension stores processed links and results (see `LinkedInShareExtension/ShareViewController.swift`).
  - `userEmail`, `authToken`, `isLoggedIn`, `subscriptionStatus`, `remainingComments` — auth/subscription state (see `ApiService.swift`).

**Important Files & Patterns**
- `LinkedInCompanionApp/LinkedInCommentGenerator.swift` — canonical HTTP client / prompt builder used by the companion app.
- `LinkedInKeyboardExtension/LinkedInCommentGenerator.swift` and `LinkedInShareExtension/LinkedInCommentGenerator.swift` — copies/variants of the generator exist in each target. Changes to generation behavior or endpoints must be applied to all copies (or consolidated into a shared framework if you refactor).
- `LinkedInCompanionApp/AIWorker.swift` — background worker that reads `AIRequest` from app-group defaults, calls `LinkedInCommentGenerator`, and writes `AIResponse` back. Use this to implement any background orchestration between targets.
- `LinkedInKeyboardExtension/KeyboardViewController.swift` — UI + state: prompts, pickers, toggles. It contains the user-facing UX for generating comments and passes options (emoji/hashtag flags, language, tone) to the comment generator.
- `CreditPurchaseManager.swift` — StoreKit 2 usage example. Product identifier placeholder: `com.yourapp.credits300`.

**Backend & Networking Conventions**
- Base URLs and endpoints are hard-coded in generators and `ApiService`. Common constant: `https://backend.einsteini.ai/api`. When changing backend behavior update all generator copies and `ApiService`.
- HTTP bodies follow the backend's expected shape. Example body for comment requests (in `LinkedInCommentGenerator`):
  - `{"requestContext":{"httpMethod":"POST"}, "prompt":..., "email":...}`
- Many network calls assume quick JSON responses and return raw string payloads; error handling is lightweight and returns UI-facing emoji-prefixed messages (e.g. `❌`, `⚠️`). Preserve this UX style when editing.

**Project Conventions & Style**
- Inter-target duplication is intentional for ease of building separate binaries; expect repeated files across `LinkedInCompanionApp`, `LinkedInKeyboardExtension`, and `LinkedInShareExtension`.
- Use `UserDefaults(suiteName: "group.com.einstein.common")` for any shared state. Do not switch to different keys without updating every target.
- UI code in the keyboard uses programmatic Auto Layout and `UIStackView`-based layouts — match this style for consistency.

**Build / Run Notes (developer workflow)**
- Use Xcode (macOS) to build and run targets. Open `LinkedInCompanionApp.xcodeproj` and select scheme `LinkedInCompanionApp` or the respective extension scheme.
- To test keyboard extension interactions: install the app on a device or simulator, enable the custom keyboard in Settings, and grant "Full Access" if the keyboard needs network access.
- App Group: ensure `group.com.einstein.common` is enabled for the app and both extensions in the project entitlements (check `*.entitlements` files present in each target root).
- StoreKit testing: `CreditsStoreKit.storekit` and `Store_Plans.storekit` are included — use Xcode's StoreKit testing when running purchases in the simulator.

**What to change vs what to preserve**
- Change: backend `baseURL` values when migrating environments — update all generator files and `ApiService.swift`.
- Preserve: shared keys, app group ID, and the general request/response shapes expected by the backend.

**Common Tasks & Examples**
- To implement a new generator option in the keyboard UI: update `KeyboardViewController.swift` to collect the new option, and update `LinkedInKeyboardExtension/LinkedInCommentGenerator.swift` to encode it into the prompt/body. Mirror the backend shape used in `LinkedInCompanionApp/LinkedInCommentGenerator.swift`.
- To change where responses are delivered from the background worker: see `AIWorker.shared.processRequests()` — it reads `AIRequest` (dictionary with `link` and `tone`) and writes `AIResponse`.

**Files to inspect when debugging**
- `LinkedInCompanionApp/AIWorker.swift`
- `LinkedInCompanionApp/LinkedInCommentGenerator.swift`
- `LinkedInKeyboardExtension/KeyboardViewController.swift`
- `LinkedInKeyboardExtension/LinkedInCommentGenerator.swift`
- `LinkedInShareExtension/ShareViewController.swift`
- `LinkedInCompanionApp/ApiService.swift`
- `CreditPurchaseManager.swift`

If any piece of this guidance is unclear or you'd like the instructions to be expanded (for example, a recommended refactor to remove duplicated generators), tell me which section to expand and I'll iterate. 
