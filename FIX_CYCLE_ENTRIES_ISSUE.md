# Cycle Entries Dashboard හි පෙනෙන්නේ නැති ගැටලුව Fix කරන හැටි

## 🔴 ගැටලුව:

Cycle entries add කරනවිට Supabase dashboard හි `cycle_entries` table එකේ පෙනෙන්නේ නැතිවීම. Authentication emails පමණක් `auth.users` table එකේ පෙනෙනවා.

## 🔍 හේතුව:

1. User sign up වෙනවිට `auth.users` table එකේ record create වෙනවා
2. නමුත් `user_profiles` table එකේ record create නොවෙනවා
3. `cycle_entries` table එකේ foreign key constraint එක `user_profiles(id)` reference කරනවා
4. එම නිසා `user_profiles` table එකේ user record නැති නිසා cycle entry insert fail වෙනවා

## ✅ විසඳුම:

### පියවර 1: Updated SQL Schema Run කරන්න

1. Supabase Dashboard → SQL Editor වෙත යන්න
2. `supabase_schema.sql` file එකේ **updated content** copy කරන්න (auto-create trigger සමඟ)
3. SQL Editor හි paste කර run කරන්න

**Important:** මෙම schema හි `handle_new_user()` function එකක් සහ trigger එකක් අලුතෙන් add කරලා තියෙනවා. මෙය new users sign up වන විට automatically `user_profiles` table එකේ record create කරනවා.

### පියවර 2: Existing Users සඳහා Profiles Create කරන්න

ඔබට already sign up වූ users තියෙනවා නම්:

1. `supabase_fix_existing_users.sql` file එක open කරන්න
2. Content එක copy කරන්න
3. Supabase SQL Editor හි paste කර run කරන්න
4. මෙය existing users සඳහා `user_profiles` records create කරනවා

### පියවර 3: Test කරන්න

1. App එකේ logout කරන්න (ඇත්නම්)
2. New account create කරන්න හෝ existing account එකක් login කරන්න
3. Cycle entry add කරන්න
4. Supabase Dashboard → Table Editor → `cycle_entries` table වෙත යන්න
5. ✅ Entry පෙනෙනවාද check කරන්න

## 🔍 Troubleshooting:

### Problem: Still not working after running the fix

**Solution 1:** Check if trigger was created:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

**Solution 2:** Check if user has profile:
```sql
SELECT 
  au.id,
  au.email,
  up.id as profile_id
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.id
WHERE au.email = 'your-email@example.com';
```

**Solution 3:** Manually create profile for specific user:
```sql
INSERT INTO user_profiles (id, email, created_at, updated_at)
SELECT id, email, created_at, NOW()
FROM auth.users
WHERE email = 'your-email@example.com'
ON CONFLICT (id) DO NOTHING;
```

### Problem: RLS Policy blocking inserts

Check RLS policies:
```sql
SELECT * FROM pg_policies WHERE tablename = 'cycle_entries';
```

## 📝 Notes:

- Trigger එක `SECURITY DEFINER` ලෙස run වෙන නිසා RLS policies bypass කරනවා
- `ON CONFLICT DO NOTHING` නිසා duplicate entries create නොවෙනවා
- New users sign up වන විට automatically profile create වෙනවා

## ✅ Success Indicators:

- ✅ New user sign up වෙන විට automatically `user_profiles` table එකේ record create වෙනවා
- ✅ Cycle entries add කරනවිට database එකට successfully save වෙනවා
- ✅ Supabase Dashboard හි `cycle_entries` table එකේ entries පෙනෙනවා

---

**ගැටලුවක් තියෙනවා නම්:** Supabase Dashboard → Logs → Postgres Logs වෙත යන්න සහ errors check කරන්න.

