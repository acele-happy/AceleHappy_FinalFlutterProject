# VentureLink — ALU Internship & Startup Hub

VentureLink is a Flutter mobile application that connects ALU students seeking internship experience with student-led startups and early-stage ventures within the ALU ecosystem.

## Problem Statement

Many ALU students struggle to secure internships at established organizations, while campus entrepreneurs need support in software development, design, marketing, operations, research, and more. VentureLink bridges this gap with a verified, mobile-first platform.

## Features

### Core (Assignment Requirements)
- **Authentication & Onboarding** — ALU email-only registration (`@alueducation.com`), role selection (Student / Founder), guided profile setup
- **Startup Profiles** — Founder-created profiles with ALU admin verification workflow
- **Opportunity Posting** — Verified startups can post internships, projects, and volunteer roles
- **Discovery & Search** — Real-time opportunity feed with text search, type filters, and remote toggle
- **Applications** — Students submit cover letters; founders review and update status
- **Real-time Updates** — Firestore streams for opportunities, applications, bookmarks, and notifications
- **Firebase Backend** — Auth, Firestore, and Storage integration
- **State Management** — Riverpod (providers, stream providers, StateNotifier for filters)

### Beyond Minimum
- Skill-based opportunity recommendations
- Bookmarking / saved opportunities
- In-app notifications (application received, status changes, startup verified)
- Admin dashboard for startup verification
- Application tracking with status pipeline (Pending → Reviewing → Accepted/Rejected)

## Architecture

```
lib/
├── core/           # Theme, constants, router
├── models/         # Data models (User, Startup, Opportunity, Application)
├── services/       # Firebase service layer (repository pattern)
├── providers/      # Riverpod providers & state notifiers
├── features/       # Feature-based UI screens
└── widgets/        # Shared UI components
```

**State Management:** Riverpod was chosen for compile-safe dependency injection, first-class StreamProvider support for Firestore real-time data, and separation of UI from business logic.

**Navigation:** `go_router` with auth-aware redirects and shell routes for bottom navigation.

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project (e.g. `alu-venture-link`)
3. Enable **Authentication** → Email/Password
4. Create a **Firestore Database** 
5. Enable **Storage** 

### 2. Register Mobile Apps
Add Android and iOS apps in Firebase Console, then run:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (generates firebase_options.dart)
cd alu_venture_link
flutterfire configure
```

### 3. Deploy Firestore Rules & Indexes

```bash
firebase deploy --only firestore
```

Copy `firestore.rules` and `firestore.indexes.json` from this repo into your Firebase project.

### 4. Create Admin User
After registering a user, manually set their role in Firestore:

```
users/{uid}/role = "admin"
```

This grants access to the Admin Verification dashboard.

## Firestore Schema

| Collection | Key Fields |
|---|---|
| `users` | email, role, displayName, skills[], onboardingComplete |
| `startups` | founderId, name, industry, verificationStatus, aluProgram |
| `opportunities` | startupId, title, skills[], type, status, applicationCount |
| `applications` | opportunityId, studentId, startupId, coverLetter, status |
| `notifications` | userId, title, body, type, read |
| `users/{uid}/bookmarks` | opportunityId |

## Running the App

```bash
cd alu_venture_link
flutter pub get
flutter run   # Requires Android emulator or physical device
```

## Testing

```bash
flutter test
flutter analyze
```


