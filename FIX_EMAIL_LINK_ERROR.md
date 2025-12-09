# 🔴 Email Arrives But Link Shows Error

## ✅ Good News:

**Email එනවා!** ✅ Email sending is now working!

## 🔴 Problem:

Email link click කරනවිට error එක එනවා:
- `error=access_denied&error_code=otp_expired`
- `{"error":"requested path is invalid"}`

**This means:** The redirect URL in the email link is not matching Supabase configuration.

---

## ✅ Solution:

### Option 1: Use Web Redirect (Recommended)

The email link should redirect to a web page, not directly to the app.

**Fix:**
1. Go to: https://supabase.com/dashboard/project/rtujdsnupkwkvnxklgzd/auth/url-configuration
2. Make sure **Site URL** is: `https://rtujdsnupkwkvnxklgzd.supabase.co`
3. Make sure these redirect URLs are added:
   - `https://rtujdsnupkwkvnxklgzd.supabase.co`
   - `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`
4. Save changes
5. Wait 5 minutes
6. Request NEW password reset email
7. Click NEW link

---

### Option 2: Check Email Link Format

The email link should look like:
```
https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/verify?token=...
```

**NOT:**
```
https://rtujdsnupkwkvnxklgzd.supabase.co/#error=...
```

---

### Option 3: Use Supabase Hosted Reset Page

Instead of deep links, use the web-based password reset:

1. **Click the email link in browser** (not in app)
2. **Should redirect to Supabase hosted page**
3. **Set new password there**
4. **Then login to app**

---

## 🔍 Check These:

### 1. Site URL
- Must be: `https://rtujdsnupkwkvnxklgzd.supabase.co`
- Complete, no trailing slash

### 2. Redirect URLs
Must have:
- `https://rtujdsnupkwkvnxklgzd.supabase.co`
- `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`

### 3. "Confirm email" Toggle
- Should be OFF ⚪ (for testing)

---

## ✅ Quick Fix:

1. **Open email link in browser** (not app)
2. **Should show Supabase password reset page**
3. **Set new password**
4. **Login to app**

---

## 🎯 Why This Happens:

The email link contains a redirect URL that Supabase doesn't recognize. This happens when:
- Redirect URL not in allowed list
- Site URL is wrong
- Deep link not configured properly

**Solution:** Use web redirect URLs (same as dashboard uses).

---

**Email link එක browser එකේ open කරලා password reset කරන්න - app එකෙන් direct open කරන්න එපා!** ✅








