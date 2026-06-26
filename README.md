<div align="center">

<h1>🎓 IGIT Connects</h1>

<p><strong>A full-stack Flutter social networking application for the IGIT campus community — Students, Alumni & Faculty, unified in one reactive, theme-aware mobile platform.</strong></p>

<br/>

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
<img src="https://img.shields.io/badge/Supabase-Postgres%20%2B%20Storage-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
<img src="https://img.shields.io/badge/Riverpod-State%20Management-3B4EFF?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Google%20Sign--In-OAuth%202.0-4285F4?style=for-the-badge&logo=google&logoColor=white"/>
<img src="https://img.shields.io/badge/Material%203-Design%20System-757575?style=for-the-badge&logo=material-design&logoColor=white"/>

</div>

---

## 📖 About

**IGIT Connects** is a production-grade, cross-platform mobile application built with Flutter for **Indira Gandhi Institute of Technology (IGIT), Sarang, Odisha**. It serves as a private campus social network that enables the entire IGIT ecosystem — current students, alumni, and faculty — to communicate, share career opportunities, and stay informed in real time.

The app follows a **reactive, provider-driven architecture** using Riverpod for state management, Firebase for authentication and user data, and Supabase (PostgreSQL) as the posts database and file storage backend. The entire UI is built on a **dual-theme design system** (dark + light) with full runtime switching and persistence.

---

## 🌊 Full App Working Flow

### 1. Bootstrap Phase — `main.dart`

```
App Launch
    │
    ├─▶ WidgetsFlutterBinding.ensureInitialized()
    ├─▶ Firebase.initializeApp()                     ← Firebase SDK init
    ├─▶ dotenv.load(".env")                          ← Load Supabase secrets from .env asset
    ├─▶ Supabase.initialize(url, anonKey)            ← Supabase client init
    ├─▶ ThemeNotifier.loadInitial()                  ← Async SharedPreferences read for saved ThemeMode
    │       └─▶ Returns: ThemeMode.system | .dark | .light
    └─▶ runApp(ProviderScope(child: MyApp(initialTheme)))
            └─▶ MyApp seeds ThemeProvider via postFrameCallback — zero-flash guarantee
```

### 2. Authentication & Routing — `AuthGate.dart`

```
MyApp renders MaterialApp
    │
    └─▶ AuthGate (ConsumerStatefulWidget)
            │
            ├─ initState() → Future.delayed(3s)       ← Branded splash screen shown
            │
            └─ FirebaseAuth.instance.currentUser?
                    │
                    ├── NULL ──────────────────────────────▶ LoginScreen
                    │
                    └── EXISTS
                            │
                            ├─ SharedPreferences.getBool('profile_completed_$uid')
                            │       └── TRUE ──────────────▶ MainScreen  (fast path, no DB read)
                            │
                            └─ Firestore: ref.read(userProvider.future)
                                    ├── profile_completed == true ──▶ MainScreen
                                    │       └─ prefs.setBool(true)  ← cache for next launch
                                    └── false ─────────────────────▶ OnBoardingScreen
```

### 3. Login Flow — `LogInScreen.dart` + `GoogleAuthController.dart`

```
LoginScreen
    │
    ├─ "Student / Alumni Login"  ─┐
    └─ "Faculty Login"           ─┤
                                  ▼
                    GoogleAuthController.signInWithGoogle()
                                  │
                                  ├─▶ GoogleSignIn().signIn()              ← OAuth 2.0 popup
                                  ├─▶ GoogleSignInAccount.authentication
                                  ├─▶ GoogleAuthProvider.credential(idToken, accessToken)
                                  └─▶ FirebaseAuth.signInWithCredential()
                                                  │
                                                  └─▶ Navigator → AuthGate(userMode)
```

### 4. Onboarding Flow — `OnBoardingScreen.dart`

