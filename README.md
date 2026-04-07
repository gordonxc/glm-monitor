# GLM Monitor

A native macOS menu bar app that monitors [Z.ai](https://z.ai) (GLM Coding Plan) usage quotas in real-time.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)

## Features

- **Session token usage** — 5-hour rolling window with percentage
- **Daily token usage** — daily quota tracking
- **Web search count** — per-model breakdown (search-prime, web-reader, etc.)
- **Color-coded indicators** — green (< 70%), orange (70–90%), red (> 90%)
- **Status bar modes** — number (icon + %) or pie chart with outline
- **Auto-refresh** — every 5 minutes
- **Launch at Login** — via macOS SMAppService
- **Lightweight** — native Swift/SwiftUI, no external dependencies

## Screenshots

### Number mode
Icon + percentage in the menu bar.

### Pie chart mode
Combined icon + color-coded pie chart in the menu bar.

### Popover
```
┌─────────────────────────────────┐
│  GLM Monitor    [Max Plan]  [↻] │
│─────────────────────────────────│
│  Session                    15% │
│  ██████░░░░░░░░░░░░░░░░░░░░░░░ │
│  ↻ 4h 23m                      │
│─────────────────────────────────│
│  Daily                      45% │
│  █████████████░░░░░░░░░░░░░░░░░ │
│  ↻ 18h 12m                     │
│─────────────────────────────────│
│  Web Searches         1828/4000 │
│    search-prime: 1433           │
│    web-reader:    462           │
│  Resets monthly                 │
│─────────────────────────────────│
│  Status Bar Style  [Number|Pie] │
│  Launch at Login         [ON]   │
│  Updated 2:30 PM  [Restart][Quit]│
└─────────────────────────────────┘
```

## Installation

### Download

Grab the latest release from [Releases](https://github.com/gordonxc/glm-monitor/releases).

1. Download and unzip `GLMMonitor-vX.X.X.zip`
2. Move `GLMMonitor.app` to `/Applications`
3. On first launch, right-click → **Open** (to bypass Gatekeeper)

### Build from source

Requires Xcode Command Line Tools.

```bash
git clone https://github.com/gordonxc/glm-monitor.git
cd glm-monitor
make build
make run
```

## Configuration

### API Key

The app needs a Z.ai API key. It checks in order:

1. Environment variable `ANTHROPIC_AUTH_TOKEN`
2. Environment variable `ZAI_API_KEY`
3. Environment variable `GLM_API_KEY`
4. Config file `~/.glm-monitor/config.json`
5. Shell dotfiles (`~/.zshrc`, `~/.bashrc`, etc.)

If launched via `open` (e.g. Launch at Login), environment variables are not available. Use the config file instead:

```bash
mkdir -p ~/.glm-monitor
echo '{"apiKey":"your-api-key-here"}' > ~/.glm-monitor/config.json
```

## Tech Stack

- **Swift + SwiftUI** — macOS 13+ Ventura, `MenuBarExtra`
- **Swift Package Manager** — `swift build -c release`
- **No external dependencies** — Foundation URLSession for networking
- **LSUIElement** — no dock icon, lives in the menu bar only

## License

MIT
