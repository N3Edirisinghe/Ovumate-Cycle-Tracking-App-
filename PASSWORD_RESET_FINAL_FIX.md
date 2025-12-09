# 🔴 Password Reset Error - Final Fix Guide

## Current Status:
- ✅ Email template: Correct (uses `{{ .ConfirmationURL }}`)
- ✅ Redirect URLs: Correct (4 URLs configured)
- ✅ Code: Using base Site URL
- ❌ Still getting: `{"error":"requested path is invalid"}`

## 🔍 Root Cause:
The error happens when Supabase generates the `ConfirmationURL` but the path doesn't match the allowed redirect URLs.

## ✅ SOLUTION: Verify Site URL EXACTLY

### Step 1: Check Site URL in Dashboard

1. Go to: https://supabase.com/dashboard/project/rtujdsnupkwkvnxklgzd/auth/url-configuration

2. Find "Site URL" field (ABOVE the Redirect URLs list)

3. **It MUST be EXACTLY:**
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co
   ```

4. **Check for:**
   - ✅ Starts with `https://`
   - ✅ Complete domain (not cut off)
   - ✅ No trailing slash
   - ✅ No spaces before/after
   - ✅ Matches exactly: `https://rtujdsnupkwkvnxklgzd.supabase.co`

5. **If wrong:**
   - Select ALL text (Ctrl+A)
   - Delete
   - Type: `https://rtujdsnupkwkvnxklgzd.supabase.co`
   - Click "Save changes"

### Step 2: Verify Redirect URLs

Must have these EXACT URLs (in order):
1. `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`
2. `https://rtujdsnupkwkvnxklgzd.supabase.co`
3. `io.supabase.ovumate://reset-password`
4. `io.supabase.ovumate://confirm`

### Step 3: Save and Wait

1. Click "Save changes" button
2. Wait for success message
3. **Wait 10 minutes** (critical!)

### Step 4: Test with NEW Email

1. **Delete ALL old password reset emails**
2. App restart කරන්න
3. Request NEW password reset
4. Use ONLY the NEW email link

## 🔄 Alternative: Use Browser-Based Reset

If error persists, use browser-based reset:

1. **Click email link in browser** (Chrome, Firefox, etc.)
2. **Should show Supabase hosted password reset page**
3. **Set new password there**
4. **Then login to app**

## 📝 Debugging Steps

If still not working:

1. **Check email link URL:**
   - Right-click link in email
   - "Copy link address"
   - Check what URL it contains
   - Should contain: `rtujdsnupkwkvnxklgzd.supabase.co`

2. **Check Supabase Logs:**
   - Dashboard → Logs → Auth
   - Filter by "password reset"
   - See what errors appear

3. **Verify Site URL one more time:**
   - Site URL field එකේ exact value එක copy කරන්න
   - Must match: `https://rtujdsnupkwkvnxklgzd.supabase.co` exactly

## ✅ Expected Result

After fixing:
- Click email link → Opens browser
- Shows Supabase password reset page
- Set new password
- Login to app






