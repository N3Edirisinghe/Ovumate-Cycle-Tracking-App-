# Fix "Database error deleting user" - පියවරෙන් පියවර

## 🔴 ගැටලුව:

Supabase Dashboard හි user delete කරන්න උත්සාහ කරනවිට:
```
Failed to delete user: Database error deleting user
```

## 🔍 හේතුව:

`user_profiles` table හි foreign key constraint එක `ON DELETE CASCADE` නැති නිසා, `auth.users` table හි user delete කරනවිට related profile delete කරන්න බැහැ.

## ✅ විසඳුම:

### Quick Fix Script Run කරන්න:

1. **Supabase Dashboard → SQL Editor** වෙත යන්න

2. **`FIX_USER_DELETE_ERROR_NOW.sql` file එක open කරන්න**

3. **සියලු content copy කරන්න** (Ctrl+A, Ctrl+C)

4. **SQL Editor හි paste කර run කරන්න** (Ctrl+V, Run button)

5. ✅ **Success message check කරන්න:**
   - "Dropped old constraint without CASCADE" (නැත්නම්)
   - "Created foreign key constraint with CASCADE"
   - Query results හි `delete_rule` column එකේ **"CASCADE"** පෙනෙනවාද check කරන්න

### Verify කරන්න:

Script run කරනවිට query results හි පෙනෙනවා:

| constraint_name | table_name | delete_rule | status |
|----------------|------------|-------------|--------|
| user_profiles_id_fkey | user_profiles | CASCADE | ✅ CASCADE is enabled |

**"CASCADE is enabled"** පෙනෙනවා නම් success!

## 🔄 දැන් User Delete Test කරන්න:

1. **Supabase Dashboard → Authentication → Users** වෙත යන්න
2. Test user කෙනෙක් select කරන්න
3. **"Delete user" button** click කරන්න
4. **Confirm** කරන්න
5. ✅ **User successfully delete වෙනවාද check කරන්න**

## 🛠️ Alternative: Manual Fix (Advanced)

SQL Editor හි අනෙක් commands:

```sql
-- Check current constraint
SELECT 
    conname,
    contype,
    confdeltype
FROM pg_constraint
WHERE conname = 'user_profiles_id_fkey';

-- Drop and recreate with CASCADE
ALTER TABLE user_profiles DROP CONSTRAINT user_profiles_id_fkey;

ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_id_fkey 
FOREIGN KEY (id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;
```

## ✅ After Fix:

දැන් user delete කරනවිට:

- ✅ `auth.users` table හි user delete වෙනවා
- ✅ `user_profiles` table හි profile automatically delete වෙනවා
- ✅ සියලු related data (cycle_entries, chat_messages, etc.) automatically delete වෙනවා

## 🔍 Troubleshooting:

### Problem: Still getting error after fix

**Check:**
```sql
-- Verify constraint exists with CASCADE
SELECT delete_rule 
FROM information_schema.referential_constraints 
WHERE constraint_name = 'user_profiles_id_fkey';
```

Should show: **CASCADE**

### Problem: Constraint doesn't exist

**Solution:**
```sql
ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_id_fkey 
FOREIGN KEY (id) 
REFERENCES auth.users(id) 
ON DELETE CASCADE;
```

## 📝 Notes:

- Fix කිරීමෙන් පසු existing data නැසී නොයනවා
- New users සඳහා automatically CASCADE work වෙනවා
- Old users delete කරන්න දැන් පුළුවන්

---

**Fix script run කරලා user delete test කරන්න!** 🚀
