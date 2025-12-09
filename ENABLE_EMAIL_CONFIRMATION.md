# Email Confirmation Setup - Register විට Email එකක් යවනවා

## 📧 Requirement:

User register කරනවිට, confirmation email එකක් automatically send විය යුතුයි.

## ✅ Supabase Dashboard Setup:

### Step 1: Enable Email Confirmation

1. **Supabase Dashboard** වෙත යන්න: https://supabase.com/dashboard
2. Project select කරන්න
3. **Authentication** → **Settings** වෙත යන්න
4. **"Enable email confirmations"** toggle **ON** කරන්න ✅
5. Save කරන්න

### Step 2: Configure Email Templates (Optional)

1. **Authentication** → **Email Templates** වෙත යන්න
2. **"Confirm signup"** template edit කරන්න
3. Customize කරන්න (optional)

### Step 3: Configure SMTP (For Custom Email)

Default Supabase email service use කරන්නනම්, මෙය setup කරන්න ඕනේ නැහැ.

Custom SMTP use කරන්නනම්:
1. **Authentication** → **Settings** → **SMTP Settings**
2. Your SMTP credentials add කරන්න

## 🔧 Code Changes:

Code එක already configured වී තියෙනවා! Supabase automatically email send කරනවා when `signUp` is called.

### Current Flow:

1. User register form fill කරයි
2. `auth_provider.dart` → `signUp()` function call වෙයි
3. Supabase `auth.signUp()` call වෙයි
4. **Supabase automatically sends confirmation email** (if enabled)
5. User email එකේ confirmation link click කරයි
6. User account confirmed වෙයි
7. User login කරන්න පුළුවන්

## 📝 Verification:

### Check Email is Sent:

1. User register කරන්න
2. Email inbox check කරන්න (spam folder එකත් check කරන්න)
3. Supabase වලින් email එකක් ආවාද check කරන්න
4. Confirmation link click කරන්න

### Check in Supabase Dashboard:

1. **Authentication** → **Users** වෙත යන්න
2. New user select කරන්න
3. **"Email Confirmed"** status check කරන්න:
   - ❌ **False** = User email verify කරලා නැහැ
   - ✅ **True** = User email verify කරලා

## 🛠️ Test Registration:

1. App run කරන්න
2. Register screen එකට යන්න
3. Details fill කරලා register කරන්න:
   - Email: test@example.com
   - Password: test123456
   - First Name: Test
   - Last Name: User
4. Email inbox check කරන්න
5. Confirmation link click කරන්න
6. App එකෙන් login try කරන්න

## ⚠️ Important Notes:

### Email Confirmation Disabled නම්:
- User register වෙනවා direct
- Email confirmation නැහැ
- Direct login විය හැකියි

### Email Confirmation Enabled නම්:
- User register වෙනවා
- Email එකක් send වෙයි
- User email verify කරන්න ඕන
- Verify කරලා නැතිව login කරන්න බෑ

## 🔍 Troubleshooting:

### Email නෑනෙ නම්:

1. **Check Supabase Settings:**
   - Authentication → Settings → Enable email confirmations = **ON**

2. **Check Spam Folder:**
   - Email spam/junk folder එකත් check කරන්න

3. **Check Email Address:**
   - Valid email address එකක් use කරන්න

4. **Check SMTP Settings:**
   - Custom SMTP use කරනවානම්, settings correct වී තිබෙනවාද check කරන්න

5. **Resend Confirmation Email:**
   - Supabase Dashboard → Authentication → Users
   - User select කරන්න
   - **"Send magic link"** button click කරන්න

### User Login කරන්න බෑ (Email Not Confirmed):

1. Supabase Dashboard → Authentication → Users
2. User select කරන්න
3. **"Confirm Email"** manually කරන්න (හෝ)
4. User ට confirmation email resend කරන්න

## 📧 Email Template Customization:

Custom email template use කරන්නනම්:

1. Supabase Dashboard → Authentication → Email Templates
2. **"Confirm signup"** template edit කරන්න
3. Customize subject, body, etc.
4. Save කරන්න

## ⚠️ IMPORTANT: Redirect URL Configuration

Email confirmation links work කරන්නනම්, Supabase Dashboard හි redirect URLs configure කරන්න ඕන:

### Fix Redirect URLs:

1. **Supabase Dashboard** → **Authentication** → **Settings**
2. **"Site URL"** field එකේ තියෙනවා:
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co
   ```
   (localhost නොවෙයි!)

3. **"Redirect URLs"** section එකේ add කරන්න:
   ```
   https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback
   io.supabase.ovumate://
   io.supabase.ovumate://confirm
   ```

4. **Save** කරන්න

**Details:** `FIX_EMAIL_CONFIRMATION_REDIRECT.md` file එක check කරන්න.

---

**Current Status:** Code already configured! Just enable email confirmation and configure redirect URLs in Supabase Dashboard.