```
OnBoardingScreen  (PageView — 2 pages)
    │
    ├── Page 1: OnboardingTemplate
    │       └── TypewriterAnimatedText, feature list, campus tagline
    │
    └── Page 2: OnboardingUserDetailsScreen
            │
            ├── userMode == "student"
            │       DropdownButtonFormField → Branch | Stream | Graduating Year
            │       Auto-detect role: graduatingYear <= currentYear → "alumni" else "student"
            │
            └── userMode == "faculty"
                    DropdownButtonFormField → Department | Designation | Phone
                    FacultyVerificationScreen → image_picker → Supabase upload → faculty_proof URL
            │
            └── Save()
                    ├─▶ Supabase UPDATE users SET { role, branch/dept, profile_completed: true }
                    ├─▶ SharedPreferences.setBool('profile_completed_$uid', true)
                    └─▶ Navigator → MainScreen
```

### 5. Main Navigation Shell — `MainScreen.dart`

```
MainScreen  (StatefulWidget)
    │
    └── BottomNavigationBar  (IndexedStack — preserves scroll state per tab)
            ├── [0] HomeScreen       → Community feed
            ├── [1] SearchScreen     → Full-text post search
            ├── [2] CreatePostScreen → Post composer
            └── [3] ProfileScreen    → User profile & own posts
```

### 6. Home Feed — `HomeScreen.dart`

```
HomeScreen  (ConsumerStatefulWidget)
    │
    ├─▶ ref.watch(userProvider)    ← AsyncNotifierProvider → Firestore /users/{uid}
    ├─▶ ref.watch(postsProvider)   ← FutureProvider → Supabase SELECT * FROM posts
    │
    ├── HomeHeader
    │       ├── AutoSizeText welcome + user name
    │       ├── 🌙 / ☀️  icon → themeProvider.notifier.toggle()
    │       └── CircleAvatar tap → ModalBottomSheet  (preview + Logout)
    │
    ├── FeedFilterBar
    │       └── AnimatedContainer chips: ALL | JOB | ANNOUNCEMENT | INTERNSHIP
    │               └── onChanged: setState(selected) → in-memory list filter
    │
    ├── RefreshIndicator → onRefresh: ref.refresh(postsProvider)
    │
    ├── ListView.builder → PostCard(post, onRefresh)
    │
    └── ScrollController
            ├── offset > 250 → showFab = true
            └── FAB → scrollController.animateTo(0, Curves.easeInOut)
```

### 7. Post Card System — `PostCard.dart`

```
PostCard  (StatefulWidget)
    │
    ├── Header: CircleAvatar | userName | userType badge (colour-coded) | date
    │
    ├── Post-type badge
    │       JOB (green) | ANNOUNCEMENT (orange) | INTERNSHIP (blue) | NORMAL (grey)
    │
    ├── Title  (bold)
    │
    ├── Content → HashtagText
    │       RegExp(r'#[A-Za-z0-9_]+') → TextSpan(color: blue, fontWeight: bold)
    │
    ├── content.length > 250 → "Read more" → FullPostScreen (push route)
    │
    ├── File attachment  (Supabase public CDN URL)
    │       isImage(url) → Image.network(height: 230, fit: cover)
    │       else         → InkWell → url_launcher (LaunchMode.externalApplication)
    │
    ├── Link → url_launcher
    │
    └── PopupMenuButton  (shown only if FirebaseAuth.currentUser.uid == post["user_id"])
            ├── Edit   → EditPostScreen → Supabase .update() → onRefresh()
            └── Delete → Supabase .delete()           → onRefresh()
```

### 8. Create Post Flow — `CreatePostScreen.dart`

```
CreatePostScreen  (ConsumerStatefulWidget)
    │
    ├── CreatePostTopSection    → animated type-chip selector
    │
    ├── CreatePostInputCard     → title | content (maxLength 2000) | link
    │       TextEditingController.addListener → setState() → live preview sync
    │
    ├── CreatePostPreviewSection → mirrors PostCard, updates on every keystroke
    │
    └── FAB "Post" → createPost()
            │
            ├─▶ ref.read(userProvider.future)  → name, photo, userType, dept
            ├─▶ Supabase.from("posts").insert({ ...all fields })
            ├─▶ ref.invalidate(postsProvider)  ← forces global feed re-fetch
            └─▶ Navigator.pushReplacement → MainScreen
```

