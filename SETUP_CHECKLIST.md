# ✅ Supabase Setup Checklist

මෙම checklist එක follow කරන්න Supabase backend setup කිරීමට.

---

## 📝 Setup Checklist

### 🔵 Step 1: Supabase Account & Project
- [ ] [supabase.com](https://supabase.com) වෙත ගොස් sign up කරා
- [ ] "New Project" create කරා
- [ ] Project name: __________
- [ ] Database password save කරගත්තා: __________
- [ ] Project ready වීමට රැඳී සිටියා

### 🔵 Step 2: Database Tables Create කරන්න
- [ ] SQL Editor open කරා
- [ ] `supabase_schema.sql` file එක open කරා
- [ ] File content copy කරා
- [ ] SQL Editor එකේ paste කරා
- [ ] "Run" button click කරා
- [ ] Success message පෙනුනා
- [ ] Table Editor වෙත ගොස් 6 tables පෙනෙනවාද check කරා:
  - [ ] user_profiles
  - [ ] cycle_entries
  - [ ] wellness_articles
  - [ ] chat_messages
  - [ ] article_ratings
  - [ ] user_article_progress

### 🔵 Step 3: API Credentials Copy කරන්න
- [ ] Settings > API වෙත ගියා
- [ ] **Project URL** copy කරා:
  ```
  https://__________________________________
  ```
- [ ] **anon public key** copy කරා:
  ```
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  ```

### 🔵 Step 4: App Configuration
- [ ] `lib/utils/constants.dart` file එක open කරා
- [ ] Line 10: supabaseUrl update කරා
- [ ] Line 14: supabaseAnonKey update කරා
- [ ] File save කරා

### 🔵 Step 5: App Run & Test
- [ ] Terminal/Command Prompt open කරා
- [ ] `flutter clean` run කරා
- [ ] `flutter pub get` run කරා
- [ ] `flutter run` run කරා
- [ ] App open වුනා

### 🔵 Step 6: Testing
- [ ] Register screen වෙත ගියා
- [ ] Test account create කරා:
  - Email: __________
  - Password: __________
- [ ] Login කරා
- [ ] Cycle entry add කරා
- [ ] Supabase Dashboard වෙත ගියා
- [ ] Table Editor > cycle_entries table check කරා
- [ ] ✅ Entry database එකේ පෙනෙනවා!

---

## 🎉 Setup Complete!

ඔබේ Supabase backend සාර්ථකව setup වී ඇත!

---

## 📚 Help Files

- **Detailed Guide**: `HOW_TO_SETUP_SUPABASE.md`
- **Full Documentation**: `SUPABASE_BACKEND_SETUP.md`
- **SQL Schema**: `supabase_schema.sql`

---

## ⚠️ Important Notes

1. **Database Password**: අමතක කරන්න එපා! එය save කරගන්න
2. **API Keys**: Public anon key එක safe - share කරන්න පුළුවන්
3. **Project URL**: Private නොවේ - share කරන්න පුළුවන්

---

**Good Luck! 🍀**










