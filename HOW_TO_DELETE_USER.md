# Supabase හි User Delete කරන හැටි

## 🗑️ පියවරෙන් පියවර Guide

### පියවර 1: Authentication Section වෙත යන්න

1. Supabase Dashboard open කරන්න
2. Left sidebar එකේ **"Authentication"** click කරන්න
3. **"Users"** section එක click කරන්න

### පියවර 2: User Select කරන්න

1. Users table හි delete කරන්න ඕන user එක click කරන්න
2. User එක select වෙනවා (highlight වෙනවා)

### පියවර 3: Delete Button සොයාගන්න

Right side panel හි scroll down කරන්න:

1. **"Danger zone"** section එකට යන්න
2. **"Delete user"** option එක සොයාගන්න
3. Description: "User will no longer have access to the project"
4. **රතු "Delete user" button** එක (trash can icon සමඟ) click කරන්න

### පියවර 4: Confirm කරන්න

1. **Confirmation dialog** එක open වෙනවා
2. Dialog හි පෙනෙනවා:
   - ⚠️ Warning icon
   - "Deleting a user is irreversible" 
   - User ගේ email address
   - "This will remove the selected user from the project and all associated data"
3. **රතු "Delete" button** එක click කරන්න

### පියවර 5: Wait කරන්න

1. User delete process start වෙනවා
2. Success message පෙනෙනවා
3. User list හි user එක remove වෙනවා

## ⚠️ Important Warnings:

### මෙය **Permanent** වේ:

- ✅ User permanently delete වෙනවා
- ✅ `auth.users` table හි user record remove වෙනවා
- ✅ `user_profiles` table හි profile automatically delete වෙනවා (ON DELETE CASCADE)
- ✅ සියලු related data delete වෙනවා:
  - Cycle entries
  - Chat messages
  - Article ratings
  - User article progress

### ඉවත් නොවන දේ:

- ❌ Backup නොකරනවා - data permanently lost
- ❌ Undo කරන්න බැහැ
- ❌ Recovery කරන්න බැහැ

## 🔍 Alternative Methods:

### Method 1: Dashboard UI (සරලම ක්‍රමය)

ඉහත පියවර follow කරන්න.

### Method 2: SQL Query (Advanced)

Supabase SQL Editor හි:

```sql
-- Delete specific user by email
DELETE FROM auth.users 
WHERE email = 'user@example.com';
```

**Note:** මෙය user සහ සියලු related data automatically delete කරනවා (CASCADE).

### Method 3: SQL Query by ID

```sql
-- Delete specific user by ID
DELETE FROM auth.users 
WHERE id = 'user-uuid-here';
```

## ✅ Verification:

User delete වී ඇත්ද check කරන්න:

1. **Users Table Check:**
   - Authentication → Users වෙත යන්න
   - User එක list හි නැතිද check කරන්න

2. **SQL Query:**
   ```sql
   -- Check if user exists
   SELECT * FROM auth.users WHERE email = 'user@example.com';
   
   -- Check if profile exists
   SELECT * FROM user_profiles WHERE email = 'user@example.com';
   ```

## 🛡️ Best Practices:

1. **Backup First:**
   - Production data නම්, delete කරන්න පෙර backup කරගන්න

2. **Test Environment:**
   - Test environment හි first test කරන්න

3. **Documentation:**
   - Delete කරපු users track කරගන්න (if needed)

4. **Confirmation:**
   - Delete කරන්න පෙර user එක correct user එකද තහවුරු කරගන්න

## 📝 Notes:

- **Auto-cleanup:** `ON DELETE CASCADE` නිසා related data automatically cleanup වෙනවා
- **RLS Policies:** User delete වෙනවිට ඔවුන්ගේ data automatically protected වෙනවා
- **Triggers:** Delete triggers run වෙනවා (if any)

## 🚨 If You Need Help:

1. Check Supabase Dashboard → Logs → Postgres Logs
2. Verify foreign key constraints
3. Check if CASCADE is properly set up

---

**Remember:** User delete කිරීම **permanent** වේ. Careful වන්න! ⚠️