### 9. Search Flow — `SearchScreen.dart`

```
SearchScreen  (ConsumerStatefulWidget)
    │
    ├─▶ ref.watch(postsProvider) → reuses Riverpod cache (zero extra network calls)
    │
    ├── TextField → onChanged → setState(query.trim().toLowerCase())
    │
    └── Client-side filter  (O(n), no server round-trip)
            posts.where(p =>
                p["user_name"].contains(query) ||
                p["title"].contains(query)     ||
                p["content"].contains(query)
            )
            └── ListView.builder → PostCard
```

### 10. Profile Flow — `ProfileScreen.dart`

```
ProfileScreen  (ConsumerWidget)
    │
    └── CustomScrollView
            │
            ├── ProfileHeaderSliver  (SliverAppBar, expandedHeight: 350, stretch: true)
            │       Stack layers:
            │           ① Container(bgColor)
            │           ② CustomPaint(GridLinePainter(color))  ← Canvas grid texture
            │           ③ Overlay container  (opacity 0.18 dark / 0.06 light)
            │       Content: CircleAvatar | name | email | ProfileStatsRow
            │       "Edit" button → EditProfileScreen → Supabase UPDATE → ref.invalidate(userProvider)
            │
            └── ProfilePostsSection  (SliverList)
                    posts.where(p => p["user_id"] == data["id"]) → PostCard list
```

### 11. Theme Engine Flow

```
Cold Start  (before first frame)
    │
    └─▶ await ThemeNotifier.loadInitial()
            ├── prefs 'dark'    → ThemeMode.dark
            ├── prefs 'light'   → ThemeMode.light
            └── key absent      → ThemeMode.system  ← first launch: honour device setting

User taps toggle  (HomeHeader)
    │
    └─▶ themeProvider.notifier.toggle()
            ├── state: dark ↔ light
            └── SharedPreferences.setString('theme_mode', 'dark'|'light')

MaterialApp  (reactive)
    ├── themeMode:  ref.watch(themeProvider)   ← rebuilds entire app on change
    ├── theme:      ThemeData.light + Poppins + custom colorScheme
    └── darkTheme:  ThemeData.dark  + Poppins + custom colorScheme

Widget color resolution
    └── AppColors.of(context)
            └── Theme.of(context).brightness
                    ├── Brightness.dark  → bgColor #141413 | card #1E1E1C | border #2C2C29
                    │                      primary #F7F7F5 | secondary #A1A1A0
                    └── Brightness.light → bgColor #F5F5F3 | card #FFFFFF  | border #E0E0DE
                                           primary #181817 | secondary #6B6B6A
```

---

## 🏛️ Architecture & Design Patterns

### Riverpod Providers

| Provider | Type | Purpose |
|---|---|---|
| `themeProvider` | `NotifierProvider<ThemeNotifier, ThemeMode>` | Dark/light mode + SharedPreferences persistence |
| `userProvider` | `AsyncNotifierProvider` | Firestore `/users/{uid}` document stream |
| `postsProvider` | `FutureProvider` | Supabase `posts` table — cached across all screens |

### Reactive Data Flow

```
ref.watch(provider)         ← subscribe; widget rebuilds on every state change
    ├── AsyncData(data)  → render content widget
    ├── AsyncLoading()   → CircularProgressIndicator
    └── AsyncError(e,s)  → error message widget

ref.read(provider.notifier).action()   ← one-shot call inside button handlers
```

### Dual-Backend Architecture

