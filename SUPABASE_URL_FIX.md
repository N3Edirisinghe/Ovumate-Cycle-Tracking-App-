# Supabase URL Error Fix - "This site can't be reached"

## ❌ Problem

Google Sign-In button click කරනවා නම් browser එකේ එන error:
- `This site can't be reached`
- `dyefaijaxubadnxicskq.supabase.co` - DNS_PROBE_FINISHED_NXDOMAIN
- Domain not found

## ✅ Cause

Supabase backend properly setup නැත හෝ URL incorrect වී තිබෙනවා.

---

## 🔧 Solution

### Option 1: Supabase Project Create කරගන්න (Recommended)

1. **Supabase Project Setup:**
   - [https://supabase.com](https://supabase.com) වෙත යන්න
   - Sign up/Login කරන්න
   - New project create කරන්න
   - Project URL copy කරගන්න

2. **Update Constants:**
   - `lib/utils/constants.dart` file open කරන්න
   - Your actual Supabase URL update කරන්න:

```dart
static const String supabaseUrl = 'https://YOUR-PROJECT-ID.supabase.co';
static const String supabaseAnonKey = 'YOUR-ACTUAL-ANON-KEY';
```

3. **Complete Setup:**
   - `HOW_TO_SETUP_SUPABASE.md` guide follow කරන්න
   - SQL schema run කරන්න
   - Google OAuth configure කරන්න

---

### Option 2: Use Without Supabase (Temporary)

දැන් Supabase setup නැතිවත් app work වේ, නමුත් Google Sign-In work නොවේ.

**Temporary solution:**
- Email/Password registration use කරන්න
- Google Sign-In disable කරන්න (optional)

---

## 📋 Quick Checklist

- [ ] Supabase project create කරා
- [ ] Project URL copy කරා
- [ ] Anon key copy කරා
- [ ] `constants.dart` update කරා
- [ ] SQL schema run කරා
- [ ] Google OAuth setup කරා

---

## 🆘 Help Files

1. **Complete Setup**: `HOW_TO_SETUP_SUPABASE.md`
2. **Checklist**: `SETUP_CHECKLIST.md`
3. **Google Auth**: `GOOGLE_AUTH_SETUP.md`

---

**දැන් Supabase setup කරන්න - app fully functional වෙනවා!** 🚀










