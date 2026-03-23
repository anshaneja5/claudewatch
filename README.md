# ClaudeWatch

A macOS menu bar app that tracks your [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI usage — sessions, tokens, costs, and rate limits — all at a glance.

![ClaudeWatch Screenshot](https://img.shields.io/badge/platform-macOS%2014+-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Today's Stats** — Cost, sessions, messages, and token breakdown (input/output/cache)
- **All-Time Overview** — Total cost, sessions, active days, average spend, model breakdown
- **Per-Project Costs** — See which projects cost the most with visual bars
- **Cost Trends** — 7-day line chart + 30-day daily history
- **Rate Limits** — Live 5-hour and 7-day usage percentages
- **Auto-Sync** — Watches `~/.claude/` for changes and updates automatically
- **Token Breakdown** — Input, output, cache write, cache read with colored bars

## How It Works

Claude Code stores session data as JSONL files in `~/.claude/projects/`. ClaudeWatch parses these files, calculates costs using Anthropic's pricing, and displays everything in a compact menu bar popover.

**Data stays local** — nothing is sent anywhere. The app only reads files from your `~/.claude/` directory.

## Install

### Option 1: Homebrew (Recommended)

```bash
brew tap anshaneja5/tap
brew install --cask claudewatch
```

> **Note:** On first launch, macOS may show a Gatekeeper warning since the app is not notarized. Go to **System Settings → Privacy & Security → "Open Anyway"** to allow it. This is a one-time step.

### Option 2: Build from Source

**Requirements:** macOS 14+, Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
# Clone the repo
git clone https://github.com/anshaneja5/claudewatch.git
cd claudewatch

# Install xcodegen if needed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open ClaudeWatch.xcodeproj
```

Then in Xcode:
1. Select the **ClaudeWatchMac** scheme
2. Set your **Team** in Signing & Capabilities
3. Hit **Cmd+R** to build and run

### Option 3: Download from Releases

Download the latest `.zip` from [Releases](https://github.com/anshaneja5/claudewatch/releases), unzip, and drag to `/Applications/`.

> **Note:** On first launch, macOS may show a Gatekeeper warning since the app is not notarized. Click **Done**, then go to **System Settings → Privacy & Security**, scroll down, and click **"Open Anyway"**. This is a one-time step.

## Usage

Once running, click the 🧠 brain icon in your menu bar. The app has 4 tabs:

| Tab | What it shows |
|-----|--------------|
| **Today** | Today's cost, sessions, messages, tokens, rate limits, recent sessions |
| **All Time** | Lifetime stats, model breakdown (Opus/Sonnet/Haiku), token breakdown |
| **Projects** | Per-project cost ranking with visual bars |
| **Trends** | 7-day cost chart, daily averages, 30-day history |

## Cost Calculation

ClaudeWatch uses Anthropic's published pricing (per million tokens):

| Model | Input | Output | Cache Write | Cache Read |
|-------|-------|--------|-------------|------------|
| Opus | $15.00 | $75.00 | $18.75 | $1.50 |
| Sonnet | $3.00 | $15.00 | $3.75 | $0.30 |
| Haiku | $0.80 | $4.00 | $1.00 | $0.08 |

## Tech Stack

- **SwiftUI** — UI framework
- **SwiftData** — Local persistence
- **Swift Charts** — Cost trend visualization
- **XcodeGen** — Project generation from YAML

## Project Structure

```
ClaudeWatch/
├── project.yml              # xcodegen configuration
├── Shared/
│   ├── Models/              # SwiftData models
│   └── Services/            # JSONL parser, cost calculator, data service
├── MacApp/
│   ├── Views/               # Menu bar UI
│   └── Services/            # File watcher, sync service
└── WatchApp/                # watchOS app (requires paid dev account)
```

## Contributing

PRs welcome! If you find a bug or want a feature, open an issue.

## License

MIT
