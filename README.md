# MusicOnly

A small iOS app (SwiftUI + WKWebView) that shows only YouTube Music, keeps playing in the
background, and tries to skip ads. For personal sideloading.

## Features
- Loads only `music.youtube.com` (and Google sign-in pages); other links open in Safari
- Background audio: keeps playing when minimized, on the lock screen, or when other apps are open
- Best-effort ad handling: network block rules, hidden promos, auto-skip, fast-forward of inline ads

## Project layout
- `Sources/` – Swift source files
- `project.yml` – [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec (the `.xcodeproj` is generated, not committed)
- `.github/workflows/build.yml` – builds an unsigned `.ipa` on a macOS runner

## Build an IPA without a Mac
1. Push this repo to GitHub.
2. Open the **Actions** tab → **Build unsigned IPA** → wait for the green tick.
3. Download the `MusicOnly-ipa` artifact and unzip it to get `MusicOnly.ipa`.
4. Install it with [Sideloadly](https://sideloadly.io) using your Apple ID.
5. On the iPhone: Settings → Privacy & Security → Developer Mode → On, then
   Settings → General → VPN & Device Management → trust your Apple ID.

Free Apple IDs expire the app after 7 days; re-sideload to renew.

## Build locally on a Mac
```bash
brew install xcodegen
xcodegen generate
open MusicOnly.xcodeproj
```
Set your Team under Signing & Capabilities and run on your device.

## Disclaimer
Blocking YouTube ads goes against YouTube's Terms of Service, and Apple would likely reject
this app from the App Store. Use it for personal sideloading only. YouTube Premium is the
supported way to get ad-free playback. Ad handling is best effort and can break when
YouTube changes its site.
