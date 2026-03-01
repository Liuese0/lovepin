# Lovepin — Product Spec & MVP Technical Plan

---

## 1. One-Page Product Spec

### Overview

Lovepin is a couple-only home screen widget messaging app. Partners send short texts, love quotes, or photo + one-line captions that appear **directly on each other's home screen widget** — no app launch required. It replaces the "push notification → open messenger" pattern with an always-visible, aesthetically curated "pinned love" experience.

### Target Users

| Segment | Detail |
|---|---|
| **Primary** | Late teens – mid 20s couples (MZ generation) |
| **Use case** | Long-distance couples, daily affection rituals, aesthetic communication |
| **Psychographic** | Values visual/emotional expression, SNS-style design, stationery/polaroid aesthetics |

### User Flow (Happy Path)

```
1. Sign up → Phone/email auth via Supabase
2. Create invite code  ─── OR ───  Enter partner's code
3. Couple linked → Land on Home (message feed)
4. Compose: type text / pick template / attach photo + caption
5. Send → Message stored in Supabase, Realtime broadcast fires
6. Partner's widget updates on home screen (near-real-time)
7. Partner taps widget → Opens app to full message view
```

### Key Differentiators

1. **Widget-first UX** — The widget IS the product. The app is the composer; the widget is the reader.
2. **Emotional design language** — Polaroid-card messages, pastel palette, handwriting fonts. Not a chat app — a love letter board.
3. **Curated templates** — Ready-made phrases for moments (miss you, cheer up, sorry, good morning) lower the barrier to expressing feelings.
4. **1:1 only** — No group chats, no social graph. Intimate by design.

### Monetization

| Tier | Content |
|---|---|
| **Free** | Core messaging, 1 widget style, 5 basic templates, 1 font |
| **Premium (subscription)** | All pastel themes, handwriting font pack, seasonal/anniversary templates, ad removal |
| **One-time IAP** | Individual theme packs, special occasion template bundles |

### UI/UX Principles

> **Design reference note:** The visual direction below is derived from the reference images described by the user (pastel gradients, polaroid-frame cards, rounded soft UI, handwriting typography). If specific images conflict with platform widget constraints, the concept is preserved but adapted for Flutter + WidgetKit/AppWidget feasibility.

1. **Pastel-dominant palette** — Soft pink (`#FFD6E0`), lavender (`#E8D5F5`), cream (`#FFF8F0`), sky blue (`#D6EEFF`). Gradients used sparingly on backgrounds.
2. **Typography** — Primary: rounded sans-serif (e.g., Pretendard Round or Nunito). Accent: handwriting-style font (e.g., Caveat, Nanum Pen Script) for message display and templates.
3. **Card/widget styling** — Polaroid-frame aesthetic: white border with slight shadow, rounded corners (16–20 dp), optional tape/pin decorative element. Photo messages show image with caption overlaid at the bottom in handwriting font.
4. **Motion** — Subtle fade-in on new message arrival. No aggressive animations. Calm, warm transitions.
5. **Iconography** — Line-art style, thin stroke, emotionally warm (hearts, pins, envelopes, stamps).
6. **Spacing** — Generous padding. Breathable layouts. Never cramped.

---

## 2. MVP Requirements

### 2.1 Functional Requirements

