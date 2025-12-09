# 🔴 URGENT: Fix "site url is improperly formatted" Error

## 🔴 Error You're Seeing:
```
{"code":500,"error_code":"unexpected_failure","msg":"site url is improperly formatted"}
```

**This happens at:** `rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`

**Root Cause:** Supabase Dashboard Site URL is incorrectly configured!

---

## ✅ IMMEDIATE FIX:

### Step 1: Go to Supabase Dashboard

**Direct link:**
```
https://supabase.com/dashboard/project/rtujdsnupkwkvnxklgzd/auth/url-configuration
```

---

### Step 2: Fix Site URL (CRITICAL!)

1. **Find "Site URL" field** (at the top)
2. **DELETE everything** currently in that field
3. **Type EXACTLY this:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co
   ```
   
4. **VERIFY:**
   - ✅ Starts with `https://`
   - ✅ Complete domain name (no truncation)
   - ✅ NO trailing slash (`/`)
   - ✅ No extra spaces
   - ✅ Matches exactly: `https://rtujdsnupkwkvnxklgzd.supabase.co`

5. **Click "Save"**

---

### Step 3: Check Redirect URLs

1. **Scroll to "Redirect URLs" section**
2. **Delete ALL existing URLs** (if any are wrong)
3. **Add these URLs ONE BY ONE:**

   **First URL:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback
   ```
   
   **Second URL:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co
   ```
   
   **Third URL (for deep links):**
   ```
   io.supabase.ovumate://reset-password
   ```

4. **Click "Save" after adding each URL**

---

### Step 4: Common Site URL Mistakes to Avoid

❌ **WRONG:**
- `rtujdsnupkwkvnxklgzd.supabase.co` (missing https://)
- `https://rtujdsnupkwkvnxklgzd.supabase.co/` (trailing slash)
- `https://rtujdsnupkwkvnxklgzd.supabase` (incomplete)
- `http://rtujdsnupkwkvnxklgzd.supabase.co` (http instead of https)

✅ **CORRECT:**
- `https://rtujdsnupkwkvnxklgzd.supabase.co` (exactly this!)

---

### Step 5: WAIT 5-10 MINUTES

**CRITICAL:** Configuration changes need time to propagate!

- Set a timer
- Wait the full time
- Don't test immediately

---

### Step 6: Request NEW Password Reset

**Don't use old email links!**

1. **Go to your app**
2. **Click "Forgot Password"**
3. **Enter email**
4. **Wait for NEW email** (don't use old links)
5. **Click the NEW reset link**

---

## 🎯 Why This Happens:

Supabase validates the Site URL format when processing authentication callbacks. If the Site URL is:
- Missing
- Incorrectly formatted
- Has trailing slashes
- Uses wrong protocol

It will throw "site url is improperly formatted" error.

---

## ✅ Verification Checklist:

After fixing, verify:

- [ ] Site URL is exactly: `https://rtujdsnupkwkvnxklgzd.supabase.co`
- [ ] No trailing slash
- [ ] Starts with `https://`
- [ ] Redirect URLs are added
- [ ] Waited 5-10 minutes
- [ ] Requested NEW password reset email
- [ ] Clicked NEW link (not old)

---

## 🔍 If Still Not Working:

1. **Clear browser cache** and try again
2. **Check Supabase logs** in dashboard for more details
3. **Verify email link** opens in browser (not app initially)
4. **Check** if email confirmation is enabled (should be OFF for testing)

---

**Fix the Site URL in Supabase Dashboard NOW - this is the root cause!** ✅

