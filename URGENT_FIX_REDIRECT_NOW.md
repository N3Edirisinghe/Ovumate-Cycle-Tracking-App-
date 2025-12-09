# 🔴 URGENT: Fix Redirect Error NOW

## 🔴 You're Seeing:
```
{"error":"requested path is invalid"}
```
URL: `rtujdsnupkwkvnxklgzd.supabase.co/#access_token=...`

**This means:** Supabase created the token but can't find a valid redirect path.

---

## ✅ IMMEDIATE FIX (Do This NOW):

### Step 1: Go to URL Configuration

**Direct link:**
```
https://supabase.com/dashboard/project/rtujdsnupkwkvnxklgzd/auth/url-configuration
```

---

### Step 2: Fix Site URL (CRITICAL!)

1. **Find "Site URL" field**
2. **Check what's there:**
   - If it says `https://rtujdsnupkwkvnx` → **DELETE IT**
   - If it's empty → Good
   
3. **Type EXACTLY this:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co
   ```
   
4. **VERIFY:**
   - ✅ Complete URL (not cut off)
   - ✅ No trailing slash
   - ✅ Starts with `https://`

5. **Click "Save changes"**

---

### Step 3: Add Redirect URL (IMPORTANT!)

1. **Scroll to "Redirect URLs" section**
2. **Delete ALL existing URLs** (if any)
3. **Click "Add URL"**
4. **Add this FIRST:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback
   ```
5. **Click "Add URL" again**
6. **Add this SECOND:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co
   ```
7. **Click "Add URL" again**
8. **Add this THIRD:**
   ```
   io.supabase.ovumate://reset-password
   ```
9. **Click "Save changes"**

---

### Step 4: WAIT 10 MINUTES

**CRITICAL:** Don't test immediately!

- Set a timer for 10 minutes
- Wait the full time
- Changes need to propagate

---

### Step 5: Request NEW Password Reset

**Don't use old email links!**

1. **Go to your app**
2. **Click "Forgot Password"**
3. **Enter email**
4. **Check email for NEW reset link**
5. **Click the NEW link** (not old ones)

---

## 🎯 Why This Works:

The error happens because Supabase generates a token but doesn't know where to redirect it. By adding:
- `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback` ← This is the callback URL
- `https://rtujdsnupkwkvnxklgzd.supabase.co` ← This is the base URL

Supabase will know where to redirect the token.

---

## ✅ Quick Checklist:

- [ ] Site URL = `https://rtujdsnupkwkvnxklgzd.supabase.co` (complete)
- [ ] Redirect URL 1 = `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`
- [ ] Redirect URL 2 = `https://rtujdsnupkwkvnxklgzd.supabase.co`
- [ ] Redirect URL 3 = `io.supabase.ovumate://reset-password`
- [ ] All saved
- [ ] Waited 10 minutes
- [ ] Requested NEW password reset
- [ ] Clicked NEW link

---

## 🆘 If Still Not Working:

1. **Double-check Site URL** - must be complete
2. **Make sure callback URL is added** - this is critical
3. **Wait longer** - try 15 minutes
4. **Clear browser cache** - try incognito mode
5. **Use NEW email** - old links won't work

---

**The callback URL is the most important one - make sure it's added!** ✅

