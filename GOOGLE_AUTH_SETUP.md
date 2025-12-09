# Google Sign-In Setup Guide (Gmail Authentication)

මෙම guide එක මගින් app එකේ Google Sign-In (Gmail) authentication setup කරන හැටි පැහැදිලි කරයි.

## 📋 Requirements

1. ✅ Supabase project setup වී තිබිය යුතුය
2. ✅ Google Cloud Console account
3. ✅ Supabase project URL

---

## 🔥 Step 1: Google Cloud Console Setup

### 1.1 Create Google Cloud Project

1. [Google Cloud Console](https://console.cloud.google.com/) වෙත යන්න
2. Sign in with your Google account
3. Top bar එකේ project dropdown click කරන්න
4. **"New Project"** click කරන්න
5. Project name: `OvuMate` (හෝ ඔබට කැමති නමක්)
6. **"Create"** button click කරන්න

### 1.2 Enable Google+ API

1. Left sidebar එකේ **"APIs & Services"** > **"Library"** click කරන්න
2. Search box එකේ "Google+ API" type කරන්න
3. **"Google+ API"** select කරන්න
4. **"Enable"** button click කරන්න

### 1.3 Create OAuth 2.0 Credentials

1. Left sidebar එකේ **"APIs & Services"** > **"Credentials"** click කරන්න
2. **"+ CREATE CREDENTIALS"** button click කරන්න
3. **"OAuth client ID"** select කරන්න
4. First time නම්, **"Configure consent screen"** button click කරන්න:
   - User Type: **External** select කරන්න
   - App name: `OvuMate`
   - User support email: ඔබේ email
   - Developer contact: ඔබේ email
   - **"Save and Continue"** click කරන්න
   - Scopes: Default scopes ප්‍රමාණවත් - **"Save and Continue"** click කරන්න
   - Test users: නැත - **"Save and Continue"** click කරන්න
   - **"Back to Dashboard"** click කරන්න

5. **"OAuth client ID"** create කරන්න:
   - Application type: **Web application** select කරන්න
   - Name: `OvuMate Web Client`
   - Authorized redirect URIs: Add these:
     ```
     https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
     ```
     (Replace `YOUR_PROJECT_REF` with your Supabase project reference)
   - **"Create"** button click කරන්න

6. **Client ID** සහ **Client Secret** copy කරගන්න:
   - Client ID: `123456789-abc...`
   - Client Secret: `GOCSPX-abc...`

---

## 🔧 Step 2: Supabase Configuration

### 2.1 Enable Google Provider in Supabase

1. Supabase Dashboard වෙත යන්න
2. Left sidebar එකේ **"Authentication"** > **"Providers"** click කරන්න
3. **"Google"** provider find කරන්න
4. **Enable Google provider** toggle on කරන්න

### 2.2 Add Google OAuth Credentials

1. **Client ID (for OAuth)** field එකේ Google Cloud Console එකෙන් copy කරගත් Client ID paste කරන්න
2. **Client Secret (for OAuth)** field එකේ Client Secret paste කරන්න
3. **"Save"** button click කරන්න

### 2.3 Configure Redirect URL

1. Supabase Dashboard එකේ **"Settings"** > **"Authentication"** click කරන්න
2. **"Site URL"** field check කරන්න:
   ```
   https://YOUR_PROJECT_REF.supabase.co
   ```
3. **"Redirect URLs"** section එකේ add කරන්න:
   ```
   io.supabase.ovumate://login-callback
   com.ovumate.app://login-callback
   ```

---

## 📱 Step 3: App Configuration

### 3.1 Android Configuration

1. `android/app/build.gradle.kts` file open කරන්න
2. Ensure `minSdkVersion` is at least 21

3. `android/app/src/main/AndroidManifest.xml` file check කරන්න:
   ```xml
   <activity
       android:name=".MainActivity"
       android:launchMode="singleTop"
       android:exported="true">
       <intent-filter>
           <action android:name="android.intent.action.MAIN"/>
           <category android:name="android.intent.category.LAUNCHER"/>
       </intent-filter>
       
       <!-- Deep linking for OAuth callback -->
       <intent-filter>
           <action android:name="android.intent.action.VIEW"/>
           <category android:name="android.intent.category.DEFAULT"/>
           <category android:name="android.intent.category.BROWSABLE"/>
           <data android:scheme="io.supabase.ovumate"/>
       </intent-filter>
   </activity>
   ```

### 3.2 iOS Configuration

1. `ios/Runner/Info.plist` file open කරන්න
2. Add URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>io.supabase.ovumate</string>
           </array>
       </dict>
   </array>
   ```

---

## ✅ Step 4: Test Google Sign-In

1. App run කරන්න:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Login screen වෙත යන්න
3. **"Continue with Google"** button click කරන්න
4. Google account select කරන්න
5. Permissions approve කරන්න
6. ✅ Success! User database එකේ save වී ඇත!

---

## 🔍 Verify User Data in Database

1. Supabase Dashboard වෙත යන්න
2. **"Table Editor"** > **"user_profiles"** click කරන්න
3. ✅ Google account එකෙන් sign in කළ user details පෙනී යනු ඇත!

---

## 🔐 Password Setup for Google Users

Google account එකෙන් sign in කළ usersට password setup කරන්න පුළුවන්:

### In App:
1. Settings screen වෙත යන්න
2. Security section වෙත යන්න
3. "Set Password" option click කරන්න
4. Password enter කරන්න
5. Save කරන්න

මෙයින් පසු usersට email/password එකකින් login වන්න පුළුවන්!

---

## ❌ Troubleshooting

### Problem: "Redirect URI mismatch"

**Solution:**
1. Google Cloud Console වෙත යන්න
2. OAuth 2.0 Client IDs section වෙත යන්න
3. Authorized redirect URIs check කරන්න
4. Supabase callback URL add කරන්න:
   ```
   https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
   ```

### Problem: "OAuth consent screen not configured"

**Solution:**
1. Google Cloud Console වෙත යන්න
2. "OAuth consent screen" configure කරන්න
3. All required fields fill කරන්න
4. Save කරන්න

### Problem: "User not created in database"

**Solution:**
1. Supabase Dashboard වෙත යන්න
2. Authentication > Users section check කරන්න
3. User create වී ඇතිද verify කරන්න
4. If user exists but profile doesn't, try signing in again

---

## 📝 Summary

✅ **Google Cloud Console**: OAuth credentials create කරා  
✅ **Supabase**: Google provider enable කරා  
✅ **App**: Google Sign-In button add කරා  
✅ **Database**: User profiles automatically save වේ  
✅ **Password**: Google usersට password setup කරන්න පුළුවන්  

**Your Google Sign-In is now fully configured!** 🎉

---

## 📚 Additional Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth Setup](https://developers.google.com/identity/protocols/oauth2)
- [Supabase OAuth Guide](https://supabase.com/docs/guides/auth/social-login/auth-google)










