# 🔴 Password Reset Email Not Arriving

## ⚠️ Problem:

Password reset button click කරනවිට "email sent" message එනවා, නමුත් Gmail එකට email එක නොපැමිණෙනවා.

---

## 🔍 Possible Causes:

### 1. Email Confirmation Still Enabled

**Most Common Issue:** "Confirm email" toggle එක ON වී තියෙනවා.

**Fix:**
1. Supabase Dashboard → Authentication → Sign In / Providers
2. "Confirm email" toggle OFF කරන්න ⚪
3. Save changes
4. Wait 5 minutes
5. Try again

---

### 2. Email Going to Spam/Junk Folder

**Check:**
- Gmail Spam folder
- Junk folder
- Promotions tab (Gmail)

---

### 3. Email Not Registered

**Check:**
- Supabase Dashboard → Authentication → Users
- Email එක registered වී තියෙනවාද check කරන්න

---

### 4. Supabase Email Not Configured

**Check:**
- Supabase Dashboard → Settings → Email
- Email provider configured කරලා තියෙනවාද

---

### 5. Rate Limiting

**Issue:** Too many requests in short time

**Fix:**
- Wait 5-10 minutes
- Try again

---

## ✅ Step-by-Step Fix:

### Step 1: Disable Email Confirmation

1. Go to: https://supabase.com/dashboard/project/rtujdsnupkwkvnxklgzd/auth/providers
2. Find "Confirm email" toggle
3. Turn it OFF ⚪
4. Save changes
5. Wait 5 minutes

---

### Step 2: Verify Email is Registered

1. Go to: https://supabase.com/dashboard/project/rtujdsnupkwkvnxklgzd/auth/users
2. Check if your email is in the list
3. If not, register first

---

### Step 3: Check Spam Folder

1. Open Gmail
2. Check Spam folder
3. Check Junk folder
4. Check Promotions tab

---

### Step 4: Try Again

1. Wait 5 minutes after disabling email confirmation
2. Go to app
3. Click "Forgot Password"
4. Enter email
5. Submit
6. Check email (including spam)

---

## 🎯 Quick Fix (Recommended):

**Disable "Confirm email" toggle:**

1. Supabase Dashboard → Authentication → Sign In / Providers
2. "Confirm email" toggle OFF කරන්න ⚪
3. Save changes
4. Wait 5 minutes
5. Try password reset again

---

## 📝 Checklist:

- [ ] "Confirm email" toggle = OFF ⚪
- [ ] Email is registered in Supabase
- [ ] Checked spam/junk folder
- [ ] Waited 5 minutes after disabling
- [ ] Tried again with NEW request

---

## 🆘 If Still Not Working:

1. **Check Supabase Email Settings:**
   - Go to Settings → Email
   - Make sure email is configured

2. **Try Different Email:**
   - Use a different email address
   - Register new user
   - Then try password reset

3. **Check Supabase Logs:**
   - Go to Logs → Email
   - See if emails are being sent

---

**Most likely issue: "Confirm email" toggle ON වී තියෙනවා. එය OFF කරන්න!** ✅

