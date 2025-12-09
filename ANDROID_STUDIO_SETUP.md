# Android Studio eke Run Karanna Setup

## Step 1: Android Studio eke Project Open Karanna

1. Android Studio open karanawa
2. **File → Open** (Ctrl+O)
3. `D:\10-18\10-18\new cycle` folder eka select karanawa
4. "Trust Project" button eka click karanawa

## Step 2: Flutter Plugin Check Karanna

1. **File → Settings** (Ctrl+Alt+S)
2. **Plugins** eka click karanawa
3. "Flutter" plugin eka install kara thiyenawa nam check karanawa
4. Install kara na nam, install karanawa (Dart plugin eka automatically install venawa)

## Step 3: Flutter SDK Path Set Karanna

1. **File → Settings → Languages & Frameworks → Flutter**
2. Flutter SDK path eka set karanawa (usually: `C:\src\flutter` or `C:\flutter`)
3. "Apply" click karanawa

## Step 4: Device Select Karanna

1. Top bar eke device dropdown eka click karanawa
2. Available devices:
   - **Android Device** (connected phone/emulator)
   - **Windows** (desktop)
   - **Chrome** (web)

## Step 5: Run Karanna

### Method 1: Run Button
1. Top bar eke **▶️ Run** button eka click karanawa
2. Or **Shift+F10** press karanawa

### Method 2: Run Configuration
1. Top bar eke "main.dart" dropdown eka click karanawa
2. "Edit Configurations..." select karanawa
3. "main.dart" configuration eka select karanawa
4. Device eka select karanawa
5. "OK" click karanawa
6. Run button eka click karanawa

## Step 6: Debug Karanna

1. **🐛 Debug** button eka click karanawa
2. Or **Shift+F9** press karanawa
3. Breakpoints set karanna puluwan

## Common Issues & Solutions

### Issue: "No devices found"
**Solution:**
- Android emulator start karanawa
- Or physical device connect karanawa (USB debugging enable karanawa)
- Or Windows/Chrome select karanawa

### Issue: "Flutter SDK not found"
**Solution:**
- Flutter SDK install kara thiyenawa nam check karanawa
- Settings eke Flutter SDK path eka correct karanawa

### Issue: "Gradle sync failed"
**Solution:**
- **File → Sync Project with Gradle Files** click karanawa
- Or terminal eke: `cd android && gradlew clean`

### Issue: "Build failed"
**Solution:**
- **Build → Clean Project** click karanawa
- **Build → Rebuild Project** click karanawa

## Quick Commands

- **Run:** Shift+F10
- **Debug:** Shift+F9
- **Stop:** Ctrl+F2
- **Hot Reload:** Ctrl+\
- **Hot Restart:** Ctrl+Shift+\

## Tips

1. **Hot Reload:** Code changes kara, save kara, hot reload button eka click karanawa (lightning bolt icon)
2. **Hot Restart:** Full restart karanna oni nam, hot restart button eka click karanawa
3. **Device Selection:** Top bar eke device dropdown eke device eka easily change karanna puluwan
4. **Logs:** Bottom eke "Run" tab eka open kara logs danne puluwan

---

**Made with ❤️ for OvuMate Development**



