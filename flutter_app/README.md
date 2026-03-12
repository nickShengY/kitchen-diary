# Kitchen Diary - Flutter App

A sophisticated recipe and cooking community app with AI-powered features, built with Flutter for iOS and Android.

## Features

### Core Features
- 🍳 **Recipe Builder** - Create step-by-step visual recipes with ingredients, tools, and cooking actions
- 🌍 **Community/Explore** - Discover recipes from chefs worldwide with social features
- 🎯 **Decider Wheel** - Spin to pick a cuisine and dish when you can't decide
- 👤 **Profile Management** - Track your recipes, followers, and cooking stats

### VIP Features ($5.99/month)
- 📸 **AI Menu Scanner** - Scan restaurant menus and get AI-powered dish recommendations
- ✨ **Premium Animations** - Enhanced visual effects in recipe builder
- 🧠 **AI Meal Planning** - Get personalized weekly meal suggestions
- 📊 **Advanced Nutrition** - Detailed nutritional analysis for recipes
- ♾️ **Unlimited Recipes** - Save unlimited recipes and collections
- 🚫 **No Ads** - Ad-free experience

### Technology Stack
- **Flutter 3.x** - Cross-platform UI framework
- **Firebase** - Authentication, Firestore, Storage
- **Google Gemini AI** - Menu scanning with structured outputs
- **RevenueCat** - Subscription management
- **Provider** - State management

## Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode
- Firebase project
- Google Cloud project with Gemini API enabled
- RevenueCat account

### Installation

1. **Clone the repository**
   ```bash
   cd flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Google Sign-In, Email/Password)
   - Enable Cloud Firestore
   - Enable Firebase Storage
   - Run FlutterFire CLI:
     ```bash
     flutterfire configure
     ```
   - This will update `lib/firebase_options.dart` with your config

4. **Configure Gemini API**
   - Get an API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Add to your environment:
     ```bash
     flutter run --dart-define=GEMINI_API_KEY=your_api_key
     ```

5. **Configure RevenueCat**
   - Create a project at [RevenueCat](https://www.revenuecat.com)
   - Set up products (vip_monthly at $5.99, vip_yearly at $49.99)
   - Update API keys in `lib/services/subscription_service.dart`

6. **Add Google Fonts**
   Download Poppins font family and place in `assets/fonts/`:
   - Poppins-Regular.ttf
   - Poppins-Medium.ttf
   - Poppins-SemiBold.ttf
   - Poppins-Bold.ttf
   - Poppins-ExtraBold.ttf

7. **Create asset directories**
   ```bash
   mkdir -p assets/images assets/icons assets/animations assets/fonts
   ```

8. **Run the app**
   ```bash
   flutter run
   ```

### Android Configuration

1. Update `android/app/build.gradle`:
   ```gradle
   android {
       defaultConfig {
           minSdkVersion 21
           targetSdkVersion 34
       }
   }
   ```

2. Add Google Sign-In configuration in `android/app/src/main/AndroidManifest.xml`

### iOS Configuration

1. Add to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

2. Enable camera and photo library permissions for menu scanning

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── core/
│   ├── theme/               # App theme and colors
│   └── router/              # GoRouter configuration
├── models/                  # Data models
│   ├── user_model.dart
│   ├── recipe_model.dart
│   └── community_model.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── recipe_provider.dart
│   ├── community_provider.dart
│   └── subscription_provider.dart
├── services/                # Business logic
│   ├── auth_service.dart
│   ├── gemini_service.dart
│   └── subscription_service.dart
├── screens/                 # UI screens
│   ├── splash_screen.dart
│   ├── auth/
│   ├── main/
│   ├── recipe/
│   ├── community/
│   ├── settings/
│   └── menu_scanner/
├── widgets/                 # Reusable widgets
│   ├── common/
│   └── recipe/
└── data/                    # Static data
    └── kitchen_data.dart
```

## Firestore Data Structure

```
users/
  {userId}/
    - email, displayName, photoUrl, bio
    - avatarEmoji, isVip, vipExpiresAt
    - followers[], following[]
    - favoriteRecipes[], savedRecipes[]
    - recipesCount, likesReceived
    - badges[], preferences

recipes/
  {recipeId}/
    - title, description, authorId
    - steps[], tags[], imageUrl
    - likes, views, commentsCount
    - servings, prepTimeMinutes, cookTimeMinutes
    - difficulty, mealType, cuisine[]
    - isPublic, isFeatured

forum_posts/
  {postId}/
    - title, content, authorId
    - category, tags[], imageUrls[]
    - likes, commentsCount, views
    - isPinned, isClosed

comments/
  {commentId}/
    - recipeId, authorId, content
    - likes, parentCommentId
    - repliesCount

challenges/
  {challengeId}/
    - title, description
    - startDate, endDate
    - participantsCount, prizes[]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For support, email support@kitchendiary.app
