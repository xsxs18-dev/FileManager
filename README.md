# FileManager

A local-first file manager for iOS 18+, built for sideloading. FileManager goes beyond what Apple's Files app offers: real PDF password protection, AES-256 encrypted ZIP archives, a Share Sheet extension, and folders that can be hidden or locked behind Face ID — all without a single network request.

![Build IPA](https://github.com/xsxs18-dev/FileManager/actions/workflows/build-ipa.yml/badge.svg)

## Features

### File & Folder Management
- Create folders and files, including empty `.txt` files
- Rename files and folders — including changing the file extension (`.txt` → `.zip`, `.pdf`, ...)
- Browse, delete, and multi-select items

### Hidden & Face ID-Protected Folders
- Mark any folder as **hidden** — it disappears from normal navigation and is only reachable from a dedicated "Hidden Area"
- Independently **lock** any folder with Face ID / passcode (`LocalAuthentication`)
- Hidden and locked are separate, composable protections

### Share Sheet Integration
- FileManager appears as a destination in the iOS share sheet of any app
- Incoming shared files are routed into a folder picker so you choose exactly where they land in the vault

### ZIP Module
- Create and extract ZIP archives from any selection of files/folders
- Password-protect archives with **AES-256**: since `ZIPFoundation` has no native password support, files are individually encrypted with `CryptoKit` (AES-GCM, key derived from the password + a random salt) before being zipped

### PDF Module
- Create PDFs from multiple images (combined into one document), from plain text (simple built-in editor), or from a document scan (`VisionKit` camera scanner)
- **Real, standard-compliant PDF password protection** via `PDFKit`'s owner/user password (`PDFDocument.write(to:withOptions:)`) — the resulting file is protected everywhere, not just inside this app
- Unlock a protected PDF by entering its password, preview it, and save an unlocked copy

## Tech Stack

- **SwiftUI** for the entire app (UIKit only where required: `VNDocumentCameraViewController` for scanning, a `UIViewController`-based Share Extension)
- **PDFKit** — PDF creation, rendering, and encryption
- **ZIPFoundation** (SwiftPM) — ZIP archive creation/extraction
- **CryptoKit** — AES-GCM encryption for password-protected ZIP contents
- **LocalAuthentication** — Face ID / passcode folder locking
- **App Group** (`group.com.xsxs18.FileManager`) — shared storage container between the main app and the Share Extension
- 100% local. No backend, no network calls, no analytics.

## Project Structure

```
FileManager/
├── App/              # App entry point
├── DesignSystem/      # Colors, spacing, typography, shared styles
├── Models/             # FileItem, ZipManifest
├── Services/           # FileSystemService, ZipService, PDFService,
│                        # CryptoService, AuthenticationService, FolderProtectionStore
├── Shared/              # App Group constants (shared with the extension)
├── Views/               # SwiftUI screens and sheets
└── Resources/            # Assets, Info.plist

ShareExtension/          # Share Sheet extension target
project.yml               # XcodeGen project definition
.github/workflows/         # CI: builds an unsigned .ipa on every push
```

## Building

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj` from `project.yml` — the generated project is not committed.

```bash
brew install xcodegen
xcodegen generate
open FileManager.xcodeproj
```

Set your signing team in Xcode (Signing & Capabilities) and build to a device.

### CI Builds

Every push to `main` triggers a GitHub Actions workflow that builds an **unsigned** `.ipa` on a macOS runner and uploads it as a build artifact. Since this app isn't distributed through the App Store, the artifact needs to be signed locally before installing:

1. Download the `FileManager-unsigned-ipa` artifact from the [Actions](https://github.com/xsxs18-dev/FileManager/actions) tab
2. Sign and install it with [Sideloadly](https://sideloadly.io/) or [AltStore](https://altstore.io/) using your own Apple ID

## Requirements

- iOS 18.0+
- No App Store account needed — designed for sideloading with a free or paid Apple Developer identity