| ID | Feature | Description | Priority |
|---|---|---|---|
| F-01 | **Sign up / Login** | Email + password auth via Supabase Auth. Optional: phone OTP (Phase 2). | P0 |
| F-02 | **Profile setup** | Display name + avatar (optional photo or default illustration). | P0 |
| F-03 | **Couple linking (invite code)** | User A generates a 6-char alphanumeric code (expires in 24h). User B enters it. Both linked as a couple. | P0 |
| F-04 | **Send text message** | Compose and send a short text message (max 200 chars) to partner. | P0 |
| F-05 | **Send photo + caption** | Attach one photo from gallery + one-line caption (max 100 chars). Photo compressed to max 1024px, stored in Supabase Storage. | P0 |
| F-06 | **Message feed** | Scrollable timeline of sent/received messages, newest first. | P0 |
| F-07 | **Home screen widget** | Displays latest received message (text, or photo thumbnail + caption). Tapping opens the app. | P0 |
| F-08 | **Near-real-time widget update** | Widget refreshes when a new message arrives (platform-dependent best effort). | P0 |
| F-09 | **Emotional templates** | Browse curated quote/phrase templates by category (miss you, cheer up, sorry, thank you, good morning, good night). Tap to prefill compose. | P1 |
| F-10 | **Widget theme selection** | Choose from 3 free pastel themes affecting widget background/font color. | P1 |
| F-11 | **Push notification** | FCM notification when a new message is received (fallback for widget refresh). | P1 |
| F-12 | **Read receipt (simple)** | Mark message as "seen" when partner opens the app and views it. | P2 |
| F-13 | **Couple unlink** | Either user can break the couple link. Requires confirmation. Messages archived. | P2 |

### 2.2 Non-Functional Requirements

| ID | Requirement | Target |
|---|---|---|
| NF-01 | **Latency** | Message delivery (server-side) < 500ms via Supabase Realtime |
| NF-02 | **Widget refresh** | iOS: ≤ 15 min timeline-based + push-triggered reload. Android: near-instant via broadcast. |
| NF-03 | **Image size** | Compress to ≤ 300KB before upload. Thumbnail for widget ≤ 50KB. |
| NF-04 | **Offline** | App caches last 50 messages locally (SQLite/Hive). Widget shows last cached message if offline. |
| NF-05 | **Security** | Row-Level Security (RLS) on all Supabase tables. Users can only read their own couple's data. |
| NF-06 | **Platform** | iOS 16+ (WidgetKit), Android 8+ (AppWidget). Flutter 3.x. |
| NF-07 | **Storage** | Supabase Storage bucket with 50MB per user soft limit (MVP). |
| NF-08 | **Scalability** | Supabase free tier supports MVP. Upgrade path to Pro for > 500 DAU. |

---

## 3. Supabase Data Model

### 3.1 Entity Relationship

```
users ──1:1── couple_members ──N:1── couples
                                        │
                                      1:N
                                        │
                                    messages
                                        │
                                      N:1 (optional)
                                        │
                                    templates

themes ── (standalone, referenced by user preference)
subscriptions ── (1:1 with users)
```

### 3.2 Table Definitions

#### `users`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default `auth.uid()` | Links to Supabase Auth |
| `display_name` | `text` | NOT NULL, max 30 | |
| `avatar_url` | `text` | NULLABLE | Supabase Storage path |
| `selected_theme_id` | `uuid` | FK → themes.id, NULLABLE | Current widget theme |
| `fcm_token` | `text` | NULLABLE | For push notifications |
| `created_at` | `timestamptz` | default `now()` | |
| `updated_at` | `timestamptz` | default `now()` | |

#### `couples`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` | |
| `invite_code` | `text` | UNIQUE, max 6 | Generated by first user |
| `invite_expires_at` | `timestamptz` | | 24h from creation |
| `status` | `text` | `'pending'` / `'active'` / `'unlinked'` | |
| `linked_at` | `timestamptz` | NULLABLE | When second user joined |
| `created_at` | `timestamptz` | default `now()` | |

#### `couple_members`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `couple_id` | `uuid` | FK → couples.id, NOT NULL | |
| `user_id` | `uuid` | FK → users.id, UNIQUE, NOT NULL | One user in one couple |
| `role` | `text` | `'creator'` / `'joiner'` | Who initiated |
| `joined_at` | `timestamptz` | default `now()` | |

**RLS:** Users can only SELECT rows where `user_id = auth.uid()`. Couple data accessible only if user is a member.

#### `messages`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK, default `gen_random_uuid()` | |
| `couple_id` | `uuid` | FK → couples.id, NOT NULL | |
| `sender_id` | `uuid` | FK → users.id, NOT NULL | |
| `content` | `text` | max 200 | Text body |
| `image_url` | `text` | NULLABLE | Supabase Storage path |
| `image_thumbnail_url` | `text` | NULLABLE | Compressed for widget |
| `template_id` | `uuid` | FK → templates.id, NULLABLE | If sent from template |
| `is_read` | `boolean` | default `false` | Simple read receipt |
| `read_at` | `timestamptz` | NULLABLE | |
| `created_at` | `timestamptz` | default `now()` | |

