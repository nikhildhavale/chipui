---
name: project-chipui
description: "Overview of the ChipUI Swift library — what it is, how it's packaged, and its distribution setup"
metadata: 
  node_type: memory
  type: project
  originSessionId: f7117619-ccc7-4dd7-9d8c-ef84389cc0e2
---

ChipUI is a reusable UIKit component library for chip-style input with autocomplete, a configurable leading label, and optional trailing action buttons (Cc, settings).

**Main types:**
- `CountryChipInputView` — the main chip input view
- `ChipInputConfiguration` — configures label text and trailing buttons
- `ChipIcon` — SF Symbol (`.system`), text (`.title`), or unimplemented `.fontAwesome`

**Requirements:** iOS 16+, Swift 5.9+, UIKit

**Distribution:**
- Swift Package Manager — via repo URL, targets the `ChipUI` library product
- CocoaPods — `:git =>` only (no tag exists yet; omitting `:branch` defaults to the default branch)
- Repo: https://github.com/nikhildhavale/chipui.git
- No git tags exist as of 2026-06-05; if a `0.1.0` tag is created, the Podfile snippet can switch to `:tag => '0.1.0'`

**Key callbacks on `CountryChipInputView`:**
- `onAutocompleteChanged` — provides current filtered suggestions
- `onHeightChanged` — fires when the view resizes
- `toggleSuggestion(_:)` — adds/removes a suggestion
- `autocompleteAnchorFrame(in:)` — frame of input area in another view's coordinate space

**Packaging notes:**
- Sample app files in the Xcode project are excluded from SPM
- Default dataset uses `Locale.Region.isoRegions` names

**Why:** To track history of decisions made about README, packaging, and distribution so future sessions don't re-derive them.
**How to apply:** When asked about packaging, installation docs, or CocoaPods/SPM setup for this repo, start here before reading files.
