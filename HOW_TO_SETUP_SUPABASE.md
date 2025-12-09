# Supabase Backend Setup කරන හැටි - පියවරෙන් පියවර (Step by Step)

## 📋 මොකක්ද වුනේ?

App එක Supabase backend එකට connect වීමට සූදානම්. දැන් Supabase project එක create කරගෙන app එකට connect කරන්න.

---

## 🔥 පියවර 1: Supabase Account Create කරන්න

1. Browser එක open කරන්න
2. [https://supabase.com](https://supabase.com) වෙත යන්න
3. **"Start your project"** button එක click කරන්න
4. Sign up කරන්න:
   - GitHub account එකක් හෝ
   - Email address එකක් භාවිතා කරන්න

---

## 🏗️ පියවර 2: New Project Create කරන්න

1. Dashboard එකේ ඉහල **"New Project"** button එක click කරන්න

2. Project details fill කරන්න:
   ```
   Name: OvuMate (හෝ ඔබට කැමති නමක්)
   Database Password: ශක්තිමත් password එකක් තෝරන්න
   ⚠️ මෙය save කරගන්න! (මෙය අමතක කරන්න එපා!)
   Region: Select කරන්න (කොළඹට ආසන්න)
   ```

3. **"Create new project"** button එක click කරන්න

4. ⏳ **කිහිප විනාඩියක් රැඳී සිටින්න** - Project setup වීමට

---

## 💾 පියවර 3: Database Tables Create කරන්න

### Step 3.1: SQL Editor Open කරන්න

1. Left sidebar එකේ **"SQL Editor"** click කරන්න
2. **"New query"** button එක click කරන්න

### Step 3.2: SQL Script Run කරන්න

1. **Project folder එකේ `supabase_schema.sql` file එක open කරන්න**
   
   File location: `new cycle/supabase_schema.sql`

2. **File එකේ සියලු content select කර copy කරන්න** (Ctrl+A, then Ctrl+C)

3. **Supabase SQL Editor එකේ paste කරන්න** (Ctrl+V)

4. **"Run" button එක click කරන්න** (හෝ **Ctrl+Enter** press කරන්න)

5. ✅ **"Success. No rows returned"** message එක පෙනෙනවා නම් success!

### Step 3.3: Verify කරන්න

1. Left sidebar එකේ **"Table Editor"** click කරන්න
2. ඔබට පහත tables පෙනී යනු ඇත:
   - ✅ `user_profiles`
   - ✅ `cycle_entries`
   - ✅ `wellness_articles`
   - ✅ `chat_messages`
   - ✅  `article_ratings`
   - ✅ `user_article_progress`

---

## 🔑 පියවර 4: API Keys ලබා ගන්න

1. Left sidebar එකේ **"Settings"** (⚙️ icon) click කරන්න

2. **"API"** section එක click කරන්න

3. **පහත information දෙක copy කරගන්න:**

   ### Project URL
   ```
   https://xxxxx.supabase.co
   ```
   - **"Project URL"** එක copy කරන්න
   - Example: `https://rtujdsnupkwkvnxklgzd.supabase.co`

   ### Anon Key
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
   - **"anon public"** key එක copy කරන්න
   - එය දිග key එකක් වනු ඇත
   - Example: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0dWpkc251cGt3a3ZueGtsZ3pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwOTE2MDUsImV4cCI6MjA3NzY2NzYwNX0.9Mq9z1U7QB9KYNU3UD-Hn6Sn5TRf8oKNXXTUdMdwdhw`

---

## 📱 පියවර 5: App එකේ Configuration කරන්න

1. **Project folder එක open කරන්න**

2. **`lib/utils/constants.dart` file එක open කරන්න**

3. **File එකේ පහත lines සොයාගෙන update කරන්න:**

   ```dart
   static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
   ```

4. **Copy කරගත් values replace කරන්න:**

   ```dart
   static const String supabaseUrl = 'https://rtujdsnupkwkvnxklgzd.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0dWpkc251cGt3a3ZueGtsZ3pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwOTE2MDUsImV4cCI6MjA3NzY2NzYwNX0.9Mq9z1U7QB9KYNU3UD-Hn6Sn5TRf8oKNXXTUdMdwdhw';
   ```

   ⚠️ **මෙහි YOUR_PROJECT_URL_HERE සහ YOUR_ANON_KEY_HERE replace කරන්න!** (හෝ ඔබේ project එකේ values use කරන්න)

---

## ✅ පියවර 6: App Run කර Test කරන්න

### Step 6.1: Clean කර Run කරන්න

Terminal එකේ හෝ Command Prompt එකේ:

```bash
cd "new cycle"
flutter clean
flutter pub get
flutter run
```

### Step 6.2: Test කරන්න

1. **App එක open වෙනවාද check කරන්න**

2. **Register Screen වෙත යන්න:**
   - New account create කරන්න
   - Email: test@example.com
   - Password: test123456

3. **Login කරන්න**

4. **Cycle Entry Add කරන්න:**
   - App එකේ cycle tracking section වෙත යන්න
   - New entry add කරන්න
   - Save කරන්න

5. **Supabase Dashboard Check කරන්න:**
   - Supabase website වෙත යන්න
   - Left sidebar එකේ **"Table Editor"** click කරන්න
   - **`cycle_entries`** table click කරන්න
   - ✅ **ඔබේ entry පෙනී යනු ඇත!**

---

## 🎉 Success!

ඔබේ app එක Supabase backend එකට successfully connect වී ඇත!

---

## ❌ Problems විසඳන හැටි

### Problem: "Failed to initialize Supabase"

**Solution:**
1. `constants.dart` file එකේ URL සහ Key correct වී තිබෙනවාද check කරන්න
2. Internet connection check කරන්න
3. Supabase project active වී තිබෙනවාද check කරන්න

### Problem: "Table does not exist"

**Solution:**
1. Supabase Dashboard වෙත යන්න
2. SQL Editor open කරන්න
3. `supabase_schema.sql` file එකේ content එක again run කරන්න

### Problem: "User not authenticated"

**Solution:**
1. App එකේ logout කර login again කරන්න
2. Supabase Dashboard එකේ Authentication > Users වෙත යන්න
3. User create වී ඇතිද check කරන්න

---

## 📝 Quick Checklist

- [ ] Supabase account create කරා
- [ ] New project create කරා
- [ ] SQL schema run කරා (supabase_schema.sql)
- [ ] Tables verify කරා (6 tables පෙනෙනවාද?)
- [ ] API credentials copy කරා (URL සහ Key)
- [ ] constants.dart file update කරා
- [ ] App run කරා
- [ ] Test account create කරා
- [ ] Cycle entry add කරා
- [ ] Database එකේ entry පෙනෙනවාද check කරා

---

## 🆘 Help ඕන නම්

1. **Supabase Documentation**: [https://supabase.com/docs](https://supabase.com/docs)
2. **Project files check කරන්න**:
   - `SUPABASE_BACKEND_SETUP.md` - Detailed guide
   - `supabase_schema.sql` - Database schema
   - `lib/services/supabase_service.dart` - Backend service

---

**ඔබේ Supabase backend setup complete! 🎊**

