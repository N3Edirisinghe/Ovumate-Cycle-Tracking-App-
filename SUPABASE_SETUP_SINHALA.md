# Supabase Setup කරන හැටි - පියවරෙන් පියවර (සිංහල)

මෙම guide එක මගින් Supabase backend setup කරන හැටි පියවරෙන් පියවර පැහැදිලි කරයි.

---

## 📋 මොකක්ද ඕන?

1. Supabase account (free)
2. 15-20 minutes
3. Internet connection

---

## 🔥 පියවර 1: Supabase Account Create කරන්න

### Step 1.1: Website වෙත යන්න

1. Browser එක open කරන්න
2. [https://supabase.com](https://supabase.com) වෙත යන්න
3. **"Start your project"** button click කරන්න

### Step 1.2: Sign Up කරන්න

1. **GitHub account** එකක් හෝ **Email** එකක් භාවිතා කරන්න
2. Sign up කරන්න
3. Email verify කරන්න (email එකේ link click කරන්න)

---

## 🏗️ පියවර 2: New Project Create කරන්න

### Step 2.1: Project Create

1. Dashboard එකේ **"New Project"** button click කරන්න

2. Project details fill කරන්න:
   ```
   Name: OvuMate
   Database Password: [ශක්තිමත් password එකක්]
   ⚠️ මෙය SAVE කරගන්න! (අමතක වෙන්න එපා!)
   Region: [ඔබට ආසන්න region එකක්]
   ```

3. **"Create new project"** button click කරන්න

4. ⏳ **3-5 minutes රැඳී සිටින්න** - Project setup වීමට

---

## 💾 පියවර 3: Database Tables Create කරන්න

### Step 3.1: SQL Editor Open කරන්න

1. Supabase Dashboard එකේ **left sidebar** එකේ **"SQL Editor"** click කරන්න
2. **"New query"** button click කරන්න

### Step 3.2: SQL Script Copy කරන්න

1. Computer එකේ **`new cycle`** folder open කරන්න
2. **`supabase_schema.sql`** file open කරන්න
3. File එකේ **සියලු content select කර copy කරන්න**:
   - `Ctrl+A` (select all)
   - `Ctrl+C` (copy)

### Step 3.3: SQL Run කරන්න

1. Supabase SQL Editor එකේ **paste කරන්න** (`Ctrl+V`)
2. **"Run"** button click කරන්න (හෝ `Ctrl+Enter` press කරන්න)
3. ✅ **"Success. No rows returned"** message එක පෙනෙනවා නම් success!

### Step 3.4: Verify කරන්න

1. Left sidebar එකේ **"Table Editor"** click කරන්න
2. පහත **6 tables** පෙනී යනු ඇත:
   - ✅ `user_profiles`
   - ✅ `cycle_entries`
   - ✅ `wellness_articles`
   - ✅ `chat_messages`
   - ✅ `article_ratings`
   - ✅ `user_article_progress`

---

## 🔑 පියවර 4: API Keys ලබා ගන්න

### Step 4.1: Settings වෙත යන්න

1. Left sidebar එකේ **"Settings"** (⚙️ icon) click කරන්න
2. **"API"** section click කරන්න

### Step 4.2: Credentials Copy කරන්න

**Project URL:**
```
https://xxxxx.supabase.co
```
- **"Project URL"** field එකේ URL එක copy කරන්න
- Example: `https://abc123def456.supabase.co`

**Anon Key:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```
- **"anon public"** key එක copy කරන්න
- මෙය දිග key එකක් වනු ඇත (eyJ...)

---

## 📱 පියවර 5: App එකේ Configuration කරන්න

### Step 5.1: Constants File Open කරන්න

1. **`new cycle`** folder එකේ **`lib/utils/constants.dart`** file open කරන්න

### Step 5.2: Credentials Update කරන්න

**Line 10** සහ **Line 14** update කරන්න:

**Before:**
```dart
static const String supabaseUrl = 'https://dyefaijaxubadnxicskq.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**After (Your values):**
```dart
static const String supabaseUrl = 'https://YOUR-PROJECT-ID.supabase.co';
static const String supabaseAnonKey = 'YOUR-ACTUAL-ANON-KEY';
```

**⚠️ Important:** 
- `YOUR-PROJECT-ID` replace කරන්න copy කරගත් URL එකෙන්
- `YOUR-ACTUAL-ANON-KEY` replace කරන්න copy කරගත් anon key එකෙන්

### Step 5.3: File Save කරන්න

- `Ctrl+S` press කරන්න

---

## ✅ පියවර 6: Test කරන්න

### Step 6.1: App Run කරන්න

Terminal/Command Prompt එකේ:

```bash
cd "new cycle"
flutter clean
flutter pub get
flutter run
```

### Step 6.2: Test කරන්න

1. **App open වෙනවාද** check කරන්න ✅
2. **Register screen** වෙත යන්න
3. **Test account create කරන්න**:
   - Email: test@example.com
   - Password: test123456
   - Name: Test User
4. **Register** button click කරන්න
5. ✅ **Success!** Login වෙනවා

### Step 6.3: Database Check කරන්න

1. **Supabase Dashboard** වෙත යන්න
2. **"Table Editor"** > **"user_profiles"** click කරන්න
3. ✅ **ඔබේ user details පෙනී යනු ඇත!**

---

## 🎉 Success!

**Supabase backend setup complete!** 

දැන්:
- ✅ User registration works
- ✅ Login works
- ✅ Data saves to database
- ✅ Google Sign-In setup කරන්න පුළුවන්

---

## 🔐 Optional: Google Sign-In Setup

Google Sign-In enable කරන්න ඕන නම්:

1. **`GOOGLE_AUTH_SETUP.md`** file read කරන්න
2. Google Cloud Console setup කරන්න
3. Supabase Dashboard > Authentication > Providers > Google enable කරන්න

---

## ❌ Problems විසඳන හැටි

### Problem: "Table does not exist"

**Solution:**
1. SQL Editor වෙත යන්න
2. `supabase_schema.sql` content again run කරන්න
3. Table Editor වෙත යන්න - tables create වී ඇතිද check කරන්න

### Problem: "Cannot reach Supabase backend"

**Solution:**
1. `constants.dart` file එකේ URL correct වී තිබෙනවාද check කරන්න
2. Internet connection check කරන්න
3. Supabase project active වී තිබෙනවාද check කරන්න

### Problem: "Authentication failed"

**Solution:**
1. Supabase Dashboard > Authentication > Users වෙත යන්න
2. User create වී ඇතිද check කරන්න
3. Password correct වී තිබෙනවාද check කරන්න

---

## 📝 Summary

✅ **Step 1**: Supabase account create කරා  
✅ **Step 2**: Project create කරා  
✅ **Step 3**: Database tables create කරා  
✅ **Step 4**: API keys copy කරා  
✅ **Step 5**: App configuration update කරා  
✅ **Step 6**: Test කරා  

---

## 📚 Help Files

- **Quick Setup**: `HOW_TO_SETUP_SUPABASE.md`
- **Checklist**: `SETUP_CHECKLIST.md`
- **Google OAuth**: `GOOGLE_AUTH_SETUP.md`

---

**Supabase setup complete! App දැන් fully functional!** 🎊










