# 🌸 Ovumate: Cycle Tracking App

<div align="center">
  <p><strong>A secure and beginner-friendly mobile application designed to help women track their menstrual cycles and improve wellness.</strong></p>
</div>

---

## 📖 Overview

**Ovumate** is a comprehensive menstrual cycle tracking application built with **Flutter** and powered by **Supabase**. It provides users with a seamless, intuitive, and private way to monitor their cycles, predict future periods, and track wellness metrics over time. The application is designed to be beginner-friendly while functioning completely offline-first with secure cloud synchronization.

## ✨ Features

- **Cycle Tracking:** Accurately track menstrual cycles, ovulation days, and fertile windows.
- **Symptom & Mood Logging:** Log daily symptoms, moods, sleep patterns, and physical wellness.
- **AI-Powered Insights:** Get personalized recommendations and wellness insights based on your cycle data.
- **Secure Data Storage:** End-to-end encryption ensures user data remains completely private.
- **Offline Mode:** Fully functional without an internet connection, automatically syncing to the cloud when online.
- **Notifications & Reminders:** Configurable localized alerts for upcoming periods, ovulation, and pill reminders.
- **PDF Reports:** Generate and export cycle data reports for medical consultations.
- **Multi-Language Support:** Fully localized for English, Sinhala, and Tamil.

---

## 🛠️ Technology Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Provider
- **Backend as a Service (BaaS):** Supabase (PostgreSQL, Authentication)
- **Local Storage:** SharedPreferences & Flutter Secure Storage
- **UI Components:** Cupertino Icons, Flutter SVG, Lottie, FL Chart
- **Localization:** Easy Localization

---

## 🚀 Getting Started

Follow these instructions to set up the project on your local machine for development and testing.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0 <4.0.0`)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code
- A [Supabase](https://supabase.com/) Account & Project

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/N3Edirisinghe/Ovumate-Cycle-Tracking-App-.git
   cd "Ovumate-Cycle-Tracking-App-"
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root directory and add your Supabase credentials. Ensure `.env` is added to your `.gitignore`.
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
lib/
├── core/                # Core configurations, constants, and utilities
├── features/            # Feature-wise modules (e.g., auth, cycle_tracking, wellness)
├── models/              # Data models and entities
├── providers/           # State management logic
├── services/            # API integration, database, and background services
├── ui/                  # Shared widgets and screens
└── main.dart            # Application entry point
```

---

## 🔒 Security & Privacy

We take user privacy seriously. All sensitive health data is anonymized and securely encrypted on the device before cloud synchronization. 

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 👨‍💻 Author

**Nilupul Thisaranga (N3Edirisinghe)**
- GitHub: [@N3Edirisinghe](https://github.com/N3Edirisinghe)
- Email: [10nilupulthisaranga@gmail.com](mailto:10nilupulthisaranga@gmail.com)

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">Made with ❤️ for Women's Health.</p>
