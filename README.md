# OvuMate - Your Personal Cycle Companion

A secure and beginner-friendly mobile application designed to help women track their menstrual cycles and improve wellness.

## 🌟 Features

### Core Features
- **Cycle Tracking**: Log periods, symptoms, and cycle phases
- **Predictions**: Accurate ovulation and fertility predictions
- **Health Chatbot**: AI-powered menstrual health support
- **Push Notifications**: Smart reminders for periods, ovulation, and medications
- **Wellness Section**: Educational articles and health tips

### Advanced Features
- **Partner Sharing**: Share cycle data with partners for mutual support
- **Lifestyle Tracking**: Monitor sleep, water intake, stress, and mood
- **Disorder Detection**: Alerts for potential cycle irregularities
- **Data Privacy**: Secure, encrypted data storage

### Optional Features
- **Analytics**: Detailed cycle insights and trends
- **Customizable Reminders**: Personalized notification settings
- **Health Profile**: Comprehensive health information tracking

## 🛠 Tech Stack

- **Frontend**: Flutter (Cross-platform mobile development)
- **Backend**: Supabase (Database, Authentication, Storage)
- **Design**: Figma (UI/UX Design)
- **Project Management**: Jira (Agile Development)
- **State Management**: Provider Pattern
- **Local Storage**: Shared Preferences & Secure Storage
- **Notifications**: Flutter Local Notifications

## 📱 Screenshots

*Screenshots will be added once the app is running*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ovumate
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Update `lib/utils/constants.dart` with your Supabase credentials:
     ```dart
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     ```

4. **Add assets**
   - Place your images in `assets/images/`
   - Place your icons in `assets/icons/`
   - Place your animations in `assets/animations/`
   - Place your fonts in `assets/fonts/`

5. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_profile.dart
│   ├── cycle_entry.dart
│   ├── wellness_article.dart
│   └── chat_message.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── cycle_provider.dart
│   ├── wellness_provider.dart
│   └── notification_provider.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── main_navigation.dart
│   ├── dashboard_screen.dart
│   ├── cycle_tracking_screen.dart
│   ├── add_entry_screen.dart
│   ├── wellness_screen.dart
│   ├── chat_screen.dart
│   └── profile_screen.dart
├── widgets/                  # Reusable widgets
│   ├── onboarding_step.dart
│   ├── cycle_overview_card.dart
│   ├── prediction_card.dart
│   ├── quick_action_card.dart
│   ├── wellness_summary_card.dart
│   └── chat_message_widget.dart
└── utils/                    # Utilities
    ├── constants.dart
    └── theme.dart
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Supabase Setup

1. **Database Tables**

   Create the following tables in your Supabase database:

   ```sql
   -- User profiles table
   CREATE TABLE user_profiles (
     id UUID REFERENCES auth.users(id) PRIMARY KEY,
     email TEXT UNIQUE NOT NULL,
     first_name TEXT,
     last_name TEXT,
     date_of_birth DATE,
     average_cycle_length INTEGER DEFAULT 28,
     average_period_length INTEGER DEFAULT 5,
     last_period_start DATE,
     notification_settings JSONB DEFAULT '{}',
     partner_sharing_enabled BOOLEAN DEFAULT false,
     privacy_settings JSONB DEFAULT '{}',
     wellness_goals TEXT[],
     health_conditions TEXT[],
     medications TEXT[],
     lifestyle_tracking_enabled BOOLEAN DEFAULT false,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Cycle entries table
   CREATE TABLE cycle_entries (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
     date DATE NOT NULL,
     cycle_phase TEXT NOT NULL,
     is_period_day BOOLEAN DEFAULT false,
     period_flow TEXT,
     symptoms JSONB DEFAULT '{}',
     notes TEXT,
     lifestyle_data JSONB DEFAULT '{}',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Wellness articles table
   CREATE TABLE wellness_articles (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     title TEXT NOT NULL,
     summary TEXT,
     content TEXT NOT NULL,
     author TEXT,
     category TEXT NOT NULL,
     difficulty TEXT DEFAULT 'beginner',
     tags TEXT[],
     image_url TEXT,
     read_time INTEGER,
     featured BOOLEAN DEFAULT false,
     premium BOOLEAN DEFAULT false,
     view_count INTEGER DEFAULT 0,
     rating_count INTEGER DEFAULT 0,
     average_rating DECIMAL(3,2) DEFAULT 0,
     published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );

   -- Chat messages table
   CREATE TABLE chat_messages (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
     content TEXT NOT NULL,
     message_type TEXT DEFAULT 'text',
     sender TEXT NOT NULL,
     quick_replies TEXT[],
     suggestions TEXT[],
     image_url TEXT,
     read BOOLEAN DEFAULT false,
     metadata JSONB DEFAULT '{}',
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   ```

