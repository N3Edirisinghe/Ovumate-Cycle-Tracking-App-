# Supabase Backend Setup Guide (සිංහල)

මෙම මාර්ගෝපදේශය මගින් ඔබේ OvuMate app එකට Supabase backend එකක් සම්පූර්ණයෙන්ම setup කරන ආකාරය පැහැදිලි කරයි.

## 📋 Table of Contents

1. [Supabase Project Create කිරීම](#1-supabase-project-create-කිරීම)
2. [Database Schema Setup](#2-database-schema-setup)
3. [API Credentials Setup](#3-api-credentials-setup)
4. [Testing](#4-testing)
5. [Features](#5-features)

---

## 1. Supabase Project Create කිරීම

### Step 1: Supabase Account Create කරන්න

1. [https://supabase.com](https://supabase.com) වෙත යන්න
2. "Start your project" button එක click කරන්න
3. GitHub account එකක් හෝ email එකක් භාවිතා කර sign up කරන්න

### Step 2: New Project Create කරන්න

1. Dashboard එකේ "New Project" button එක click කරන්න
2. Project details fill කරන්න:
   - **Name**: OvuMate (හෝ ඔබට කැමති නමක්)
   - **Database Password**: ශක්තිමත් password එකක් තෝරා ගන්න (මෙය save කරගන්න!)
   - **Region**: ඔබට ආසන්න region එකක් තෝරන්න
3. "Create new project" click කරන්න
4. Project ready වීමට කිහිප විනාඩියක් රැඳී සිටින්න

---

## 2. Database Schema Setup

### Step 1: SQL Editor වෙත යන්න

1. Supabase Dashboard එකේ left sidebar එකේ "SQL Editor" click කරන්න
2. "New query" button එක click කරන්න

### Step 2: Schema SQL Run කරන්න

1. Project root directory එකේ `supabase_schema.sql` file එක open කරන්න
2. File එකේ සියලුම content copy කරන්න
3. Supabase SQL Editor එකට paste කරන්න
4. "Run" button එක click කරන්න (හෝ Ctrl+Enter press කරන්න)

### Step 3: Verify කරන්න

1. Left sidebar එකේ "Table Editor" click කරන්න
2. ඔබට පහත tables පෙනී යනු ඇත:
   - `user_profiles`
   - `cycle_entries`
   - `wellness_articles`
   - `chat_messages`
   - `article_ratings`
   - `user_article_progress`

✅ **Success!** Database schema setup වී ඇත!

---

## 3. API Credentials Setup

### Step 1: API Credentials ලබා ගන්න

1. Supabase Dashboard එකේ left sidebar එකේ "Settings" click කරන්න
2. "API" section එක click කරන්න
3. පහත information copy කරගන්න:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...` (long key)

### Step 2: App එකේ Constants Update කරන්න

1. Project එකේ `lib/utils/constants.dart` file එක open කරන්න
2. Current values replace කරන්න:

```dart
static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
```

**Example:**
```dart
static const String supabaseUrl = 'https://dyefaijaxubadnxicskq.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR5ZWZhaWpheHViYWRueGljc2txIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU4MDE4MzAsImV4cCI6MjA3MTM3NzgzMH0.1pDr2dXN8AuZ_MHnZE_srBehaQHOeQuXJnI-KDAJwIc';
```

### Alternative: Environment Variables (Recommended for Production)

Production apps සඳහා environment variables use කරන්න:

**Create `.env` file:**
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

**Run with environment variables:**
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 4. Testing

### Step 1: App Run කරන්න

```bash
flutter clean
flutter pub get
flutter run
```

### Step 2: Test Authentication

1. App එක open කරන්න
2. Register screen එකේ new account create කරන්න
3. Login කරන්න
4. Cycle entry එකක් add කරන්න
5. Supabase Dashboard එකේ "Table Editor" වෙත යන්න
6. `cycle_entries` table එක check කරන්න - ඔබේ entry පෙනී යනු ඇත!

### Step 3: Verify Database Operations

1. **Cycle Entries**: Add, update, delete entries කර test කරන්න
2. **User Profile**: Settings screen එකේ profile update කරන්න
3. **Wellness Articles**: Articles load වන ආකාරය check කරන්න
4. **Chat Messages**: AI chat එකේ messages save වන ආකාරය test කරන්න

---

## 5. Features

### ✅ Implemented Features

මෙම backend setup සමග පහත features සියල්ල work වේ:

1. **User Authentication**
   - Email/Password sign up
   - Email/Password sign in
   - Password reset
   - Session management

2. **Cycle Tracking**
   - Cycle entries save කිරීම
   - Period tracking
   - Symptoms tracking
   - Lifestyle data (sleep, water, stress, mood)

3. **User Profiles**
   - Profile information storage
   - Cycle preferences
   - Settings sync

4. **Wellness Articles**
   - Articles storage
   - Reading progress
   - Ratings
   - Bookmarks

5. **Chat History**
   - Chat messages storage
   - Conversation history

### 🔒 Security Features

- **Row Level Security (RLS)**: සියලුම tables සඳහා RLS enabled
- **User Data Isolation**: Users ටරට තම data පමණක් access කරන්න පුළුවන්
- **Secure Authentication**: Supabase Auth service භාවිතා කරයි
- **Encrypted Storage**: Data encrypted වී store වේ

### 📱 Offline Support

- Guest users සඳහා local storage fallback
- Network issues විට automatic local storage save
- Online වීමේ දී automatic sync

---

## Troubleshooting

### Problem: "Failed to initialize Supabase"

**Solution:**
1. Check කරන්න `constants.dart` file එකේ URL සහ Key correct වී තිබෙනවාද කියලා
2. Internet connection check කරන්න
3. Supabase project active වී තිබෙනවාද check කරන්න

### Problem: "Table does not exist"

**Solution:**
1. SQL Editor වෙත යන්න
2. `supabase_schema.sql` file එකේ content එක again run කරන්න
3. Table Editor එකේ tables create වී ඇතිද check කරන්න

### Problem: "User not authenticated" error

**Solution:**
1. App එකේ login කරන්න
2. Supabase Dashboard එකේ "Authentication" > "Users" වෙත යන්න
3. User create වී ඇතිද check කරන්න

### Problem: "Row Level Security policy violation"

**Solution:**
1. SQL Editor වෙත යන්න
2. RLS policies check කරන්න - users ටරට තම data access කිරීමට permissions තිබිය යුතුයි

---

## Next Steps

1. ✅ Database schema setup complete
2. ✅ API credentials configured
3. ✅ App integrated with Supabase
4. 📱 Test all features
5. 🚀 Deploy to production!

---

## Support

මෙම setup සම්බන්ධව problems තිබෙනවා නම්:

1. Check කරන්න Supabase documentation: [https://supabase.com/docs](https://supabase.com/docs)
2. Project එකේ `SUPABASE_SETUP.md` file එක refer කරන්න
3. Error messages console එකේ check කරන්න

---

## Summary

✅ **Database Schema**: Created with all necessary tables  
✅ **Authentication**: Integrated with Supabase Auth  
✅ **Data Storage**: Cycle entries, profiles, articles, chat messages  
✅ **Security**: Row Level Security enabled  
✅ **Offline Support**: Local storage fallback for guest users  

**Your Supabase backend is now fully set up and ready to use!** 🎉










