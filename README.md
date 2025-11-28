# LinkedInKeyboardWorkspace

## 1. Project Overview & Architecture

### Application purpose
LinkedInKeyboardWorkspace provides a lightweight iOS companion app plus two extensions (a custom keyboard and a share extension) that let users quickly generate high-quality, AI-powered LinkedIn comments and short posts. The keyboard allows in-context generation (with toggles for emojis/hashtags, translate/personalize flows) while the share extension captures links and persists them to a shared store for later processing by the companion app.

### Architecture
Primary pattern: Lightweight MVC (View Controllers) + Service Layer

- UI surfaces (keyboard, share extension, companion app views) are implemented as view controllers (UIKit + a small SwiftUI `ContentView` exists in the companion target).
- Business logic and network interactions are decoupled into service/helper classes (notably `LinkedInCommentGenerator` and `ApiService`) that act as a simple service layer.
- This shape was chosen because each iOS target (app, keyboard extension, share extension) is a small, self-contained binary; using view controllers for UI and dedicated service classes for networking keeps cross-target duplication straightforward and isolates backend contract code.

### Code structure (high-level)
- LinkedInCompanionApp
  - LinkedInCommentGenerator.swift — primary generator used by the companion app.
  - ApiService.swift — auth, subscription, and generic POST helper.
  - AIWorker.swift — background worker that reads/writes app-group defaults handshake keys.
  - `ContentView.swift`, `DualDefaults.swift`, entitlements, assets, Info.plist, etc.
- LinkedInKeyboardExtension
  - KeyboardViewController.swift — custom keyboard UI, toggles, pickers, and generation flow.
  - LinkedInCommentGenerator.swift — copy of generator tailored for keyboard (mirrors API usage).
- LinkedInShareExtension
  - ShareViewController.swift — captures shared URL(s) and writes them into app-group defaults.
  - LinkedInCommentGenerator.swift — copy of generator used in share flows.
- Root files:
  - CreditPurchaseManager.swift — StoreKit 2 sample integration.
  - CreditsStoreKit.storekit, Store_Plans.storekit — StoreKit testing config.
  - LinkedInCompanionApp.xcodeproj — Xcode project.

Notes:
- The `LinkedInCommentGenerator` is intentionally duplicated per target (companion app, keyboard, share extension) to keep each target self-contained and buildable independently. Any change to generation logic or backend shape should be applied to all three copies unless you refactor to a shared framework.

---

## 2. Xcode Targets and Dependencies

### Targets (exact names and roles)
- LinkedInCompanionApp — Main companion app. Handles login, subscription state, background orchestration (`AIWorker`), and hosts the canonical `LinkedInCommentGenerator`.
- LinkedInKeyboardExtension — Custom keyboard extension. Provides the interactive UI for generating comments inside other apps; UI and UX are implemented in KeyboardViewController.swift.
- LinkedInShareExtension — Share extension. Captures shared links from the system share sheet and persists them into shared app group storage.
- LinkedInCompanionApp.xcodeproj — Xcode project file (contains schemes for the above targets).
- (No dedicated test target present in the repository snapshot.)

### External dependencies
- There are no third-party dependency managers (no `Package.swift`, no `Podfile`) in the visible workspace—project relies on system frameworks.
- Critical frameworks used (system frameworks):
  - `Foundation` — networking, JSON handling.
  - `UIKit` — keyboard and extension UI.
  - `StoreKit` — CreditPurchaseManager.swift for in-app purchases / StoreKit 2.
  - `UniformTypeIdentifiers` — used by the share extension to handle URLs.

---

## 3. Data Sharing & Inter-Process Communication (IPC)

This section documents how the app and its extensions exchange data and coordinate work.

### App Group
- App Group ID (exact):  
  ```
  group.com.einstein.common
  ```
- Purpose: central shared container for user defaults and shared state. All inter-target shared keys and persisted small data are stored under `UserDefaults(suiteName: "group.com.einstein.common")`.

### Shared storage locations & keys
- Shared persistence mechanism: Shared `UserDefaults` (app-group suite).
- Common keys to read/write (use exactly as coded):
  - `AIRequest` — (keyboard/extension → companion) dictionary with generation request properties (e.g., `["link": "<url>", "tone": "<tone>"]`).
  - `AIResponse` — (companion → keyboard/extension) generated comment string written back after processing.
  - `SharedLinks` — array of links collected by the share extension.
  - `LastProcessedLink` — last link saved/processed by share extension.
  - `LatestResult` — map-like storage for the most recent generation result (tone → comment).
  - `LatestTone` — tone associated with the `LatestResult`.
  - Authentication/subscription keys in standard `UserDefaults` (non-app-group or app-group depending on usage): `userEmail`, `authToken`, `isLoggedIn`, `subscriptionStatus`, `remainingComments`.

Example of reading/writing the shared defaults:
```swift
let defaults = UserDefaults(suiteName: "group.com.einstein.common")
defaults?.set("...", forKey: "AIResponse")
defaults?.synchronize()
```

### Communication flow (how components coordinate)
- Primary coordination is done via the shared `UserDefaults` app-group store.
  - The keyboard or share extension writes a request (e.g., `AIRequest`) into the app-group defaults.
  - The companion app runs `AIWorker.shared.processRequests()` which reads `AIRequest`, invokes `LinkedInCommentGenerator`, and writes `AIResponse` back to the same app-group defaults.
  - The extension/keyboard can then read `AIResponse` from the shared defaults.
- There is no explicit CFNotificationCenter or Darwin notifications usage in the current code; the code therefore depends on polling / explicit read-after-write semantics or the extension reading stored results when it resumes.
- The share extension writes captured links to `SharedLinks` and `LastProcessedLink` immediately, then dismisses.

