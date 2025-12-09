# Fix "Invalid login credentials" Error

## 🔴 ගැටලුව:

Correct email සහ password එකෙන් login කරනවිට "Invalid login credentials" error එක එනවා.

## 🔍 හේතු (Possible Causes):

### 1. Email Confirmation Required
Supabase project එකේ email confirmation enable කරලා තියෙනවානම්, user email verify කරන්න ඕන.

**Check කරන්න:**
- Supabase Dashboard → Authentication → Settings
- "Enable email confirmations" check කරන්න enabled ද

### 2. Password Reset Issue
Password change වී තිබිය හැකියි.

### 3. Email Format Issues
- Email හි spaces තියෙනවාද check කරන්න
- Case sensitivity issues

### 4. User Not Created Properly
User sign up වෙලා නැති විය හැකියි.

## ✅ විසඳුම්:

### Solution 1: Email Confirmation Check කරන්න

1. **Supabase Dashboard** වෙත යන්න
2. **Authentication → Settings** වෙත යන්න
3. **"Enable email confirmations"** check කරන්න:
   - **Enabled** නම් → User email verify කරන්න ඕන
   - **Disabled** නම් → Direct login විය යුතුයි

### Solution 2: Disable Email Confirmation (Development)

Development/testing සඳහා email confirmation disable කරන්න:

1. Supabase Dashboard → Authentication → Settings
2. **"Enable email confirmations"** toggle off කරන්න
3. Save කරන්න

### Solution 3: Password Reset කරන්න

1. Login screen හි **"Forgot Password"** link click කරන්න
2. Email reset link එකක් request කරන්න
3. Email එකේ reset link click කරන්න
4. New password set කරන්න

### Solution 4: User Verify කරන්න

Supabase Dashboard හි:

1. **Authentication → Users** වෙත යන්න
2. User select කරන්න
3. **"Send magic link"** button click කරන්න (හෝ)
4. User එක manually confirm කරන්න

## 🛠️ Code Fix (Better Error Messages)

Better error handling add කරලා exact error message show කරන්න:

```dart
try {
  final response = await _supabase!.auth.signInWithPassword(
    email: email.trim(), // Trim spaces
    password: password,
  );
} on AuthException catch (e) {
  if (e.message.contains('Invalid login credentials')) {
    _setError('Email or password is incorrect. Please check and try again.');
  } else if (e.message.contains('Email not confirmed')) {
    _setError('Please verify your email address first. Check your inbox for the confirmation link.');
  } else {
    _setError('Login failed: ${e.message}');
  }
}
```

## 📝 Quick Checklist:

- [ ] Email confirmation enabled/disabled check කරලා
- [ ] Email spaces නැතිද check කරන්න (trim කරන්න)
- [ ] Password correct වී තිබෙනවාද double check කරන්න
- [ ] Supabase Dashboard හි user exist වී තිබෙනවාද check කරන්න
- [ ] User email verified වී තිබෙනවාද check කරන්න

## 🔍 Verify User Exists:

SQL Editor හි:
```sql
SELECT id, email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'your-email@example.com';
```

මෙය show කරනවා:
- User exists වී තිබෙනවාද
- Email confirmed වී තිබෙනවාද

---

**මොකක්ද වුනේ කියලා check කරන්න:** Supabase Dashboard → Authentication → Settings → Email confirmations

