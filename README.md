# StickyShot 📷

## Screenshots that stay on top

Capture any screen region as a floating preview window.

Ideal for quick reference, design comparisons, and keeping essential information visible while you work.
<br></br>

> Quick annotation tools (red lines)

<img width="900" alt="image" src="https://github.com/user-attachments/assets/2eedc986-801f-4c7e-a9d5-c1230265e7a6" />


## Features

- 🎯 **Global Hotkey** - Trigger screenshot from anywhere (default: `⌘⇧2`)
- ✂️ **Region Selection** - Click and drag to select any screen region
- 📌 **Sticky Previews** - Screenshots float on top of all windows
- 🖱️ **Draggable** - Move previews anywhere on screen
- 🔍 **Adjustable Opacity** - Scroll on preview to change transparency
- ✏️ **Annotation Tools** - Draw lines, arrows, squares, circles
- 📋 **Quick Actions**:
  - `⌘C` - Copy to clipboard
  - `⌘S` - Save to file
  - `⌘Z` - Undo last drawing
  - `Esc` - Close preview (or exit draw mode)
- ⚙️ **Fully Configurable**:
  - Custom hotkey
  - Save directory
  - Export format (PNG/JPEG)
  - Border color and width
  - Draw color
  - Max preview count
  - Launch at login

## Installation

### Homebrew (Recommended)

```bash
brew tap rgcr/homebrew-formulae
brew install --cask stickyshot
```

### Manual Download

1. Download [StickyShot-1.1.0-macos.dmg](https://github.com/rgcr/stickyshot/releases/download/v1.1.0/StickyShot-1.1.0-macos.dmg) from Releases
2. Open the DMG and drag `StickyShot.app` to `/Applications`
3. Bypass Gatekeeper: `xattr -cr /Applications/StickyShot.app`
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
| `⌘Z` | Undo last drawing |
| `Esc` | Exit draw mode / Close preview |
| Scroll | Adjust preview opacity |


### Right-Click Menu (on preview)


| Option | Description |
|--------|-------------|
| Copy | Copy to clipboard (with drawings) |
| Save | Save to file (with drawings) |
| Undo | Remove last drawing |
| Clear All Drawings | Remove all drawings |
| Draw Line | Enter line drawing mode |
| Draw Arrow | Enter arrow drawing mode |
| Draw Square | Enter square drawing mode |
| Draw Circle | Enter circle drawing mode |
| Close | Close preview |


### Menu Bar Options


| Option | Description |
|--------|-------------|
| Take Screenshot | Manually trigger capture |
| Close All Previews | Close all sticky windows (shows count) |
| Preferences... | Configure settings |
| Check for Updates... | Check for new versions |
| Help | Keyboard shortcuts and tips |
| About StickyShot | Version and credits |
| Quit | Exit application |


### Settings


| Setting | Description | Default |
|---------|-------------|---------|
| Screenshot Shortcut | Global hotkey | `⌘⇧2` |
| Save Location | Where to save screenshots | `~/Desktop` |
| Export Format | PNG or JPEG | PNG |
| Show Border | Border on previews | On |
| Border Color | Border color picker | Blue |
| Border Width | 1-5 pixels | 1px |
| Max Previews | 5, 10, 15, or 20 | 10 |
| Draw Color | Color for annotations | Red |
| Launch at Login | Start automatically | Off |
| Debug Logging | Enable debug logs | Off |


## Annotation Tools

1. Right-click on a preview
2. Select a drawing tool (Line, Arrow, Square, Circle)
3. Click and drag to draw
4. Drawing auto-exits after each shape
5. Use Undo (`⌘Z`) to remove mistakes
6. Drawings are included when copying or saving

## Troubleshooting

### Hotkey not working
- Check Accessibility permission is granted
- Try removing and re-adding StickyShot in Accessibility settings

### Black/empty screenshots
- Check Screen Recording permission is granted
- Try removing and re-adding StickyShot in Screen Recording settings

### After update, permissions not working
- You will need to re-grant permissions after updating
- System Settings → Privacy & Security → Accessibility/Screen Recording
- Remove and re-add StickyShot

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
