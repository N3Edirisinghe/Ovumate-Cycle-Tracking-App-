# iOS App Build Options (Windows හි සිට)

## ⚠️ Important: iOS apps macOS හි build කිරීමට අවශ්‍යයි

Windows computer හි iOS app build කිරීමට නොහැකිය. macOS computer එකක් අවශ්‍යයි.

## Options (විකල්ප)

### Option 1: macOS Computer Use කරන්න (Best Option)

1. **MacBook, iMac, Mac Mini** - ඕනෑම macOS computer එකක්
2. Project folder එක copy කරන්න Mac එකට
3. Xcode install කරන්න
4. Build කරන්න

**Steps:**
```bash
# Mac හි Terminal හි:
cd /path/to/project
cd ios
pod install
cd ..
flutter build ios --release
```

### Option 2: Cloud Build Services (Paid)

#### A. Codemagic
- Website: https://codemagic.io
- Free tier available
- Automatic builds
- App Store upload

#### B. AppCircle
- Website: https://appcircle.io
- Free tier available
- CI/CD integration

#### C. Bitrise
- Website: https://www.bitrise.io
- Free tier available
- Good for continuous integration

### Option 3: Mac VM (Not Recommended)

⚠️ **Warning**: Apple's Terms of Service වලට අනුව macOS virtual machine හි run කිරීම legal නොවේ (except on Apple hardware).

### Option 4: MacStadium / MacinCloud (Rent a Mac)

- **MacStadium**: https://www.macstadium.com
- **MacinCloud**: https://www.macincloud.com
- Monthly subscription
- Remote access to Mac

### Option 5: Friend/Colleague Mac Use කරන්න

1. Project folder එක share කරන්න
2. Mac හි build කරන්න
3. IPA file එක download කරන්න

## Quick Setup for Mac (Mac එකක් තිබේ නම්)

### Step 1: Install Xcode
```bash
# App Store වෙතින් Xcode download කරන්න
# Or command line:
xcode-select --install
```

### Step 2: Install CocoaPods
```bash
sudo gem install cocoapods
```

### Step 3: Install Dependencies
```bash
cd ios
pod install
cd ..
```

### Step 4: Build
```bash
# For simulator:
flutter run -d ios

# For device:
flutter build ios --release

# For App Store:
flutter build ipa --release
```

## Project Files Ready (සූදානම්)

✅ Podfile created
✅ Info.plist configured
✅ iOS project structure ready
✅ Permissions configured

## Next Steps

1. **Mac computer එකක් find කරන්න** (own, friend, or cloud service)
2. **Project folder එක copy කරන්න** Mac එකට
3. **Xcode install කරන්න**
4. **Build කරන්න** using the guide in `IOS_BUILD_GUIDE.md`

## Alternative: Test on Web First

iOS build කිරීමට පෙර web හි test කරන්න:

```bash
flutter run -d chrome
```

## Contact for Help

Mac computer එකක් නැති නම්:
- Cloud build service use කරන්න (Codemagic recommended)
- Friend/colleague Mac use කරන්න
- Mac rental service use කරන්න



