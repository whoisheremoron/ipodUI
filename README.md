![screen1](https://github.com/user-attachments/assets/b0d63c59-a9fd-4f6e-8ca1-8862d167eb11)# iPod Classic

A native iOS app that turns your iPhone into an iPod Classic — complete with a working click wheel, iPod-style UI, and full integration with your Music library.

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2015%2B-blue?style=flat-square"/>
  <img src="https://img.shields.io/badge/built%20with-Theos-lightgrey?style=flat-square"/>
  <img src="https://img.shields.io/badge/jailbreak-required-red?style=flat-square"/>
</p>

![screen1](https://github.com/user-attachments/assets/aea09cc8-36ac-4b78-afc1-6481cde4a8ed)
![Screen2](https://github.com/user-attachments/assets/07024c91-e08b-4dce-ad22-40633c046c73)
![Screen3](https://github.com/user-attachments/assets/d1a026d0-bfc4-4898-9581-d4dddd706693)

---

## Features

- **Click wheel** — touch-based scroll wheel with taptic feedback and click sounds on every interaction
- **Full music library** — browse by Albums, Artists, Playlists, Songs, and Genres
- **Now Playing screen** — album art, track/artist/album info, iPod-style flat progress bar with elapsed and remaining time
- **Cover Flow** — album art browser(WIP)
- **Async artwork loading** — all album art loads in the background via `NSCache`, no UI freezing(I hope)
- **Background media preloading** — library queries run at launch so menu would open instantly
- **Settings** — toggle taptics and click sounds

---

## Requirements

- **Jailbroken iPhone** (rootless jailbreak supported — Dopamine, palera1n, etc.)
- **iOS 15.0 or later**
- **Theos** build system installed on your Mac or Linux machine
- **Music library access** — grant permission on first launch

---

## Building from Source

### 1. Install Theos

If you don't have Theos installed:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

Then add to your `~/.bashrc` or `~/.zshrc`:

```bash
export THEOS=~/theos
```

Reload your shell:

```bash
source ~/.bashrc
```

### 2. Clone the repository

```bash
git clone https://github.com/yourusername/IPodClassic.git
cd IPodClassic
```

### 3. Check your SDK

Make sure you have an iOS 15+ SDK in `$THEOS/sdks/`:

```bash
ls $THEOS/sdks/
```

If needed, adjust the `TARGET` line in `Makefile` to match your SDK version:

```makefile
TARGET = iphone:clang:16.5:15.0
```

### 4. Build and install

Make sure your iPhone is on the same Wi-Fi network, then run:

```bash
make clean && make package && make install THEOS_DEVICE_IP=<your_device_ip>
```

Replace `<your_device_ip>` with your iPhone's local IP address (find it in **Settings → Wi-Fi → your network**).

The app will be installed and the device will respring automatically.

---

## Installing a Pre-built IPA

> Coming soon — pre-built `.ipa` releases will be available on the [Releases](../../releases) page.

---

## Project Structure

```
IPodClassic/
├── AppDelegate.m                # App entry point, media auth, library preload
├── RootViewController.m         # Top-level nav, music menu builder, custom slide transition
├── MenuViewController.m/.h      # Reusable iPod-style list screen
├── TrackListViewController.m/.h # Track list for albums/playlists/artists
├── NowPlayingViewController.m   # Now Playing screen with progress bar
├── ClickWheelView.m/.h          # Touch-based click wheel (taptic + click sound)
├── CoverFlowViewController.m    # Cover Flow album browser
├── SettingsViewController.m     # Haptic/sound toggle settings
├── IPDMenuCell.m/.h             # Custom UITableViewCell (no UIKit layout conflicts)
├── IPDArtworkCache.m/.h         # NSCache-backed async artwork loader
├── IPDMediaLibrary.m/.h         # Background MPMediaQuery preloader
├── IPodLayout.h                 # All colors, dimensions, and shared UI helpers
├── Makefile
├── control
└── Info.plist
```

---

## How It Works

**Click Wheel** — `ClickWheelView` tracks touch angle using `atan2`. Rotation accumulates and fires `WheelActionScrollUp/Down` every `2π/20` radians. Button zones (Menu, Next, Prev, Play/Pause) are detected by angle quadrant on `touchesEnded`. Each tick triggers both `IPDHaptic()` (UIImpactFeedbackGenerator) and `IPDClick()` (AudioServicesPlaySystemSound 1104).

**Async Artwork** — `IPDArtworkCache` runs `[MPMediaItemArtwork imageWithSize:]` on a serial background queue and caches results in `NSCache` (up to 300 images / ~40 MB). When an image arrives, the specific table row is reloaded via `MenuItem.onArtworkLoaded` callback — no full `reloadData`.

**Library Preloading** — `IPDMediaLibrary` fires all five `MPMediaQuery` calls concurrently at app launch (after media authorization). By the time the user navigates to Music → Albums, results are ready instantly.

**Navigation Animation** — a custom `UINavigationControllerDelegate` (`IPDSlideAnimator`) slides only the white screen subview — not the full view — so the iPod body stays fixed while content transitions inside the display area.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