**Index:** `(couple_id, created_at DESC)` for feed queries.

**RLS:** Users can INSERT where `sender_id = auth.uid()` AND user is member of `couple_id`. Users can SELECT where they are a member of `couple_id`.

#### `templates`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `category` | `text` | NOT NULL | `'miss_you'`, `'cheer_up'`, `'sorry'`, `'thank_you'`, `'good_morning'`, `'good_night'` |
| `content` | `text` | NOT NULL, max 200 | The quote/phrase text |
| `language` | `text` | default `'en'` | i18n support |
| `is_premium` | `boolean` | default `false` | |
| `sort_order` | `int` | | Display ordering |
| `created_at` | `timestamptz` | default `now()` | |

#### `themes`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `name` | `text` | NOT NULL | e.g., "Rose Quartz", "Lavender Dream" |
| `background_color` | `text` | | Hex, e.g., `#FFD6E0` |
| `text_color` | `text` | | Hex |
| `accent_color` | `text` | | Hex |
| `font_family` | `text` | | e.g., `'caveat'`, `'nunito'` |
| `is_premium` | `boolean` | default `false` | |
| `preview_url` | `text` | NULLABLE | Theme preview image |
| `created_at` | `timestamptz` | default `now()` | |

#### `subscriptions`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | `uuid` | PK | |
| `user_id` | `uuid` | FK → users.id, UNIQUE | |
| `plan` | `text` | `'free'` / `'premium'` | |
| `platform` | `text` | `'ios'` / `'android'` | |
| `store_receipt_id` | `text` | NULLABLE | App Store / Play Store receipt |
| `expires_at` | `timestamptz` | NULLABLE | NULL = free tier |
| `created_at` | `timestamptz` | default `now()` | |
| `updated_at` | `timestamptz` | default `now()` | |

---

## 4. Realtime Logic Design

### 4.1 Message Send Flow

```
┌─────────┐       ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│ Sender   │       │ Supabase     │       │ Supabase     │       │ Receiver     │
│ App      │──────▶│ REST / RPC   │──────▶│ Realtime     │──────▶│ App / Widget │
│          │  1.   │ INSERT msg   │  2.   │ Broadcast    │  3.   │ Update UI    │
└─────────┘       └──────────────┘       └──────────────┘       └──────────────┘
                         │                                              │
                         │  4. Supabase Edge Function (webhook)         │
                         │────▶ FCM push notification ─────────────────▶│
                         │                                         5. Trigger
                         │                                        widget refresh
```

### 4.2 Realtime Channel Design

**Channel:** `couple:{couple_id}`

```dart
// Subscribe to couple's message channel
final channel = supabase.channel('couple:${coupleId}');

channel
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'messages',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'couple_id',
      value: coupleId,
    ),
    callback: (payload) {
      final newMessage = Message.fromJson(payload.newRecord);
      if (newMessage.senderId != currentUserId) {
        // Update UI + trigger widget refresh
        messageNotifier.addMessage(newMessage);
        WidgetService.updateWidget(newMessage);
      }
    },
  )
  .subscribe();
```

### 4.3 Widget Refresh Trigger

**When the app is in foreground:**
- Realtime subscription fires → update local cache → call native widget update method via platform channel.

**When the app is in background / killed:**
- FCM data message arrives → handled by background message handler.
- **Android:** `AppWidgetProvider.onReceive()` triggered by broadcast from FCM handler. Widget redraws immediately.
- **iOS:** `WidgetCenter.shared.reloadTimelines(ofKind:)` called from Notification Service Extension. WidgetKit reloads (subject to system budget, ~40–70 refreshes/day).

### 4.4 Read Receipt Logic (Phase 2)

```sql
-- When receiver opens app and views message feed:
UPDATE messages
SET is_read = true, read_at = now()
WHERE couple_id = :couple_id
  AND sender_id != :current_user_id
  AND is_read = false;
```

