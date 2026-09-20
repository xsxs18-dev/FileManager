<p align="center">
  <img src="FileManager/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="128" height="128" alt="FileManager icon">
</p>

<h1 align="center">FileManager</h1>

<p align="center">
  A local file manager for iOS that actually does the things Apple's Files app won't.
</p>

<p align="center">
  <img src="https://github.com/xsxs18-dev/FileManager/actions/workflows/build-ipa.yml/badge.svg" alt="Build status">
  <img src="https://img.shields.io/badge/iOS-18%2B-blue" alt="iOS 18+">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT license">
</p>

---

Files apps on iOS are fine for browsing, but the moment you want to actually *protect* something — a real password on a PDF, an encrypted zip, a folder nobody but you can open — you're stuck. FileManager is my answer to that: a sideloaded, no-account, no-backend file manager that treats security features as first-class, not an afterthought.

Everything runs on-device. There's no server, no analytics, no account. The app never makes a network request — it doesn't even ask for one.

## What it does

**Files & folders** — the basics, done properly: create folders and files, rename anything (including swapping the extension, `.txt` → `.pdf`, whatever), multi-select, delete, browse.

**Hidden & Face ID–locked folders** — mark a folder "hidden" and it's gone from normal browsing, only reachable from its own dedicated area. Separately, lock any folder behind Face ID / passcode. The two are independent, so you can mix and match.

**Share Sheet support** — FileManager shows up when you tap Share in any other app. Pick a file, pick FileManager, pick a folder to drop it in. Done.

**ZIP, with real encryption** — create and extract zip archives from anything in the app. Password-protect them with AES-256. (`ZIPFoundation` doesn't support encrypted zips natively, so files are individually encrypted with `CryptoKit` before they ever get zipped.)

**PDF tools** — build a PDF from a batch of photos, from typed text, or straight from the camera via a document scanner. Lock it with a real owner/user password through `PDFKit` — the kind of protection that works when you open the file in *any* PDF reader, not just this app.

## Screenshots

*(coming soon — open an issue or PR if you'd like to contribute some)*

## Getting it running

You'll need a Mac with Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (the `.xcodeproj` isn't committed — it's generated from `project.yml`):

```bash
brew install xcodegen
git clone https://github.com/xsxs18-dev/FileManager.git
cd FileManager
xcodegen generate
open FileManager.xcodeproj
```

Set your own signing team in Xcode and build to a device.

### Don't have Xcode?

Every push to `main` builds an **unsigned** `.ipa` automatically on GitHub Actions. Grab it from the [Releases](https://github.com/xsxs18-dev/FileManager/releases) page or the latest [Actions run](https://github.com/xsxs18-dev/FileManager/actions), then sign and install it with your own free (or paid) Apple ID using:

- [Sideloadly](https://sideloadly.io/), or
- [AltStore](https://altstore.io/) — handles the 7-day re-signing free accounts need automatically

## How it's built

| | |
|---|---|
| UI | SwiftUI everywhere, except where iOS forces UIKit (the document scanner, the Share Extension host) |
| PDF | `PDFKit` — creation, rendering, and real owner/user password encryption |
| ZIP | [`ZIPFoundation`](https://github.com/weichsel/ZIPFoundation) for archiving, `CryptoKit` (AES-GCM) for encryption |
| Face ID | `LocalAuthentication` |
| App ↔ Share Extension | one App Group container, no App Store, no cloud |

```
FileManager/
├── App/            entry point
├── DesignSystem/   colors, spacing, type, shared button/card styles
├── Models/         FileItem, ZipManifest
├── Services/       FileSystemService, ZipService, PDFService, CryptoService,
│                   AuthenticationService, FolderProtectionStore
├── Shared/         App Group constants, shared with the extension
├── Views/          screens and sheets
└── Resources/      Assets.xcassets, Info.plist

ShareExtension/     the Share Sheet extension target
project.yml         XcodeGen project definition
.github/workflows/  CI — builds an unsigned .ipa on every push
```

## Known rough edges

- Since this is sideloaded rather than App Store–distributed, some free Apple ID signing tools are inconsistent about preserving the App Group entitlement. If shared files don't show up after using the Share Sheet, that's the most likely cause — re-sign with your Apple Developer account if you have one, or open an issue.
- No landscape-optimized layout yet.
- No iPad-specific split view.

Contributions and bug reports welcome — this is a small side project, not a polished product, and it'll stay that way unless people find it useful enough to push on.

## License

MIT — see [LICENSE](LICENSE). Do whatever you want with it.
