# Supabase Setup - කෙටි හැටි (Quick Guide)

## ⚡ Quick Steps (5 minutes)

### 1️⃣ Supabase Account Create කරන්න

1. Browser එකේ: [https://supabase.com](https://supabase.com)
2. "Start your project" click කරන්න
3. Sign up කරන්න (GitHub හෝ Email)

---

### 2️⃣ Project Create කරන්න

1. Dashboard එකේ "New Project" click කරන්න
2. Fill කරන්න:
   - **Name**: `OvuMate`
   - **Database Password**: (මතක තියාගන්න!)
   - **Region**: Select කරන්න
3. "Create" click කරන්න
4. **3-5 minutes රැඳී සිටින්න**

---

### 3️⃣ Database Setup කරන්න

1. Left sidebar > **"SQL Editor"** click කරන්න
2. **"New query"** click කරන්න
3. Computer folder එකේ **`supabase_schema.sql`** file open කරන්න
4. File content **copy කරන්න** (Ctrl+A, Ctrl+C)
5. Supabase SQL Editor එකේ **paste කරන්න** (Ctrl+V)
6. **"Run"** button click කරන්න ✅

---

### 4️⃣ API Keys Copy කරන්න

1. Left sidebar > **"Settings"** > **"API"** click කරන්න
2. **Copy කරගන්න:**
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...` (දිග key)

---

### 5️⃣ App එක Update කරන්න

1. **`lib/utils/constants.dart`** file open කරන්න
2. **Line 10** update කරන්න:
   ```dart
   static const String supabaseUrl = 'https://YOUR-PROJECT-ID.supabase.co';
   ```
3. **Line 14** update කරන්න:
   ```dart
   static const String supabaseAnonKey = 'YOUR-ACTUAL-ANON-KEY';
   ```
4. **Save කරන්න** (Ctrl+S)

---

### 6️⃣ Test කරන්න

```bash
flutter clean
flutter pub get
flutter run
```

1. App open වෙනවාද ✅
2. Register කරන්න
3. Supabase Dashboard > Table Editor > user_profiles check කරන්න
4. ✅ **User details පෙනෙනවා!**

---

## ✅ Done!

**Supabase setup complete!** 🎉

---

## 📋 Checklist

- [ ] ✅ Supabase account create
- [ ] ✅ Project create
- [ ] ✅ SQL schema run
- [ ] ✅ API keys copy
- [ ] ✅ constants.dart update
- [ ] ✅ App test

---

## 🆘 Help

- **Detailed Guide**: `SUPABASE_SETUP_SINHALA.md`
- **Quick Guide**: `HOW_TO_SETUP_SUPABASE.md`

---

**5 minutes කින් Supabase ready!** ⚡