Sender's app picks up the change via Realtime `UPDATE` event on the same channel.

---

## 5. Flutter App Architecture

### 5.1 State Management

**Riverpod** (recommended for this scale)
- `AsyncNotifierProvider` for async data (messages, couple info)
- `StreamProvider` for Realtime subscription
- `StateProvider` for simple UI state (selected theme, compose draft)

### 5.2 Folder Structure

```
lib/
├── main.dart
├── app.dart                         # MaterialApp, routing, theme
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Pastel palette constants
│   │   ├── app_fonts.dart           # Font family references
│   │   └── app_sizes.dart           # Spacing, radius, etc.
│   ├── theme/
│   │   └── app_theme.dart           # ThemeData, widget theme mapping
│   ├── router/
│   │   └── app_router.dart          # GoRouter config
│   └── utils/
│       ├── image_compressor.dart    # Compress before upload
│       └── date_formatter.dart
│
├── data/
│   ├── supabase/
│   │   ├── supabase_client.dart     # Singleton init
│   │   ├── auth_repository.dart
│   │   ├── couple_repository.dart
│   │   ├── message_repository.dart
│   │   ├── template_repository.dart
│   │   └── theme_repository.dart
│   ├── local/
│   │   └── local_cache.dart         # Hive/SharedPreferences for widget data
│   └── models/
│       ├── user_model.dart
│       ├── couple_model.dart
│       ├── message_model.dart
│       ├── template_model.dart
│       └── theme_model.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── onboarding/
│   │   ├── screens/
│   │   │   ├── profile_setup_screen.dart
│   │   │   └── couple_link_screen.dart   # Generate / enter invite code
│   │   └── providers/
│   │       └── couple_link_provider.dart
│   │
│   ├── home/
│   │   ├── screens/
│   │   │   └── home_screen.dart          # Message feed
│   │   ├── widgets/
│   │   │   ├── message_card.dart         # Polaroid-style card
│   │   │   └── message_feed.dart
│   │   └── providers/
│   │       └── message_provider.dart     # Realtime stream
│   │
│   ├── compose/
│   │   ├── screens/
│   │   │   └── compose_screen.dart       # Text + photo compose
│   │   ├── widgets/
│   │   │   ├── template_picker.dart
│   │   │   └── photo_preview.dart
│   │   └── providers/
│   │       └── compose_provider.dart
│   │
│   ├── widget_config/
│   │   ├── screens/
│   │   │   └── widget_theme_screen.dart  # Pick theme for widget
│   │   └── providers/
│   │       └── widget_theme_provider.dart
│   │
│   └── settings/
│       └── screens/
│           └── settings_screen.dart      # Account, unlink, subscription
│
├── services/
│   ├── widget_service.dart               # Platform channel to native widget
│   ├── notification_service.dart         # FCM setup
│   └── realtime_service.dart             # Supabase Realtime lifecycle
│
└── native/                               # Reference — actual code in platform dirs
    ├── ios/     → ios/LovepinWidget/     # WidgetKit extension
    └── android/ → android/app/src/.../   # AppWidgetProvider
```

### 5.3 Key Screens

| Screen | Purpose |
|---|---|
| **Login / Signup** | Supabase Auth (email + password) |
| **Profile Setup** | Display name, avatar |
| **Couple Link** | Generate code / enter partner's code |
| **Home (Feed)** | Scrollable message timeline, FAB to compose |
| **Compose** | Text input, template picker, photo attach, send button |
| **Widget Theme** | Preview + select widget pastel theme |
| **Settings** | Account info, unlink couple, subscription management |

---

## 6. Home Screen Widget Implementation

### 6.1 iOS — WidgetKit

**Setup:**
- Create a Widget Extension target in the Xcode project (inside `ios/`).
- Widget type: `StaticConfiguration` (or `IntentConfiguration` if adding user-configurable theme later).
- Supported families: `.systemSmall`, `.systemMedium`.

