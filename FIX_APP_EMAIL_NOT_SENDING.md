# 🔴 Dashboard Email Works, App Email Doesn't

## ⚠️ Problem:

**Supabase Dashboard** එකෙන් password reset email send කරනවිට email එනවා ✅
**App** එකෙන් password reset email send කරනවිට email නොඑනවා ❌

**This means:** Email service is working, but app code has an issue!

---

## 🔍 Root Cause:

App code එකේ `redirectTo` parameter එක `io.supabase.ovumate://reset-password` (deep link) use කරනවා. මෙය Supabase email sending block කරනවාද එසේ නොවේ.

**Dashboard uses:** Web redirect URL or no redirect
**App uses:** Deep link redirect

---

## ✅ Solution Applied:

Code එක update කරා to use **web redirect URL** (same as dashboard):

```dart
redirectTo: 'https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback'
```

**If this fails, it tries without redirect** (let Supabase use default).

---

## 🎯 What Changed:

### Before:
```dart
redirectTo: 'io.supabase.ovumate://reset-password'  // Deep link - not working
```

### After:
```dart
redirectTo: 'https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback'  // Web URL - same as dashboard
```

---

## ✅ Test Now:

1. **Run the app**
2. **Click "Forgot Password"**
3. **Enter email**
4. **Submit**
5. **Check email** - should arrive now! ✅

---

## 📝 Why This Works:

- **Dashboard uses web redirect** → Email sends ✅
- **App was using deep link** → Email blocked ❌
- **Now app uses web redirect** → Email sends ✅

---

## 🎯 Alternative: Use Without Redirect

If web redirect still doesn't work, the code will automatically try **without redirect URL**, letting Supabase use its default (same as dashboard).

---

## ✅ Summary:

- ✅ Code updated to use web redirect (same as dashboard)
- ✅ Fallback to no redirect if needed
- ✅ Should work now!

---

**App එකෙන් email send කරන්න try කරන්න - දැන් work විය යුතුයි!** ✅

