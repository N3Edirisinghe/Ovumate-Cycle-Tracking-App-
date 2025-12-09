# Fix Email Verification Error

## The Problem
You're getting this error when clicking the email verification link:
```
?error=invalid_request&error_code=bad_oauth_callback&error_description=OAuth+state+parameter+missing
{"error":"requested path is invalid"}
```

## The Solution

### Step 1: Configure Redirect URLs in Supabase Dashboard

1. Go to your Supabase Dashboard: https://app.supabase.com
2. Select your project
3. Go to **Authentication** → **URL Configuration**
4. In the **Redirect URLs** section, add these URLs (one per line):

```
https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback
http://localhost/
io.supabase.ovumate://login-callback
```

5. Click **Save**

### Step 2: Update Email Templates in Supabase Dashboard

1. Go to **Authentication** → **Email Templates**
2. For **Confirm signup** template, replace the entire content with:

```html
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your email:</p>
<p><a href="{{ .SiteURL }}/auth/v1/callback?token_hash={{ .TokenHash }}&type=email">Confirm your email</a></p>
```

3. Click **Save**

### Step 3: Update Site URL

1. Still in **Authentication** → **URL Configuration**
2. Make sure **Site URL** is set to:
```
https://rtujdsnupkwkvnxklgzd.supabase.co
```

3. Click **Save**

## Why This Happens

The error occurs because:
1. Email verification links need a proper redirect URL configured in Supabase
2. The default email template uses a redirect URL that's not in your allowed list
3. When you click the link, Supabase rejects it because it doesn't recognize the redirect destination

## After Making These Changes

1. Create a new test account with a new email
2. Check your email for the confirmation link
3. Click the link - it should work now!
4. You'll see a success page, then you can login to the app

## Alternative: Disable Email Confirmation (Not Recommended)

If you want to skip email verification for testing:

1. Go to **Authentication** → **Providers** → **Email**
2. Turn OFF **"Confirm email"**
3. Click **Save**

**Note:** This is not recommended for production apps as it allows anyone to sign up without verifying their email.

## Test It

1. Delete your current test user (if needed)
2. Create a new account
3. Check your email
4. Click the confirmation link
5. You should see a success page instead of an error!
