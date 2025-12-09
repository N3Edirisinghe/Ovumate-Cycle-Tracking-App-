# ⏱️ Rate Limit Error - Wait and Retry

## ⚠️ Error Message:

```
"For security purposes, you can only request this after 32 seconds."
```

**This is NOT a code error!** This is Supabase's **rate limiting** for security.

---

## ✅ What This Means:

Supabase limits how many password reset requests you can make in a short time. This prevents:
- Spam attacks
- Email flooding
- Abuse

**You requested password reset too quickly!**

---

## ✅ Solution:

### Simple Fix: Wait!

1. **Wait 60 seconds** (or the time shown in error)
2. **Then try again**
3. **Should work!**

---

## 📝 Why This Happens:

- Requested password reset multiple times quickly
- Supabase rate limits password reset requests
- Must wait before requesting again

---

## ✅ Best Practice:

1. **Request password reset ONCE**
2. **Wait for email** (check spam folder)
3. **If email doesn't arrive:**
   - Wait 5 minutes
   - Check spam folder again
   - Then request again (not immediately!)

---

## 🎯 Code Updated:

Code එක update කරා to show better error message:
- Shows wait time from error
- Clearer message in Sinhala and English
- Better user guidance

---

## ✅ Summary:

**This is normal security behavior!**

**Just wait 60 seconds and try again.** ✅

---

**Rate limit එක normal security feature එකක්. මිනිත්තු 1ක් බලලා නැවත try කරන්න!** ✅








