# Test Suite — IGIT Connects

This directory contains all automated tests for the IGIT Connects Flutter application.

---

## Structure

```
test/
├── widget_test.dart              # Root smoke test (confirms test runner works)
│
├── unit/
│   ├── theme_provider_test.dart  # ThemeNotifier — loadInitial, toggle, setMode, persistence
│   └── post_filter_test.dart     # Feed filter, search query, role detection, owner check
│
└── widget/
    ├── hashtag_text_test.dart    # HashtagText — rendering, themes, edge cases
    └── feed_filter_bar_test.dart # FeedFilterBar — chip rendering, tap callbacks, themes
```

---

## Running the Tests

```bash
# Run all tests
flutter test

# Run a specific file
flutter test test/unit/theme_provider_test.dart

# Run all unit tests
flutter test test/unit/

# Run all widget tests
flutter test test/widget/

# Run with verbose output
flutter test --reporter expanded

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## What Is Tested

### Unit Tests (`test/unit/`)

**`theme_provider_test.dart`** — Tests the `ThemeNotifier` Riverpod provider in isolation.

| Test case | Description |
|---|---|
| `loadInitial()` — no prefs | Returns `ThemeMode.system` on first launch |
| `loadInitial()` — stored "dark" | Returns `ThemeMode.dark` |
| `loadInitial()` — stored "light" | Returns `ThemeMode.light` |
| `loadInitial()` — invalid value | Falls back to `ThemeMode.system` |
| `init()` | Seeds state without writing to SharedPreferences |
| `toggle()` dark → light | Switches mode and persists "light" |
| `toggle()` light → dark | Switches mode and persists "dark" |
| `toggle()` from system | Treats system as non-light, toggles to dark |
| `setMode(dark)` | Writes "dark" to prefs |
| `setMode(light)` | Writes "light" to prefs |
| `setMode(system)` | Removes the prefs key entirely |
| `isDark` getter | Returns correct boolean for all three modes |
| Persistence round-trip | `toggle()` persisted value is read back by `loadInitial()` |

**`post_filter_test.dart`** — Tests business logic extracted from `HomeScreen` and `SearchScreen`.

| Test case | Description |
|---|---|
| `filterByType("all")` | Returns all posts unchanged |
| `filterByType("job")` | Returns only job posts |
| `filterByType("internship")` | Returns only internship posts |
| `filterByType("announcement")` | Returns only announcement posts |
| `filterByType` — no match | Returns empty list |
| `filterByType` — case-insensitive | Works regardless of `post_type` casing |
| `filterByQuery` — empty | Returns empty list |
| `filterByQuery` — user name | Matches on `user_name` field |
| `filterByQuery` — title | Matches on `title` field |
| `filterByQuery` — content | Matches on `content` field |
| `filterByQuery` — whitespace | Treated as empty, returns no results |
| `filterByQuery` — no match | Returns empty list |
| Role detection | `graduatingYear ≤ now` → alumni; future year → student |
| Owner check | Correct boolean for matching and non-matching UIDs |
| Post type colour | Each `post_type` string maps to the correct colour label |

---

### Widget Tests (`test/widget/`)

**`hashtag_text_test.dart`** — Tests the `HashtagText` component.

| Test case | Description |
|---|---|
| Plain text | Renders `RichText` with no errors |
| Single hashtag | `#flutter` token rendered |
| Mixed text + hashtag | Both parts rendered |
| Empty string | No exceptions thrown |
| Light theme | Renders without errors |
| Custom `fontSize` | Applied without errors |
| Multiple hashtags | Consecutive `#tag` tokens handled |

**`feed_filter_bar_test.dart`** — Tests the `FeedFilterBar` component.

| Test case | Description |
|---|---|
| All chips rendered | ALL, JOB, ANNOUNCEMENT, INTERNSHIP visible |
| Tap JOB | `onChanged` called with `"job"` |
| Tap ANNOUNCEMENT | `onChanged` called with `"announcement"` |
| Tap INTERNSHIP | `onChanged` called with `"internship"` |
| Dark theme | Renders without exceptions |
| Light theme | Renders without exceptions |

---

## What Is Not Tested Here

The following areas require Firebase and Supabase emulators or mocking libraries beyond the current scope. They are documented here so contributors know where to add coverage next.

| Area | Reason |
|---|---|
| `AuthGate` routing | Requires `FirebaseAuth` mock |
| `userProvider` / `postsProvider` | Requires Firestore / Supabase mock |
| `GoogleAuthController` | Requires Google Sign-In mock |
| `CreatePostScreen` submit | Requires Supabase insert mock |
| `EditPostScreen` / `EditProfileScreen` | Requires Supabase update mock |
| Full `HomeScreen` widget | Requires both providers mocked |
| `ProfileScreen` sliver header | Requires user data and posts providers |

For mocking Firebase in Flutter tests, see the [`fake_cloud_firestore`](https://pub.dev/packages/fake_cloud_firestore) and [`firebase_auth_mocks`](https://pub.dev/packages/firebase_auth_mocks) packages.

---

## Adding New Tests

1. Place **pure Dart / Riverpod logic tests** in `test/unit/`
2. Place **Flutter widget rendering tests** in `test/widget/`
3. Name test files after the file they test: `foo_bar.dart` → `foo_bar_test.dart`
4. Use `SharedPreferences.setMockInitialValues({})` in `setUp()` for any test touching prefs
5. Wrap widgets in a `MaterialApp` with an explicit `ThemeData` to avoid unresolved theme errors
