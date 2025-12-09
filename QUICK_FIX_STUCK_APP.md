# App Stuck වෙන Problem - Quick Fix

## ❌ Problem
App mobile eka run karana vela 15+ minutes stuck venawa, open venne na.

## ✅ Quick Fix Steps

### Step 1: Stop Current Process
Android Studio eke:
- **Stop button** click karanawa (⏹️)
- Or **Ctrl+F2** press karanawa

### Step 2: Uninstall Old App
Mobile device eke:
1. **Settings → Apps → ovumate** (or com.example.ovumate)
2. **Uninstall** click karanawa
3. Or Android Studio terminal eke:
   ```bash
   flutter uninstall
   ```

### Step 3: Clean Build
Android Studio terminal eke:
```bash
cd "D:\10-18\10-18\new cycle"
flutter clean
flutter pub get
```

### Step 4: Run with Verbose Logging
Android Studio eke:
1. **Run → Edit Configurations...**
2. **Additional run args** eke add karanawa: `--verbose`
3. Or terminal eke:
   ```bash
   flutter run -d A9SV6R4126000946 --verbose
   ```

### Step 5: Check Logs
Android Studio eke **Logcat** tab eka open kara errors check karanawa:
- Filter: `flutter` or `ovumate`
- Errors danne puluwan

## 🔍 Common Issues & Solutions

### Issue 1: Installation Hanging
**Solution:**
- Device eke **Developer Options** enable kara thiyenawa nam check karanawa
- **USB Debugging** enable kara thiyenawa nam check karanawa
- USB cable change karanawa

### Issue 2: App Crashes on Launch
**Solution:**
- Logcat eke crash logs check karanawa
- Common cause: Missing permissions or Supabase initialization

### Issue 3: Network Timeout
**Solution:**
- Mobile eke **Internet connection** check karanawa
- WiFi or Mobile data enable kara thiyenawa nam check karanawa

### Issue 4: Build Stuck
**Solution:**
- **File → Invalidate Caches / Restart** click karanawa
- Android Studio restart karanawa

## 🚀 Alternative: Run on Windows First
Testing karanna oni nam:
1. Device dropdown eke **Windows** select karanawa
2. Run karanawa
3. Windows eke work venawa nam, Android issue ekak

## 📱 Manual Installation
1. Build APK:
   ```bash
   flutter build apk --debug
   ```
2. APK file eka mobile eke copy karanawa
3. Mobile eke install karanawa

## ✅ Expected Behavior
- Build: 2-5 minutes
- Installation: 30-60 seconds
- Launch: 1-2 seconds
- Total: 3-7 minutes maximum

---

**If still stuck after 10 minutes, check Logcat for specific errors!**