Important discovery: the repo relies on this app-group `UserDefaults` handshake rather than direct IPC or a shared daemon. Any changes that alter keys or storage location must be mirrored across all targets.

---

## 4. Application Flow and Feature Walkthrough

### Main flow (user journey)
1. Install the main app and enable the custom keyboard in Settings (enable App Group entitlements).
2. Launch LinkedInCompanionApp:
   - If required, sign in via the companion app (auth flows are backed by `ApiService`).
   - Companion app maintains `userEmail` / `authToken` in `UserDefaults`.
3. Enable the custom keyboard (and optionally grant Full Access to allow network operations).
4. In any text field on the device:
   - Switch to LinkedInKeyboardExtension.
   - The keyboard shows a grid of prompt buttons (Applaud, Agree, Fun, Perspective, Question, Translate, Repost).
   - Tap a prompt → the keyboard collects context (post URL or content), optionally shows picker flows (Translate) or personalization, and triggers generation.
   - The keyboard writes `AIRequest` to the app-group defaults or directly calls its local `LinkedInCommentGenerator` copy depending on the flow; the companion app may process background requests and write `AIResponse` back.
5. Share extension flow:
   - From any app, open the share sheet on a LinkedIn post → choose the LinkedInShareExtension.
   - The extension captures the URL and saves it to `SharedLinks` and `LastProcessedLink` in app-group defaults for later processing or for the companion to pick up.

### Key features (screens & behavior)
- AI-Powered Comment Generation
  - Files: LinkedInCommentGenerator.swift (three copies), ApiService.swift.
  - Behavior: scrape `/scrape?url=...` endpoint then call `/comment` endpoint with prompt, returning raw string responses.
- Translate Flow (keyboard)
  - File: KeyboardViewController.swift
  - Behavior: Two pickers (language & comment type) and a `Go` button to request a translated comment. Hides main grid while active.
- Personalize / Tone Input (keyboard)
  - File: KeyboardViewController.swift
  - Behavior: UI for specifying tone and details, used to build a personalized prompt for the backend.
- Share collecting & quick copy (share extension)
  - File: ShareViewController.swift
  - Behavior: stores shared URLs into `SharedLinks`, sets `LastProcessedLink`, then dismisses quickly. Optionally can trigger comment generation (commented earlier in code).

### Backend contract notes
- Backend base URL (canonical in code): `https://backend.einsteini.ai/api`
- Endpoints used in the codebase:
  - `GET /scrape?url=...` — returns scraped post content/metadata.
  - `POST /comment` — takes `prompt`, `email`, `requestContext` and returns comment text.
  - `POST /summarize`, `/translate`, `/create-post`, `/create-repost`, `/create-about-me`, etc.
- Request body convention used widely:
```json
{
  "requestContext": { "httpMethod": "POST" },
  "prompt": "...",
  "email": "user@example.com"
}
```

---

## 5. User Experience (UX) and Design Philosophy

### Core value proposition
- Instantly generate high-quality, human-sounding LinkedIn comments and short posts without leaving the context where you're writing — enabling faster engagement and consistent professional voice.

### Design philosophy
- Minimal, focused, and task-oriented.
  - Keyboard UI emphasizes single-tap/low-friction actions: a small grid of prompt buttons, always-visible next-keyboard and delete buttons.
  - Use programmatic Auto Layout + `UIStackView` for predictable layouts across device sizes and to minimize storyboard complexity in extensions.
- Separation of concerns:
  - Keep UI controllers simple and delegate network/prompt logic to `LinkedInCommentGenerator` or `ApiService` so UIs remain responsive.

### Key interactions (what makes the UX unique)
- Prompt Grid: Tap once to select a comment tone — the keyboard then orchestrates further options (translate, personalize) in-place rather than switching context to the main app.
- Always-visible toggles: `Emojis` and `Hashtags` toggles are anchored within the keyboard UI so the user can quickly enable/disable them for any prompt.
- Translate & Personalize flows: modal-like in-keyboard pickers and inputs (two pickers for language & comment type) remove the need to leave the text entry surface.
- Share extension quick-capture: share sheet flow is minimal and fast — captures link(s) and stores them for later processing (the extension dismisses quickly to avoid blocking the user).
- StoreKit flows: CreditPurchaseManager.swift demonstrates StoreKit 2 integration for purchasing credits (used to gate comment generation in some subscription flows).

---

## Additional developer notes & quick start

### Quick start (open and run)
- Open the Xcode project in macOS:
  ```bash
  open LinkedInCompanionApp.xcodeproj
  ```
- Select the scheme for the target you want to run:
  - LinkedInCompanionApp to run the companion app.
  - Choose the extension scheme (keyboard or share) to debug extension UI with a host app or simulator.
- Entitlements:
  - Ensure `group.com.einstein.common` is added to each target's entitlements file.
  - If testing keyboard network features, enable "Full Access" in Settings for the keyboard on the simulator/device.
- StoreKit testing: open CreditsStoreKit.storekit in Xcode's StoreKit testing UI to simulate purchases.

### Files to inspect first when onboarding or debugging
- AIWorker.swift — worker that processes `AIRequest` and writes `AIResponse`.
- LinkedInCommentGenerator.swift — canonical prompt builder and API client.
- KeyboardViewController.swift — keyboard UI and prompt flows.
- LinkedInCommentGenerator.swift & LinkedInCommentGenerator.swift — per-target generator copies.
- ApiService.swift — auth, subscription, and generic POST helper.
- CreditPurchaseManager.swift — StoreKit 2 flow example.

