# Kitchen Diary - Deployment & Publishing Guide

## 📋 Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Neon Database Setup](#neon-database-setup)
3. [Service Wiring Architecture](#service-wiring-architecture)
4. [Firebase Configuration](#firebase-configuration)
5. [API Keys & Secrets](#api-keys--secrets)
6. [App Store Deployment](#app-store-deployment)
7. [Image Generation Script](#image-generation-script)

---

## 🔍 Pre-Deployment Checklist

### Required Accounts & Services

| Service | Purpose | Registration URL |
|---------|---------|------------------|
| **Firebase** | Auth, Firestore, Storage, Analytics | https://console.firebase.google.com |
| **Neon** | PostgreSQL for user data, forum, recipes | https://neon.tech |
| **Google Cloud** | Gemini AI API | https://console.cloud.google.com |
| **Apple Developer** | iOS App Store publishing | https://developer.apple.com |
| **Google Play Console** | Android publishing | https://play.google.com/console |
| **RevenueCat** (optional) | Subscription management | https://www.revenuecat.com |

### Required API Keys

```bash
# Firebase (auto-generated in firebase_options.dart)
- FIREBASE_API_KEY
- FIREBASE_AUTH_DOMAIN
- FIREBASE_PROJECT_ID
- FIREBASE_STORAGE_BUCKET
- FIREBASE_MESSAGING_SENDER_ID
- FIREBASE_APP_ID

# Neon PostgreSQL
- NEON_DATA_API_URL       # e.g., https://YOUR-PROJECT.neon.tech/rest/v1
- NEON_DATA_API_KEY       # Service role key
- NEON_USER_API_URL       # Same as above or separate project
- NEON_USER_API_KEY       # Service role key

# Google/Gemini
- GEMINI_API_KEY          # For AI features

# RevenueCat (if using)
- REVENUECAT_API_KEY_IOS
- REVENUECAT_API_KEY_ANDROID
```

---

## 🗄️ Neon Database Setup

### Step 1: Create Neon Project
1. Go to https://console.neon.tech
2. Create a new project (e.g., "kitchen-diary")
3. Choose a region closest to your users
4. Note your connection string

### Step 2: Database Schema

Run these SQL commands in the Neon SQL Editor:

```sql
-- ============================================================
-- USERS TABLE
-- ============================================================
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    photo_url TEXT,
    avatar_emoji TEXT DEFAULT '👨‍🍳',
    bio TEXT,
    is_vip BOOLEAN DEFAULT FALSE,
    vip_expires_at TIMESTAMPTZ,
    recipes_count INTEGER DEFAULT 0,
    likes_received INTEGER DEFAULT 0,
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    streak_days INTEGER DEFAULT 0,
    last_streak_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_display_name ON users(display_name);

-- ============================================================
-- USER FOLLOWS (followers/following)
-- ============================================================
CREATE TABLE user_follows (
    id SERIAL PRIMARY KEY,
    follower_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    following_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(follower_id, following_id)
);

CREATE INDEX idx_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_follows_following ON user_follows(following_id);

-- ============================================================
-- USER SAVED RECIPES
-- ============================================================
CREATE TABLE user_saved_recipes (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    saved_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, recipe_id)
);

CREATE INDEX idx_saved_user ON user_saved_recipes(user_id);

-- ============================================================
-- USER BADGES
-- ============================================================
CREATE TABLE user_badges (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    badge_id TEXT NOT NULL,
    awarded_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, badge_id)
);

CREATE INDEX idx_badges_user ON user_badges(user_id);

-- ============================================================
-- USER PREFERENCES
-- ============================================================
CREATE TABLE user_preferences (
    user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    preferences JSONB DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- COOKING HISTORY
-- ============================================================
CREATE TABLE cooking_history (
    id SERIAL PRIMARY KEY,
    user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    cooked_at TIMESTAMPTZ DEFAULT NOW(),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    notes TEXT,
    photo_urls TEXT[]
);

CREATE INDEX idx_history_user ON cooking_history(user_id);
CREATE INDEX idx_history_recipe ON cooking_history(recipe_id);

-- ============================================================
-- FORUM POSTS
-- ============================================================
CREATE TABLE forum_posts (
    id SERIAL PRIMARY KEY,
    author_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT DEFAULT 'general',
    image_url TEXT,
    tags TEXT[],
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_posts_category ON forum_posts(category);
CREATE INDEX idx_posts_author ON forum_posts(author_id);

-- ============================================================
-- FORUM COMMENTS
-- ============================================================
CREATE TABLE forum_comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES forum_posts(id) ON DELETE CASCADE,
    author_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    content TEXT NOT NULL,
    parent_id INTEGER REFERENCES forum_comments(id) ON DELETE CASCADE,
    likes_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_post ON forum_comments(post_id);

-- ============================================================
-- RECIPES (if storing in Neon instead of Firestore)
-- ============================================================
CREATE TABLE recipes (
    id TEXT PRIMARY KEY,
    author_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    prep_time INTEGER,
    cook_time INTEGER,
    servings INTEGER,
    difficulty TEXT,
    cuisine TEXT,
    dietary_tags TEXT[],
    ingredients JSONB,
    steps JSONB,
    nutrition JSONB,
    likes_count INTEGER DEFAULT 0,
    saves_count INTEGER DEFAULT 0,
    cook_count INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    forked_from TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_recipes_author ON recipes(author_id);
CREATE INDEX idx_recipes_cuisine ON recipes(cuisine);

-- ============================================================
-- HELPER FUNCTIONS FOR ATOMIC OPERATIONS
-- ============================================================
CREATE OR REPLACE FUNCTION increment_followers(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET followers_count = followers_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_followers(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_following(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET following_count = following_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_following(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET following_count = GREATEST(following_count - 1, 0) WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_recipes_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE users SET recipes_count = recipes_count + 1 WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;
```

### Step 3: Enable Data API
1. In Neon console, go to Settings → Data API
2. Enable the Data API
3. Copy your API URL and generate a service role key
4. **IMPORTANT**: For production, create a backend proxy instead of exposing keys to clients

---

## 🔌 Service Wiring Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    KITCHEN DIARY APP                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Screens   │───▶│  Providers  │───▶│  Services   │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                              │                  │
│         ┌────────────────────────────────────┼──────────────┐   │
│         │                                    │              │   │
│         ▼                                    ▼              ▼   │
│  ┌─────────────┐                    ┌─────────────┐  ┌─────────┐│
│  │  Firebase   │                    │    Neon     │  │ Gemini  ││
│  │  - Auth     │                    │  PostgreSQL │  │   AI    ││
│  │  - Firestore│                    │  - Users    │  │         ││
│  │  - Storage  │                    │  - Forum    │  │         ││
│  └─────────────┘                    │  - History  │  └─────────┘│
│                                     └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

### Services & Their Responsibilities

| Service | File | Purpose |
|---------|------|---------|
| `AuthService` | `auth_service.dart` | Firebase Auth, Google Sign-In |
| `UserNeonService` | `user_neon_service.dart` | User profiles in Neon |
| `ForumNeonService` | `forum_neon_service.dart` | Forum posts/comments |
| `GeminiService` | `gemini_service.dart` | AI recipe suggestions |
| `SubscriptionService` | `subscription_service.dart` | Premium subscriptions |
| `HapticService` | `haptic_service.dart` | Haptic feedback |
| `AnimationSoundService` | `animation_sound_service.dart` | Sound effects |

### Wiring Services in main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Check Neon configuration
  if (!NeonUserConfig.isConfigured) {
    debugPrint('⚠️ Neon not configured - some features will be limited');
  }
  
  runApp(
    MultiProvider(
      providers: [
        // Auth Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // User Provider (syncs Firebase + Neon)
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, auth, user) => user!..updateAuth(auth),
        ),
        
        // Recipe Provider
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        
        // Community Provider
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        
        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Subscription Provider
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const KitchenDiaryApp(),
    ),
  );
}
```

---

## 🔥 Firebase Configuration

### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create new project "Kitchen Diary"
3. Enable Analytics

### Step 2: Add Apps
- Add iOS app (bundle ID: `com.yourcompany.kitchendiary`)
- Add Android app (package: `com.yourcompany.kitchendiary`)
- Download config files

### Step 3: Enable Services
- **Authentication**: Email/Password, Google Sign-In
- **Firestore**: Create database in production mode
- **Storage**: Enable for recipe images

### Step 4: Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Recipes
    match /recipes/{recipeId} {
      allow read: if resource.data.isPublic == true || request.auth.uid == resource.data.authorId;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.authorId;
    }
  }
}
```

---

## 🔑 API Keys & Secrets

### Environment Variables (for CI/CD)

```bash
# .env (DO NOT COMMIT)
NEON_DATA_API_URL=https://your-project.neon.tech/rest/v1
NEON_DATA_API_KEY=your-service-role-key
NEON_USER_API_URL=https://your-project.neon.tech/rest/v1
NEON_USER_API_KEY=your-service-role-key
GEMINI_API_KEY=your-gemini-api-key
```

### Flutter Build Commands

```bash
# Development
flutter run --dart-define=NEON_DATA_API_URL=https://your-project.neon.tech/rest/v1 \
            --dart-define=NEON_DATA_API_KEY=your-key \
            --dart-define=NEON_USER_API_URL=https://your-project.neon.tech/rest/v1 \
            --dart-define=NEON_USER_API_KEY=your-key \
            --dart-define=GEMINI_API_KEY=your-gemini-key

# Production Build
flutter build apk --release \
            --dart-define=NEON_DATA_API_URL=... \
            --dart-define=NEON_DATA_API_KEY=... \
            # ... etc
```

---

## 📱 App Store Deployment

### iOS (App Store Connect)

**Required:**
1. Apple Developer Account ($99/year)
2. App Store Connect account
3. Provisioning profiles & certificates

**Steps:**
```bash
# Build for iOS
flutter build ios --release

# Archive in Xcode
# Open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

**App Store Listing:**
- App Name: Kitchen Diary
- Subtitle: Your Personal Cooking Companion
- Category: Food & Drink
- Screenshots: 6.5" (iPhone 14 Pro Max), 5.5" (iPhone 8 Plus), iPad Pro
- App Preview videos (optional)
- Privacy Policy URL (required)
- Support URL

### Android (Google Play)

**Required:**
1. Google Play Developer Account ($25 one-time)
2. Signing keystore

**Steps:**
```bash
# Create keystore (once)
keytool -genkey -v -keystore ~/kitchen-diary-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias kitchen-diary

# Build AAB
flutter build appbundle --release

# Upload to Play Console
```

**Play Store Listing:**
- Title: Kitchen Diary
- Short description (80 chars)
- Full description (4000 chars)
- Screenshots: Phone, Tablet, Wear OS (optional)
- Feature graphic (1024x500)
- Privacy Policy URL

---

## 🎨 Image Generation Script

### What `generate_kitchen_images_qwen.py` Produces

When you run the script, it generates:

```
generated/kitchen_images/
├── ingredients/
│   ├── tomato_raw.png          # Ingredient in raw state
│   ├── tomato_chopped.png      # Ingredient chopped
│   ├── tomato_cooked.png       # Ingredient cooked
│   ├── onion_raw.png
│   ├── onion_diced.png
│   └── ... (all ingredients × all states)
├── tools/
│   ├── chef_knife.png          # Kitchen tool icons
│   ├── cutting_board.png
│   ├── frying_pan.png
│   └── ... (all tools)
├── actions/
│   ├── chop_action.png         # Action icons
│   ├── fry_action.png
│   └── ... (all actions)
├── sprites/
│   ├── tomato_chop_sprite.png  # 4x4 sprite sheet for animation
│   ├── onion_fry_sprite.png
│   └── ... (transformation animations)
├── transitions/
│   ├── tomato_raw_to_chopped.png  # Before→After transition
│   └── ... (all valid transformations)
└── cuisines/
    ├── italian_theme.png
    ├── japanese_theme.png
    └── ... (cuisine backgrounds)
```

### Running the Script

**Prerequisites:**
```bash
# Install dependencies
pip install 'diffusers[torch]' transformers accelerate safetensors pillow

# Requires GPU with 12GB+ VRAM (or use cloud GPU)
```

**Basic Usage:**
```bash
python generate_kitchen_images_qwen.py \
    --kitchen-json flutter_app/assets/data/kitchen_data.json \
    --output-dir generated/kitchen_images \
    --types ingredient tool action state sprite \
    --quality standard
```

**Quality Tiers:**
| Tier | Size | Frames | Steps | Time |
|------|------|--------|-------|------|
| preview | 256px | 4 | 20 | Fast |
| standard | 512px | 8 | 40 | Medium |
| high | 768px | 12 | 60 | Slow |
| ultra | 1024px | 16 | 80 | Very Slow |

**Dry Run (see what would be generated):**
```bash
python generate_kitchen_images_qwen.py \
    --kitchen-json flutter_app/assets/data/kitchen_data.json \
    --output-dir generated/kitchen_images \
    --dry-run
```

### Output Summary

The script generates **~500-2000 images** depending on:
- Number of ingredients in `kitchen_data.json`
- Number of ingredient states (raw, chopped, cooked, etc.)
- Number of tools and actions
- Whether sprite sheets are enabled

**Typical Output:**
- **Ingredients**: 50 ingredients × 6 states = 300 images
- **Tools**: 25 tool icons
- **Actions**: 20 action icons
- **Sprites**: 50 sprite sheets (4x4 = 800 frames)
- **Transitions**: 100 before→after images
- **Cuisines**: 12 theme backgrounds

---

## ✅ Final Checklist Before Launch

- [ ] All API keys configured
- [ ] Neon database schema created
- [ ] Firebase project configured
- [ ] Firestore security rules deployed
- [ ] Privacy Policy URL created
- [ ] Terms of Service URL created
- [ ] App icons generated (all sizes)
- [ ] Splash screen configured
- [ ] Screenshot taken for all required sizes
- [ ] App description written
- [ ] Keywords researched
- [ ] TestFlight beta tested (iOS)
- [ ] Internal testing completed (Android)
- [ ] Analytics verified working
- [ ] Crash reporting enabled
- [ ] Performance monitoring enabled
- [ ] Deep links configured (optional)
- [ ] Push notifications configured (optional)
- [ ] In-app purchases configured (if premium)

---

## 🆘 Support

For issues:
1. Check Firebase Console logs
2. Check Neon database logs
3. Review `debugPrint` output in Flutter
4. File issues in the project repository
