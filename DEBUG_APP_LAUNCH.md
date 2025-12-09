# App Launch Debugging Guide

## ❌ Problem
App installs successfully but doesn't launch after installation.

## 🔍 Debugging Steps

### Step 1: Check Logcat for Errors
Android Studio eke:
1. **View → Tool Windows → Logcat** open karanawa
2. Filter eke type karanawa: `flutter` or `ovumate` or `ERROR`
3. Red errors check karanawa

### Step 2: Check Device Logs
Terminal eke:
```bash
cd "D:\10-18\10-18\new cycle"
flutter logs
```

### Step 3: Uninstall and Reinstall
```bash
flutter uninstall
flutter install
flutter run
```

### Step 4: Check if App is Installed
Mobile device eke:
- **Settings → Apps → ovumate** check karanawa
- App eka thiyenawa nam, manually open karanna try karanawa

### Step 5: Run with Debug Output
```bash
flutter run -d A9SV6R4126000946 --verbose
```

## 🔧 Common Fixes

### Fix 1: Clear App Data
Mobile device eke:
1. **Settings → Apps → ovumate**
2. **Storage → Clear Data**
3. **Clear Cache**
4. App eka run karanawa

### Fix 2: Check Permissions
Mobile device eke:
1. **Settings → Apps → ovumate → Permissions**
2. All permissions enable karanawa

### Fix 3: Rebuild from Scratch
```bash
cd "D:\10-18\10-18\new cycle"
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Fix 4: Check Android SDK
```bash
flutter doctor -v
```
Android SDK properly installed kara thiyenawa nam check karanawa.

## 📱 Manual Test
1. APK build karanawa:
   ```bash
   flutter build apk --debug
   ```
2. APK file eka mobile eke copy karanawa
3. Mobile eke manually install karanawa
4. Open karanawa

## 🆘 If Still Not Working
Logcat eke exact error message eka share karanna - mehema exact problem eka identify karanna puluwan.