2. **Row Level Security (RLS)**

   Enable RLS and create policies:

   ```sql
   -- Enable RLS
   ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE cycle_entries ENABLE ROW LEVEL SECURITY;
   ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

   -- User profiles policies
   CREATE POLICY "Users can view own profile" ON user_profiles
     FOR SELECT USING (auth.uid() = id);

   CREATE POLICY "Users can update own profile" ON user_profiles
     FOR UPDATE USING (auth.uid() = id);

   CREATE POLICY "Users can insert own profile" ON user_profiles
     FOR INSERT WITH CHECK (auth.uid() = id);

   -- Cycle entries policies
   CREATE POLICY "Users can view own cycle entries" ON cycle_entries
     FOR SELECT USING (auth.uid() = user_id);

   CREATE POLICY "Users can insert own cycle entries" ON cycle_entries
     FOR INSERT WITH CHECK (auth.uid() = user_id);

   CREATE POLICY "Users can update own cycle entries" ON cycle_entries
     FOR UPDATE USING (auth.uid() = user_id);

   CREATE POLICY "Users can delete own cycle entries" ON cycle_entries
     FOR DELETE USING (auth.uid() = user_id);

   -- Chat messages policies
   CREATE POLICY "Users can view own chat messages" ON chat_messages
     FOR SELECT USING (auth.uid() = user_id);

   CREATE POLICY "Users can insert own chat messages" ON chat_messages
     FOR INSERT WITH CHECK (auth.uid() = user_id);
   ```

## 🎨 Design System

### Colors
- **Primary**: #E91E63 (Pink)
- **Secondary**: #9C27B0 (Purple)
- **Accent**: #FF4081 (Light Pink)
- **Background**: #F8F9FA (Light Gray)
- **Text Primary**: #1A202C (Dark Gray)
- **Text Secondary**: #718096 (Medium Gray)

### Typography
- **Font Family**: Poppins
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

### Components
- **Border Radius**: 12px
- **Padding**: 16px (default), 8px (small), 24px (large)
- **Button Height**: 56px
- **Animation Duration**: 200ms (short), 300ms (medium), 500ms (long)

## 🔒 Privacy & Security

- **Data Encryption**: All sensitive data is encrypted at rest
- **Local Storage**: Sensitive data stored using Flutter Secure Storage
- **Authentication**: Supabase Auth with email/password
- **Row Level Security**: Database-level access control
- **GDPR Compliance**: User data control and deletion options

## 📊 Analytics & Insights

The app provides comprehensive cycle analytics:

- **Cycle Statistics**: Average cycle length, period length, regularity
- **Phase Tracking**: Current cycle phase and predictions
- **Symptom Patterns**: Track and analyze recurring symptoms
- **Lifestyle Correlation**: Connect lifestyle factors to cycle health
- **Trend Analysis**: Long-term cycle pattern recognition

## 🤖 Chatbot Features

The in-app health assistant provides:

- **Cycle Education**: Information about menstrual phases
- **Symptom Guidance**: Help understanding and managing symptoms
- **Fertility Support**: Ovulation and conception guidance
- **Health Tips**: Personalized wellness recommendations
- **Emergency Alerts**: When to seek medical attention

## 🔔 Notifications

Smart notification system includes:

- **Period Reminders**: Based on predicted cycle
- **Ovulation Alerts**: Fertile window notifications
- **Medication Reminders**: Custom medication schedules
- **Wellness Tips**: Daily health and wellness content
- **Partner Sharing**: Shared cycle event notifications

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🚀 Deployment

### Android
1. Generate signed APK/AAB
2. Upload to Google Play Console
3. Configure app signing
4. Submit for review

### iOS
1. Archive the app in Xcode
2. Upload to App Store Connect
3. Configure app signing
4. Submit for review

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [Link to documentation]
- **Issues**: [GitHub Issues](https://github.com/your-repo/ovumate/issues)
- **Email**: support@ovumate.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- The open-source community for various packages
- All beta testers and contributors

## 📈 Roadmap

### Version 1.1
- [ ] iOS version release
- [ ] Enhanced analytics dashboard
- [ ] More wellness articles
- [ ] Improved chatbot responses

### Version 1.2
- [ ] Partner sharing features
- [ ] Advanced lifestyle tracking
- [ ] Disorder detection algorithms
- [ ] Integration with health apps

### Version 2.0
- [ ] Web version
- [ ] Wearable device integration
- [ ] AI-powered insights
- [ ] Telemedicine integration

---

**Made with ❤️ for women's health and wellness**




