```
┌─────────────────────────────────────────┐
│              Firebase                    │
│  ┌──────────────────┐  ┌─────────────┐  │
│  │  Authentication  │  │  Firestore  │  │
│  │  Google OAuth    │  │ /users/{uid}│  │
│  │  JWT sessions    │  │ name, role, │  │
│  │  currentUser     │  │ photo, ...  │  │
│  └──────────────────┘  └─────────────┘  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│              Supabase                    │
│  ┌──────────────────┐  ┌─────────────┐  │
│  │  PostgreSQL REST │  │  Storage    │  │
│  │  /posts table    │  │ /posts/     │  │
│  │  insert, update, │  │ images, docs│  │
│  │  delete, select  │  │ public CDN  │  │
│  └──────────────────┘  └─────────────┘  │
└─────────────────────────────────────────┘
```

### Color System — `AppColors`

```dart
// ✅ Always use context-aware accessor
final colors = AppColors.of(context);

colors.bgColor        // Scaffold / screen background
colors.cardColor      // Elevated card / surface fill
colors.borderColor    // Input borders, dividers, separators
colors.primaryText    // Headings, body, buttons
colors.secondaryText  // Hints, metadata, placeholder text

// ❌ Never hardcode colors inline
Container(color: Color(0xff141413))   // breaks light mode
```

---

## ✨ Feature Matrix

| Feature | Implementation Detail | Tech Used |
|---|---|---|
| Google Sign-In | OAuth 2.0 token → Firebase credential | `firebase_auth`, `google_sign_in` |
| Auth Persistence | `FirebaseAuth.currentUser` survives restart | Firebase JWT session |
| Auth Fast-path | SharedPreferences skips Firestore on return | `shared_preferences` |
| Campus Feed | `FutureProvider` + `ref.refresh()` on pull | Supabase REST, Riverpod |
| Feed Filtering | In-memory `List.where()` on cached data | Riverpod cache, Dart `Iterable` |
| Hashtag Rendering | `RegExp` splits text into `TextSpan` list | `RichText`, `TextSpan` |
| File Attachments | Supabase CDN URL, images inline + docs external | `url_launcher`, Supabase Storage |
| Post CRUD | Owner-gated `PopupMenuButton` for edit/delete | Supabase `.update()`, `.delete()` |
| Full Post Reader | Push route for `content.length > 250` | `Navigator`, `FullPostScreen` |
| Live Compose Preview | `TextEditingController.addListener` → `setState` | `setState`, `RichText` |
| Client-side Search | `List.where()` on Riverpod cache — zero latency | Dart `Iterable` |
| Role Auto-detection | `graduatingYear <= DateTime.now().year` → alumni | `DateTime`, Supabase `UPDATE` |
| Faculty Verification | Photo → Supabase Storage → URL stored in profile | `image_picker`, Supabase bucket |
| Dual Theme | `ThemeData.dark` + `ThemeData.light`, full widget coverage | Material 3, `ThemeData` |
| System Theme Sync | `ThemeMode.system` on first launch | `ThemeMode`, `Brightness` |
| Theme Persistence | `SharedPreferences` survives app restart | `shared_preferences` |
| Zero Theme Flash | `loadInitial()` awaited before `runApp()` | `async main()` |
| Theme Toggle | `NotifierProvider.toggle()` in HomeHeader | Riverpod `Notifier` |
| Scroll-to-top FAB | `ScrollController.offset > 250` threshold | `ScrollController` |
| Pull-to-refresh | `RefreshIndicator` → `ref.refresh(postsProvider)` | `RefreshIndicator` |
| Profile Grid Texture | `CustomPainter` with `Canvas.drawLine()` | `CustomPainter`, `Canvas` |
| Poppins Typography | `GoogleFonts.poppinsTextTheme(base)` on both themes | `google_fonts` |
| Onboarding Animation | `TypewriterAnimatedText` + `SmoothPageIndicator` | `animated_text_kit` |
| Responsive Text | `AutoSizeText` in HomeHeader prevents overflow | `auto_size_text` |
| Admin Panel | `role == "admin"` guard in bottom sheet | Role-gated widget |