**Data sharing (Flutter → Widget):**
- Use **App Groups** to share data between the Flutter app and the widget extension.
- Flutter writes latest message data to `UserDefaults(suiteName: "group.com.lovepin.app")` via `shared_preferences` or a platform channel.
- The widget extension reads from the same App Group `UserDefaults`.

**Refresh strategy:**
```swift
// In the Flutter app (via platform channel) after receiving a new message:
import WidgetKit
WidgetCenter.shared.reloadTimelines(ofKind: "LovepinWidget")
```

- **Timeline provider** returns a single entry (the latest message) with `.after(date)` refresh policy set 15 minutes ahead as fallback.
- **Push-triggered reload:** Use a Notification Service Extension to call `WidgetCenter.shared.reloadTimelines` when an FCM silent push arrives. This is the best-effort near-real-time path on iOS.
- **Budget reality:** iOS grants ~40–70 widget reloads per day. Combine timeline + push-triggered reloads. For most couples sending 5–20 messages/day, this is sufficient.

**Widget UI (SwiftUI):**
```swift
struct LovepinWidgetEntryView: View {
    var entry: MessageEntry

    var body: some View {
        ZStack {
            // Pastel gradient background from selected theme
            LinearGradient(colors: [entry.theme.bgColor, .white],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 8) {
                if let imageData = entry.thumbnailData {
                    // Polaroid frame: white border + shadow
                    Image(uiImage: UIImage(data: imageData)!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(6)
                        .background(Color.white)
                        .shadow(radius: 2)
                }

                Text(entry.content)
                    .font(.custom("Caveat", size: 16))
                    .foregroundColor(entry.theme.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Text(entry.senderName)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(12)
        }
    }
}
```

### 6.2 Android — AppWidget (Glance / RemoteViews)

**Setup:**
- Create an `AppWidgetProvider` subclass in `android/app/src/main/java/...` (or Kotlin).
- Register in `AndroidManifest.xml` with `<receiver>` and `<appwidget-provider>` metadata.
- Widget layout: XML-based `RemoteViews` (or Jetpack Glance for Compose-style API, requires Android 12+).

**Data sharing (Flutter → Widget):**
- Flutter writes latest message to `SharedPreferences` via `shared_preferences` plugin (automatically accessible in native Android code).
- Alternatively, use `home_widget` Flutter plugin which wraps both iOS App Groups and Android SharedPreferences.

**Refresh strategy:**
```kotlin
// Triggered from FCM onMessageReceived or Flutter platform channel:
val intent = Intent(context, LovepinWidgetProvider::class.java).apply {
    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
}
val ids = AppWidgetManager.getInstance(context)
    .getAppWidgetIds(ComponentName(context, LovepinWidgetProvider::class.java))
intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
context.sendBroadcast(intent)
```

- **Android has no strict refresh budget** like iOS. Widgets can be updated via broadcast at any time.
- On FCM data message receipt → background handler saves message to SharedPreferences → triggers `sendBroadcast` → widget redraws.
- This achieves **near-instant** widget updates on Android.

### 6.3 Recommended Flutter Plugin

