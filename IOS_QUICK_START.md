# iOS Quick Start Guide (සිංහල/English)

## ⚡ Quick Setup (වේගවත් Setup)

### Mac Computer හි:

1. **Terminal Open කරන්න**

2. **Project Folder එකට යන්න:**
   ```bash
   cd "/path/to/new cycle"
   ```

3. **Setup Script Run කරන්න:**
   ```bash
   chmod +x ios/setup.sh
   ./ios/setup.sh
   ```

4. **Xcode Open කරන්න:**
   ```bash
   open ios/Runner.xcworkspace
   ```

5. **Xcode හි Signing Configure කරන්න:**
   - Runner project select කරන්න
   - Signing & Capabilities tab
   - Team select කරන්න

6. **Run කරන්න:**
   ```bash
   flutter run -d ios
   ```

## 📋 Manual Setup (Manual Setup)

### Step 1: Dependencies Install කරන්න

```bash
# Flutter dependencies
flutter pub get

# iOS dependencies
cd ios
pod install
cd ..
```

### Step 2: Xcode හි Open කරන්න

```bash
open ios/Runner.xcworkspace
```

**⚠️ Important**: `.xcworkspace` file එක open කරන්න, `.xcodeproj` නොවේ!

### Step 3: Configure Signing

1. Xcode හි **Runner** project select කරන්න
2. **Signing & Capabilities** tab එකට යන්න
3. **Team** dropdown හි your Apple Developer account select කරන්න
4. **Bundle Identifier** set කරන්න (e.g., `com.yourcompany.ovumate`)

### Step 4: Build & Run

**Simulator හි:**
```bash
flutter run -d ios
```

**Release Build:**
```bash
flutter build ios --release
```

**IPA File (App Store):**
```bash
flutter build ipa --release
```

## ✅ What's Configured (කර ඇති දේ)

- ✅ Podfile - iOS dependencies
- ✅ Info.plist - Permissions (Camera, Photos, Contacts, Notifications)
- ✅ AppDelegate.swift - App initialization
- ✅ Deep linking - OAuth callback
- ✅ Background modes - Notifications

## 🔧 Troubleshooting

### Pod Install Fails:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

### Build Errors:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios
```

### Xcode Not Found:

```bash
# Install Xcode from App Store
# Or install command line tools:
xcode-select --install
```

## 📱 Testing

### Simulator හි Test කිරීමට:

```bash
# Available devices list:
flutter devices

# Run on specific device:
flutter run -d "iPhone 15 Pro"
```

### Physical Device හි Test කිරීමට:

1. iPhone USB cable හි connect කරන්න
2. Device trust කරන්න
3. Xcode හි device select කරන්න
4. Run කරන්න

## 🚀 App Store Submission

1. **Archive Create කරන්න:**
   - Xcode හි: Product > Archive

2. **Upload කරන්න:**
   - Window > Organizer
   - Distribute App > App Store Connect

3. **App Store Connect හි:**
   - App details add කරන්න
   - Screenshots upload කරන්න
   - Submit for review

## 📚 More Information

- Detailed guide: `ios/SETUP_INSTRUCTIONS.md`
- Build options: `IOS_BUILD_OPTIONS.md`
- Setup complete: `IOS_SETUP_COMPLETE.md`

---

**Ready to build!** 🎉



