# Fix Email Confirmation Redirect Error

## 🔴 ගැටලුව:

Email confirmation link click කරනවිට `localhost:7898` error එක එනවා. Mobile device හි localhost use කරන්න බෑ.

## 🔍 හේතුව:

Supabase Dashboard හි **Site URL** සහ **Redirect URLs** configuration වැරදිව setup කරලා තියෙනවා.

## ✅ විසඳුම:

### Step 1: Supabase Dashboard වෙත යන්න

1. **Supabase Dashboard** open කරන්න: https://supabase.com/dashboard
2. Project select කරන්න (`rtujdsnupkwkvnxklgzd`)
3. **Authentication** menu click කරන්න
4. **Settings** tab එක click කරන්න

### Step 2: Site URL Update කරන්න

1. Scroll down කරන්න **"URL Configuration"** section එකට
2. **"Site URL"** field එකේ දැන් `http://localhost:7898` තියෙනවා
3. මෙය **change කරන්න** පහත URL එකට:

```
https://rtujdsnupkwkvnxklgzd.supabase.co
```

**හෝ** mobile app සඳහා deep link scheme එකක් use කරන්න:

```
io.supabase.ovumate://
```

### Step 3: Redirect URLs Add කරන්න

1. **"Redirect URLs"** section එකට scroll down කරන්න
2. **"Redirect URLs"** list එකේ **Add URL** button click කරන්න
3. පහත URLs add කරන්න (එක එකක් add කරන්න):

```
https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback
io.supabase.ovumate://
io.supabase.ovumate://login-callback
io.supabase.ovumate://confirm
com.supabase.ovumate://
```

**Important:** 
- එක එක URL enter කරලා **Add** button click කරන්න
- මෙය allow කරනවා mobile app වලින් email confirmation links handle කරන්න

### Step 4: Save කරන්න

1. **"Save"** button click කරන්න (page එකේ bottom හි)
2. Changes save වෙනවා

## 📱 Mobile App Configuration (Optional - Deep Links)

Mobile app එකෙන් email confirmation handle කරන්නනම්, deep link configuration add කරන්න:

### Android:

`android/app/src/main/AndroidManifest.xml` file එකේ:

```xml
<activity
    android:name=".MainActivity"
    ...>
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Deep link for email confirmation -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="io.supabase.ovumate"/>
    </intent-filter>
</activity>
```

### iOS:

`ios/Runner/Info.plist` file එකේ:

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

## 🎯 Simple Solution (Recommended):

**වඩාත්ම සරල විසඳුම:** Site URL එක Supabase project URL එකට set කරන්න:

1. **Supabase Dashboard** → **Authentication** → **Settings**
2. **"Site URL"** = `https://rtujdsnupkwkvnxklgzd.supabase.co`
3. **"Redirect URLs"** add කරන්න:
   - `https://rtujdsnupkwkvnxklgzd.supabase.co/auth/v1/callback`
   - `io.supabase.ovumate://`
4. Save කරන්න

මෙයින් email confirmation links Supabase hosted page එකකට redirect වෙයි, එතැනින් automatically app එකට redirect වෙයි.

## ✅ Test කරන්න:

1. Supabase Dashboard හි settings save කරන්න
2. App run කරන්න
3. New user register කරන්න
4. Email inbox check කරන්න
5. Confirmation email එකේ link click කරන්න
6. ✅ **මෙවර localhost error නෑ, confirmation successful!**

## 📝 Alternative: Email Confirmation Disable කරන්න

Development/testing සඳහා email confirmation disable කරන්නනම්:

1. **Supabase Dashboard** → **Authentication** → **Settings**
2. **"Enable email confirmations"** toggle **OFF** කරන්න
3. Save කරන්න

මෙයින් register වෙනවා direct, email confirmation නැහැ.

---

**Most Important:** Site URL එක `https://rtujdsnupkwkvnxklgzd.supabase.co` වෙනස් කරන්න!