---

## 📁 Project Structure

```
igit_connects/
│
├── lib/
│   ├── main.dart                                # App entry — init + theme bootstrap
│   ├── MainScreen.dart                          # IndexedStack bottom nav shell
│   ├── firebase_options.dart                    # FlutterFire auto-generated config
│   ├── Storage_Backend.dart                     # Supabase file upload utility
│   │
│   ├── Component/
│   │   ├── app_colors.dart                      # AppColors class (dark + light palettes)
│   │   ├── AppColour.dart                       # Backward-compat shim → re-exports app_colors
│   │   ├── HashtagText.dart                     # RegExp #hashtag RichText widget
│   │   │
│   │   ├── Home/
│   │   │   ├── HomeHeader.dart                  # Welcome card + theme toggle + user sheet
│   │   │   ├── FeedFilterBar.dart               # Animated filter chip row
│   │   │   ├── PostCard.dart                    # Full post card (CRUD, file, link, hashtag)
│   │   │   └── SearchBox.dart                   # Decorative search prompt widget
│   │   │
│   │   ├── CreatePost/
│   │   │   ├── CreatePostTopSection.dart        # Post-type animated chip selector
│   │   │   ├── CreatePostInputCard.dart         # Themed TextField group
│   │   │   ├── CreatePostLivePreview.dart       # Real-time preview mirrors PostCard
│   │   │   └── TextfielsBuild.dart              # Reusable themed TextField builder
│   │   │
│   │   ├── Onboarding/
│   │   │   ├── OnboardingTemplate.dart          # Typewriter animation + feature showcase
│   │   │   └── OnboardingUserDetailsScreen.dart # Role-specific profile form
│   │   │
│   │   └── Profile/
│   │       ├── ProfileHeaderSliver.dart         # SliverAppBar + grid + avatar + stats
│   │       ├── ProfileGridPainter.dart          # Canvas grid texture (theme-aware)
│   │       ├── ProfileStatsRow.dart             # Posts / Role / Branch row
│   │       └── ProfileStatsBox.dart             # Single stat label + value widget
│   │
│   ├── Controllers/
│   │   ├── AuthGate.dart                        # Splash + smart auth routing
│   │   ├── ThemeProvider.dart                   # Riverpod NotifierProvider + persistence
│   │   ├── UserProvider.dart                    # AsyncNotifierProvider for Firestore user
│   │   ├── PostProvider.dart                    # FutureProvider for Supabase posts
│   │   └── GoogleAuthController.dart            # Google Sign-In → Firebase credential
│   │
│   └── Screens/
│       ├── HomeScreen.dart                      # Feed + FAB + pull-refresh
│       ├── SearchScreen.dart                    # Client-side real-time search
│       ├── LogInScreen.dart                     # Login UI + role selection
│       ├── OnBoardingScreen.dart                # PageView onboarding host
│       ├── FacultyVerificationScreen.dart       # Camera photo proof capture
│       ├── Post/
│       │   ├── CreatePostScreen.dart            # Composer + live preview
│       │   ├── EditPostScreen.dart              # Edit + inline preview
│       │   └── FullPostScreen.dart              # Long-form post reader
│       └── Profile/
│           ├── ProfileScreen.dart               # CustomScrollView profile
│           └── EditProfileScreen.dart           # Role-specific edit form
│
├── android/                                     # Android platform config
├── ios/                                         # iOS platform config
├── .env                                         # Supabase secrets  ⚠️ never commit
├── pubspec.yaml                                 # Flutter package manifest
└── README.md
```

---

## 🛠️ Tech Stack

