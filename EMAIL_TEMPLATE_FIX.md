# Email Template Fix - "requested path is invalid"

## ❌ Problem
Confirmation email click karana vela `{"error":"requested path is invalid"}` error ekak thiyenawa.

## 🔍 Root Cause
Email template eke generate venna URL eka Supabase Redirect URLs eke thiyenawa na.

## ✅ Solution: Check Email Template

### Step 1: Go to Email Templates
1. **Supabase Dashboard** → **Authentication** → **Email Templates**
2. **"Confirm signup"** template click karanawa

### Step 2: Check Template Content
Template eke me format eka thiyenawa nam check karanawa:

**Subject:**
```
Confirm your signup
```

**Body should have:**
```
Follow this link to confirm your user:
{{ .ConfirmationURL }}
```

### Step 3: Reset to Default (If Edited)
1. Template edit kara thiyenawa nam, **"Reset to default"** button click karanawa
2. **Save** karanawa
3. Mehema Supabase default URL format use karanawa

### Step 4: Verify Redirect URLs Again
Make sure these URLs are in Redirect URLs:
1. `https://rtujdsnupkwkvnxklgzd.supabase.co`
2. `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`
3. `io.supabase.ovumate://reset-password`
4. `io.supabase.ovumate://confirm`

## 🔧 Code Fix Applied

Code eka update kara Site URL directly use karanna set kara:
- **Before:** `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`
- **After:** `https://rtujdsnupkwkvnxklgzd.supabase.co`

Supabase automatically callback path append karanawa.

## ✅ Next Steps

1. **Email template reset karanawa** (if edited)
2. **Wait 5 minutes**
3. **App eke Hot Restart** (Ctrl+Shift+\)
4. **NEW verification email request karanawa**
5. **Browser eke link eka open karanawa**

## 🆘 Alternative: Disable Email Confirmation

Testing karanna oni nam:
1. **Supabase Dashboard** → **Authentication** → **Settings**
2. **"Enable email confirmations"** toggle **OFF** karanawa
3. **Save** karanawa
4. App eke register karanawa - immediately login venawa

---

**Most Important: Reset email template to default and use NEW emails!** ✅


