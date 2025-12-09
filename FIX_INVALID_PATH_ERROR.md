# Fix "requested path is invalid" Error

## ❌ Problem
Browser eke email link click karana vela `{"error":"requested path is invalid"}` error ekak thiyenawa.

## 🔍 Root Cause
Supabase Dashboard eke **Redirect URLs** properly configured kara thiyenawa na.

## ✅ Solution: Fix Supabase Redirect URLs

### Step 1: Go to Supabase Dashboard
1. **Supabase Dashboard** → https://supabase.com/dashboard
2. Your project select karanawa
3. **Authentication** → **URL Configuration** click karanawa

### Step 2: Add Redirect URLs
**"Redirect URLs"** section eke me URLs tika add karanawa:

```
io.supabase.ovumate://confirm
io.supabase.ovumate://reset-password
https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback
```

### Step 3: Fix Site URL
**"Site URL"** field eke me URL eka set karanawa:
```
https://rtujdsnupkwkvnxklgzd.supabase.co
```

**NOT:** `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback` (wrong!)

### Step 4: Save Changes
1. **"Save"** button click karanawa
2. **Wait 2-3 minutes** (configuration propagate venna)
3. **Try again**

## 🔧 Alternative: Browser-Based Reset (Works Immediately)

Email link eka browser eke open karanawa:

1. **Email eke link eka copy karanawa**
2. **Browser eke paste karanawa** (Chrome, Safari, etc.)
3. **Password reset karanawa**
4. **App eke login karanawa**

Mehema deep link issues bypass karanawa.

## ✅ Expected Result

After fixing redirect URLs:
- Email links properly work venawa
- No "invalid path" error
- Password reset/email confirmation work venawa

## 🆘 If Still Not Working

1. **Clear browser cache**
2. **Use incognito/private mode**
3. **Try different browser**
4. **Wait 5 minutes** after saving Supabase settings

---

**Most Important: Fix the Redirect URLs in Supabase Dashboard!** ✅


