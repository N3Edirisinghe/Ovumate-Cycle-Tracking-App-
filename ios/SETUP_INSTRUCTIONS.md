# iOS Setup Instructions (Sinhala/English)

## Prerequisites (අවශ්‍ය දේවල්)

### 1. macOS Computer
- MacBook, iMac, Mac Mini, හෝ Mac Studio
- macOS 12.0 හෝ ඊට වැඩි version

### 2. Xcode Installation
```bash
# App Store වෙතින් Xcode download කරන්න
# හෝ command line හි:
xcode-select --install
```

### 3. CocoaPods Installation
```bash
sudo gem install cocoapods
```

### 4. Flutter SDK
- Already installed ✅

## Step-by-Step Setup (පියවරෙන් පියවර)

### Step 1: Project Copy කරන්න Mac එකට

```bash
# Project folder එක Mac එකට copy කරන්න
# USB drive, cloud storage, හෝ network share use කරන්න
```

### Step 2: Terminal Open කරන්න

```bash
# Terminal app open කරන්න (Applications > Utilities > Terminal)
```

### Step 3: Project Folder එකට යන්න

```bash
cd /path/to/your/project/"new cycle"
```

### Step 4: Flutter Dependencies Install කරන්න

```bash
flutter pub get
```

### Step 5: iOS Dependencies Install කරන්න

```bash
cd ios
pod install
cd ..
```

**Note**: First time pod install කරන විට කල් ගත විය හැකිය (5-10 minutes)

### Step 6: Xcode හි Project Open කරන්න

```bash
# IMPORTANT: .xcworkspace file එක open කරන්න, .xcodeproj නොවේ!
open ios/Runner.xcworkspace
```

### Step 7: Xcode හි Settings Configure කරන්න

1. **Project Navigator** හි `Runner` select කරන්න
2. **Signing & Capabilities** tab එකට යන්න
3. **Team** select කරන්න (Apple Developer account)
4. **Bundle Identifier** set කරන්න (e.g., `com.yourcompany.ovumate`)

### Step 8: Build කරන්න

#### Option A: Simulator හි Test කිරීමට

1. Xcode හි top bar හි device select කරන්න
2. iPhone simulator select කරන්න
3. **Play button** (▶️) click කරන්න

#### Option B: Command Line හි

```bash
# Simulator හි run කිරීමට:
flutter run -d ios

# Specific simulator select කිරීමට:
flutter devices  # Available devices list කරන්න
flutter run -d "iPhone 15 Pro"  # Device name specify කරන්න
```

### Step 9: Release Build කිරීමට

```bash
# Release build:
flutter build ios --release

# IPA file create කිරීමට (App Store submission):
flutter build ipa --release
```

## Troubleshooting (ගැටළු විසඳීම)

### Pod Install Error නම්:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Build Errors නම්:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```

### Xcode Version Issues:

- Xcode 14.0 හෝ ඊට වැඩි version use කරන්න
- Command Line Tools install කර ඇති බව verify කරන්න:
  ```bash
  xcode-select -p
  ```

### Signing Issues:

- Apple Developer account එකක් අවශ්‍යයි
- Xcode හි Signing & Capabilities හි team select කරන්න
- Bundle Identifier unique විය යුතුය

## App Store Submission (App Store හි upload කිරීම)

### Step 1: Archive Create කරන්න

1. Xcode හි **Product > Scheme > Runner** select කරන්න
2. **Product > Destination > Any iOS Device** select කරන්න
3. **Product > Archive** click කරන්න
4. Archive complete වන තෙක් රැඳී සිටින්න

### Step 2: Archive Upload කරන්න

1. **Window > Organizer** open කරන්න
2. Archive select කරන්න
3. **Distribute App** click කරන්න
4. **App Store Connect** select කරන්න
5. Wizard follow කරන්න

### Step 3: App Store Connect හි Configure කරන්න

1. https://appstoreconnect.apple.com වෙත යන්න
2. App details add කරන්න
3. Screenshots upload කරන්න
4. Submit for review කරන්න

## Configuration Files (Configured Files)

✅ **Podfile** - iOS dependencies
✅ **Info.plist** - App permissions and settings
✅ **AppDelegate.swift** - App initialization
✅ **Bundle Identifier** - Set in Xcode
✅ **Signing** - Configure in Xcode

## Permissions Configured (Configured Permissions)

✅ Camera access
✅ Photo library access
✅ Contacts access (WhatsApp sharing)
✅ Notifications (background)
✅ Deep linking (OAuth)

## Minimum Requirements

- **iOS Version**: 12.0 or later
- **Xcode Version**: 14.0 or later
- **CocoaPods**: 1.11.0 or later
- **Flutter**: 3.0.0 or later

## Quick Commands Reference

```bash
# Dependencies install:
flutter pub get
cd ios && pod install && cd ..

# Run on simulator:
flutter run -d ios

# Build release:
flutter build ios --release

# Build IPA:
flutter build ipa --release

# Clean build:
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

## Support

- Flutter iOS Docs: https://docs.flutter.dev/deployment/ios
- Xcode Help: Help menu in Xcode
- CocoaPods Docs: https://guides.cocoapods.org

---

**Status**: iOS setup complete and ready for building! 🚀