Use **[`home_widget`](https://pub.dev/packages/home_widget)** (pub.dev) — it provides a unified API for:
- Saving data to App Group (iOS) / SharedPreferences (Android)
- Triggering widget updates on both platforms
- Registering background callbacks for interactive widgets

```dart
// After receiving a new message:
await HomeWidget.saveWidgetData<String>('message_content', message.content);
await HomeWidget.saveWidgetData<String>('sender_name', message.senderName);
await HomeWidget.saveWidgetData<String>('image_path', localThumbnailPath);
await HomeWidget.saveWidgetData<String>('theme_bg', selectedTheme.backgroundColor);
await HomeWidget.updateWidget(
  iOSName: 'LovepinWidget',
  androidName: 'LovepinWidgetProvider',
);
```

### 6.4 Summary: Widget Refresh Best-Effort Strategy

| Platform | Trigger | Latency | Notes |
|---|---|---|---|
| **Android** | FCM data msg → broadcast → widget redraw | 1–5 sec | Reliable, no budget limit |
| **iOS (foreground)** | Realtime → platform channel → `reloadTimelines` | 1–3 sec | Immediate |
| **iOS (background)** | FCM silent push → Notification Service Extension → `reloadTimelines` | 5–30 sec | Subject to system budget |
| **iOS (fallback)** | Timeline refresh every 15 min | ≤ 15 min | Worst case |

---

## 7. Development Roadmap

### Phase 1 — Foundation (Weeks 1–2)

- [ ] Flutter project setup, folder structure, Riverpod, GoRouter
- [ ] Supabase project creation: Auth, DB tables, RLS policies, Storage bucket
- [ ] Auth flow: signup, login, session persistence
- [ ] Profile setup screen
- [ ] Couple linking: generate code, enter code, link confirmation
- [ ] Basic navigation shell (bottom nav or tab)

**Milestone:** Two users can sign up and become a linked couple.

### Phase 2 — Core Messaging (Weeks 3–4)

- [ ] Compose screen: text message input + send
- [ ] Photo attach: gallery picker, image compression, Supabase Storage upload
- [ ] Message feed screen: query messages by couple_id, display as polaroid cards
- [ ] Supabase Realtime: subscribe to couple channel, live message updates
- [ ] Local caching: Hive/SQLite for offline message feed

**Milestone:** Couples can exchange text and photo messages in real-time within the app.

### Phase 3 — Widget (Weeks 5–6)

- [ ] `home_widget` plugin integration
- [ ] Android AppWidget: layout XML, provider, SharedPreferences bridge
- [ ] iOS WidgetKit: extension target, App Group, SwiftUI view
- [ ] Platform channel: Flutter → native widget update trigger
- [ ] FCM setup: firebase_messaging, background handler
- [ ] Supabase Edge Function: on message insert → send FCM to partner
- [ ] Widget tap → deep link into app

**Milestone:** New message appears on partner's home screen widget without opening the app.

### Phase 4 — Polish & Templates (Weeks 7–8)

- [ ] Emotional templates: seed database, template picker UI, category browsing
- [ ] Widget theme system: 3 free pastel themes, theme picker screen
- [ ] Polaroid card styling refinement (shadows, fonts, spacing)
- [ ] Handwriting font integration (Caveat, Nanum Pen Script)
- [ ] Read receipt indicator (subtle "seen" dot)
- [ ] Settings screen: account info, couple unlink, app info

**Milestone:** Feature-complete MVP with polished, emotional UI.

### Phase 5 — Monetization & Launch Prep (Weeks 9–10)

- [ ] RevenueCat or in-app purchase setup (iOS + Android)
- [ ] Premium gate: additional themes, fonts, templates
- [ ] Ad placement (tasteful — e.g., bottom banner on feed, not on widget)
- [ ] App Store / Play Store listing assets, screenshots, description
- [ ] Crash reporting (Sentry / Crashlytics)
- [ ] Analytics (Mixpanel / Firebase Analytics) — key events: signup, link, send, widget_view
- [ ] TestFlight / Internal testing track

**Milestone:** Ready for closed beta / soft launch.

---

## Appendix: Design Reference Image Influence

> **Note:** The reference images from `C:\coding\gptcli\Lovepin\image` were not directly accessible in the build environment. The design direction below is based on the user's described aesthetic. When images are uploaded, refine these decisions accordingly.

| Design Element | Assumed Direction | Adapt If Images Show... |
|---|---|---|
| **Color palette** | Soft pink, lavender, cream, sky blue pastels | Specific hex values, gradient angles |
| **Card style** | Polaroid frame (white border, drop shadow, rounded 16dp) | Different frame style (tape, sticker, stamp) |
| **Typography** | Handwriting accent (Caveat) + rounded sans body (Nunito) | Specific font names or weight preferences |
| **Widget layout** | Centered text, optional thumbnail above, sender name below | Different information hierarchy or layout |
| **Iconography** | Thin line-art, warm emotional icons | Filled icons, specific icon set |
| **Background** | Soft gradient or flat pastel | Textured, pattern, illustration-based |

Upload the images and I will revise specific hex values, font choices, and component styling to match.