| Category | Package | Version | Purpose |
|---|---|---|---|
| **UI Framework** | `flutter` | SDK `^3.10.4` | Declarative cross-platform widget tree |
| **Language** | `dart` | `^3.x` | Null-safe, strongly typed, async/await |
| **State Management** | `flutter_riverpod` | `^3.3.1` | `NotifierProvider`, `FutureProvider`, `ConsumerWidget` |
| **Auth** | `firebase_auth` | `^6.4.0` | Firebase JWT session management |
| **OAuth** | `google_sign_in` | `^7.2.0` | Google OAuth 2.0 popup flow |
| **NoSQL DB** | `cloud_firestore` | `^6.3.0` | User profile documents |
| **Relational DB + Storage** | `supabase_flutter` | `^2.12.4` | PostgreSQL REST API + Object Storage CDN |
| **Firebase Init** | `firebase_core` | `^4.7.0` | Firebase SDK bootstrapping |
| **Typography** | `google_fonts` | `^8.0.2` | Poppins applied to full `TextTheme` |
| **Persistence** | `shared_preferences` | `^2.5.5` | Theme mode + profile completion cache |
| **URL Handling** | `url_launcher` | `^6.3.2` | External links and file downloads |
| **Image Picker** | `image_picker` | `^1.2.1` | Camera and gallery selection |
| **File Picker** | `file_picker` | `^11.0.2` | Document and file selection |
| **Text Animation** | `animated_text_kit` | `^4.3.0` | `TypewriterAnimatedText` in onboarding |
| **Page Indicator** | `smooth_page_indicator` | `^2.0.1` | PageView dot indicator |
| **Responsive Text** | `auto_size_text` | `^3.0.0` | Overflow-safe text in header |
| **Env Secrets** | `flutter_dotenv` | `^6.0.1` | `.env` bundled as Flutter asset |
| **Design System** | Material 3 | `useMaterial3: true` | Colour scheme, elevated surfaces |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.10.4` — [Install Flutter](https://docs.flutter.dev/get-started/install)
- A Firebase project with **Google Authentication** and **Cloud Firestore** enabled
- A Supabase project with a `posts` table and a storage bucket

### Setup

**1. Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/igit_connects.git
cd igit_connects
```

**2. Install dependencies**

```bash
flutter pub get
```

**3. Firebase configuration**

- Place `google-services.json` → `android/app/`
- Place `GoogleService-Info.plist` → `ios/Runner/`
- Update `lib/firebase_options.dart` with your project credentials

**4. Create `.env` in project root**

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**5. Supabase `posts` table schema**

```sql
CREATE TABLE posts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     TEXT NOT NULL,
  user_name   TEXT,
  user_photo  TEXT,
  user_type   TEXT,
  department  TEXT,
  post_type   TEXT DEFAULT 'normal',
  title       TEXT,
  content     TEXT,
  link        TEXT,
  file_url    TEXT,
  file_name   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

**6. Run the app**

```bash
flutter run
```

---

## 👥 User Roles

| Role | Description | Auto-detected |
|---|---|---|
| **Student** | Active IGIT students | No |
| **Alumni** | Graduated — graduating year ≤ current year | ✅ Yes |
| **Faculty** | Teaching staff — requires photo verification | No |
| **Admin** | Internal admin — App Manager route | No |

---

## 🤝 Contributing

Pull requests are welcome! For major changes please open an issue first to discuss.

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/igit_connects.git

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Commit with a clear message
git commit -m "feat: add post bookmarking with Supabase favourites table"

# 4. Push and open a PR
git push origin feature/your-feature-name
```

### Code Guidelines

- ✅ Always use `AppColors.of(context)` — never hardcode `Color(0xff...)` inside widgets
- ✅ Use `ConsumerWidget` / `ConsumerStatefulWidget` for any widget that reads a provider
- ✅ `ref.watch()` for reactive UI — `ref.read()` inside button callbacks only
- ✅ Keep all Supabase / Firestore calls inside `Controllers/` — not in widget `build()` methods
- ✅ Test both dark and light themes before submitting a PR

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">

**Built with ❤️ for IGIT, Sarang, Odisha**

*Empowering every student, alumnus, and faculty member with the tools to connect, grow, and inspire.*

</div>
