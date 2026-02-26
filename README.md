# StickyShot 📷  

## Screenshots that stay on top

Capture any screen region as a floating preview window.

Ideal for quick reference, design comparisons, and keeping essential information visible while you work.
<br></br>

<img width="900" alt="image" src="https://github.com/user-attachments/assets/d3f98d10-c4c6-48b9-9f79-b49051b1c2b5" />



## Features

- 🎯 **Global Hotkey** - Trigger screenshot from anywhere (default: `⌘⇧2`)
- ✂️ **Region Selection** - Click and drag to select any screen region
- 📌 **Sticky Previews** - Screenshots float on top of all windows
- 🖱️ **Draggable** - Move previews anywhere on screen
- 📋 **Quick Actions**:
  - `⌘C` - Copy to clipboard
  - `⌘S` - Save to file (Default: `~/Desktop` as `StickyShot_<year>-<month>-<day>_<hour>-<minute>-<second>.png`)
  - `Esc` - Close preview
- ⚙️ **Configurable** - Custom hotkey, change default save location

## Installation

### Homebrew (Recommended)

```bash
brew tap rgcr/homebrew-formulae
brew install --cask stickyshot
```

### Manual Download

1. Download [StickyShot-1.0.0-macos.dmg](https://github.com/rgcr/stickyshot/releases/download/v1.0.0/StickyShot-1.0.0-macos.dmg) from `Releases`
2. Open the DMG and drag `StickyShot.app` to `/Applications`
3. Bypass Gatekeeper `xattr -cr /Applications/Snape.app`
4. Grant necessary permissions (see below)

## Permissions

StickyShot requires two permissions:


| Permission | Purpose | How to Grant |
|------------|---------|--------------|
| **Accessibility** | Global hotkey | System Settings → Privacy & Security → Accessibility → Add StickyShot |
| **Screen Recording** | Capture screenshots | System Settings → Privacy & Security → Screen Recording → Add StickyShot |


## Usage

1. **Launch** - StickyShot appears as 📷 in your menu bar
2. **Capture** - Press `⌘⇧2` (or your custom shortcut)
3. **Select** - Click and drag to select a region
4. **Interact** - The screenshot becomes a floating sticky window


### Keyboard Shortcuts


| Shortcut | Action |
|----------|--------|
| `⌘⇧2` | Take screenshot (default, configurable) |
| `⌘C` | Copy preview to clipboard |
| `⌘S` | Save preview to file |
| `Esc` | Close preview |


### Menu Bar Options


| Option | Description |
|--------|-------------|
| Take Screenshot | Manually trigger capture |
| Close All Previews | Close all sticky preview windows |
| Preferences... | Configure settings |
| Quit | Exit application |


### Options

| Setting | Description | Default |
|---------|-------------|---------|
| `showBlueBorder` | Blue border on previews | `true` |
| `saveDirectory` | Where to save screenshots | `~/Desktop` |
| `launchAtLogin` | Start automatically on login | `false` |
| `debugLogging` | Enable debug logs | `false` |


## Troubleshooting

### Hotkey not working
- Check Accessibility permission is granted
- Try removing and re-adding StickyShot in Accessibility settings

### Black/empty screenshots
- Check Screen Recording permission is granted
- Try removing and re-adding StickyShot in Screen Recording settings

### Debug logs
Enable debug logging in Preferences → Advanced, then check:
```bash
cat ~/.config/stickyshot/debug.log
```

## Contributing

1. Fork the repo
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push the branch: `git push origin my-new-feature`
5. Open a Pull Request 🚀
