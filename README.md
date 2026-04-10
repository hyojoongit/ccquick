<p align="center">
  <img src="icon/ccquick_logo.png" width="120" alt="CCQuick Logo" />
</p>

<h1 align="center">CCQuick</h1>

<p align="center">
  <strong>Claude Code, one shortcut away.</strong>
</p>

<p align="center">
  A native macOS menu bar app for instant access to Claude Code from anywhere.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2015+-black?style=flat-square" />
  <img src="https://img.shields.io/badge/swift-6.1-orange?style=flat-square" />
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" />
</p>

---

## What is CCQuick?

CCQuick lives in your menu bar and lets you launch [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in any project directory — instantly.

No more `cd`-ing around in terminals. Just press **Cmd + Shift + C**, pick a project, done.

## Features

**Launch**
- Global shortcut to summon a Spotlight-style launcher
- Browse or search your projects with fuzzy matching
- Pin favorites to the top
- Drag & drop folders onto the menu bar icon
- Right-click folders in Finder → "Open with Claude Code"

**Sessions**
- See all running Claude Code sessions at a glance
- Click to switch — focuses the exact terminal window
- Session count badge in the menu bar

**Customization**
- Choose your terminal: Terminal.app, iTerm2, or Warp
- Custom SF Symbol icons per project
- Configurable shortcut, scan directories, and more
- Auto-discovers git repos across your machine

## Install

### Homebrew (recommended)

```bash
brew tap hyojoongit/tap
brew install --cask hyojoongit/tap/ccquick
```

This installs CCQuick to `/Applications` and automatically removes the Gatekeeper quarantine flag.

To update later:

```bash
brew upgrade --cask ccquick
```

### Download

Grab the latest `.dmg` from [Releases](https://github.com/hyojoongit/ccquick/releases).

1. Open the DMG
2. Drag **CCQuick** to **Applications**
3. Run this in Terminal (one-time, removes Gatekeeper quarantine):
   ```bash
   xattr -cr /Applications/CCQuick.app
   ```
4. Open CCQuick from Applications

### Build from source

Requires macOS 15+ and Xcode Command Line Tools.

```bash
git clone https://github.com/hyojoongit/ccquick.git
cd ccquick
bash build.sh
open build/CCQuick.app
```

To create a distributable DMG:

```bash
bash dist.sh
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed (`brew install claude` or similar)
- macOS 15.0 or later
- Apple Silicon (arm64)

## Usage

1. **Cmd + Shift + C** — Opens the launcher
2. Type to search, arrow keys to navigate, Enter to open
3. Claude Code launches in your chosen terminal

The shortcut, terminal app, and scan directories are all configurable in **Settings** (menu bar icon → Settings).

## Project Structure

```
CCQuick/
├── App/                  # App entry point, AppDelegate
├── Models/               # Project data model
├── Persistence/          # ProjectStore, Preferences
├── Services/             # Hotkey, terminal launch, session tracking, git discovery
├── Utilities/            # Permissions, helpers
├── ViewModels/           # LauncherViewModel
├── Views/                # SwiftUI views, NSPanel, onboarding
├── Resources/            # Info.plist
icon/                     # Logo assets
build.sh                  # Build script
dist.sh                   # DMG packaging script
```

## License

MIT
