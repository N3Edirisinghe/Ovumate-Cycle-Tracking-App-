# Backend Setup නැතිව Google Sign-In Error

## ❌ Problem

Google Sign-In button click කරනවා නම්:
- Browser එක open වෙනවා
- Error message: "This site can't be reached"
- `dyefaijaxubadnxicskq.supabase.co` - DNS_PROBE_FINISHED_NXDOMAIN

## ✅ Cause

**Supabase backend properly setup නැත!**

Constants file එකේ තියෙන URL එක invalid project එකක් point කරනවා.

---

## 🔧 Solutions

### Solution 1: Supabase Setup කරන්න (Recommended)

#### Step 1: Supabase Project Create කරන්න

1. [https://supabase.com](https://supabase.com) වෙත යන්න
2. Sign up/Login කරන්න
3. **"New Project"** create කරන්න:
   - Name: `OvuMate`
   - Database Password: (strong password එකක්)
   - Region: Select කරන්න
4. **Wait for project to be ready** (2-3 minutes)

#### Step 2: Get Your Credentials

1. Supabase Dashboard එකේ **Settings** > **API** click කරන්න
2. Copy these:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGci...` (long key)

#### Step 3: Update App Configuration

1. `lib/utils/constants.dart` file open කරන්න
2. Update කරන්න:

```dart
static const String supabaseUrl = 'https://YOUR-PROJECT-ID.supabase.co';
static const String supabaseAnonKey = 'YOUR-ACTUAL-ANON-KEY';
```

#### Step 4: Setup Database

1. SQL Editor වෙත යන්න
2. `supabase_schema.sql` file content copy කරන්න
3. Paste කර Run කරන්න

#### Step 5: Setup Google OAuth

1. **Google Cloud Console** setup කරන්න (see `GOOGLE_AUTH_SETUP.md`)
2. Supabase Dashboard > Authentication > Providers > Google enable කරන්න
3. Client ID සහ Secret add කරන්න

#### Step 6: Test

```bash
flutter clean
flutter pub get
flutter run
```

---

### Solution 2: Temporary - Use Email/Password Only

Supabase setup කරන්න ඕන නම් later, දැන් email/password registration use කරන්න:

1. **Google Sign-In button click නොකරන්න**
2. **Email/Password fields** use කරන්න
3. Register/Login කරන්න

App එක work වේ, නමුත් Google Sign-In work නොවේ.

---

## ⚠️ Important Notes

### Current Status:
- ❌ Supabase URL: Invalid/Not found
- ❌ Google Sign-In: Not working (backend නැති නිසා)
- ✅ Email/Password: Works (local storage)
- ✅ App Features: Work (offline mode)

### After Supabase Setup:
- ✅ All features work
- ✅ Google Sign-In works
- ✅ Cloud sync enabled
- ✅ Multi-device access

---

## 📋 Quick Setup Checklist

- [ ] Supabase account create කරා
- [ ] New project create කරා
- [ ] Project URL copy කරා
- [ ] Anon key copy කරා
- [ ] `constants.dart` update කරා
- [ ] SQL schema run කරා
- [ ] Google OAuth setup කරා
- [ ] Test කරා

---

## 📚 Detailed Guides

1. **Complete Setup**: `HOW_TO_SETUP_SUPABASE.md`
2. **Step-by-step**: `SUPABASE_BACKEND_SETUP.md`
3. **Google OAuth**: `GOOGLE_AUTH_SETUP.md`
4. **Checklist**: `SETUP_CHECKLIST.md`

---

## 🎯 Summary

**Problem**: Supabase backend setup නැත  
**Solution**: Supabase project create කරගෙන credentials update කරන්න  
**Temporary**: Email/Password use කරන්න (Google Sign-In skip කරන්න)  

**Setup guide follow කරන්න - app fully functional වෙනවා!** 🚀










