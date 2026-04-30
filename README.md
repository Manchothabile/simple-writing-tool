# Simple Writing Tool

A minimal, distraction-free text editor for macOS with an optional AI writing assistant powered by Claude (Anthropic).

![macOS](https://img.shields.io/badge/macOS-13%2B-black) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![Version](https://img.shields.io/badge/version-0.1.0-blue)

---

## Features

**Editor**
- Clean white writing surface — nothing in the way
- Rich text formatting: bold, italic, underline, font, size, color, alignment
- Paragraph cleanup button (¶) — removes trailing spaces and extra blank lines
- Unsaved changes indicator in the title bar

**File management**
- Open and save `.txt`, `.rtf`, `.docx` files
- New / Open / Save As from the toolbar

**AI writing assistant** *(optional — requires an Anthropic API key)*
- 7 one-click actions on selected text or the full document:
  - **Corriger** — spell and grammar check
  - **Reformuler** — rephrase while keeping the meaning
  - **Continuer** — continue the text naturally, respecting the narrative if it's fiction
  - **Résumer** — produce a concise summary
  - **Proposer** — suggest an alternative formulation
  - **Raccourcir** — condense by ~40%
  - **Formater** — restructure into well-formed paragraphs
- **Free prompt** — send any custom instruction (translate, change tone, etc.)
- **Prompt history** — revert to the document state before any AI action
- Modified text is briefly highlighted in yellow after each AI action
- API key stored securely in the macOS Keychain (never in any file)

---

## Installation

### Download (recommended)

1. Go to the [Releases](../../releases) page
2. Download `Simple Writing Tool.zip` from the latest release
3. Unzip and move `Simple Writing Tool.app` to your Applications folder
4. **Right-click → Open** the first time (required because the app is not notarized by Apple)

> After the first launch, double-click works normally.

### Build from source

Requirements: macOS 13+, Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
git clone https://github.com/Manchothabile/simple-writing-tool.git
cd simple-writing-tool
xcodegen generate
open MacTextEditor.xcodeproj
```

Then **Product → Run** in Xcode.

---

## AI Setup

The AI panel is off by default. To enable it:

1. Click the **✦ sparkle button** in the top-right of the toolbar
2. Enter your [Anthropic API key](https://console.anthropic.com/) in the field at the top of the panel
3. The key is saved in your macOS Keychain — you only need to enter it once

The app uses **Claude Haiku** (`claude-haiku-4-5`), the fastest and most affordable Claude model. Typical cost: a fraction of a cent per action.

---

## Usage tips

- **Select text first** before clicking an AI action to apply it to the selection only. Without a selection, the action applies to the entire document.
- **Continuer** works best with a few sentences of context — the AI will extend the narrative, not give advice.
- **¶ Nettoyer** in the toolbar is a fast, offline cleanup: collapses 3+ blank lines and strips trailing spaces. Use it before **Formater** (AI) for best results.
- **Revert an AI action** anytime via the history list at the bottom of the AI panel.

---

## Tech stack

- Swift / SwiftUI (macOS 13+)
- AppKit `NSTextView` for rich text editing
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) for `.docx` export
- Anthropic Messages API (`claude-haiku-4-5-20251001`)
- macOS Keychain for API key storage

---

## Releasing a new version

Tag the commit and push — GitHub Actions builds and publishes the release automatically:

```bash
git tag v0.2.0
git push origin v0.2.0
```

---

## License

MIT
