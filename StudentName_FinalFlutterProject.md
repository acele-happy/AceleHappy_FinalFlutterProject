# VentureLink: ALU Internship & Startup Hub
## Final Flutter Project — Technical Report

**Author:** [Your Full Name]  
**Institution:** African Leadership University (ALU)  
**Course:** Mobile Development  
**Date:** July 2026  
**GitHub Repository:** [https://github.com/YOUR_USERNAME/alu_venture_link](https://github.com/YOUR_USERNAME/alu_venture_link)  
**Demo Video:** [Link to 7–10 minute demo]

---

## Abstract

VentureLink is a Flutter mobile app that connects ALU students with campus startups for internships, projects, and volunteer roles. It uses Firebase Authentication and Cloud Firestore for the backend, Riverpod for state management, and go_router for navigation. The app supports three roles—students, founders, and admins—with real-time data updates across discovery, applications, bookmarks, and notifications.

---

## 1. Introduction

### Problem
ALU students often struggle to find internships, while student founders need help with development, design, marketing, and operations. General job boards do not fit ALU's verification and trust requirements.

### Solution
VentureLink is a mobile-first platform where:
- **Students** discover opportunities, apply, and track status.
- **Founders** create startups, post roles after verification, and review applications.
- **Admins** verify startups before they can publish listings.

### Tech Stack
Flutter, Dart, Riverpod, go_router, Firebase Auth, Cloud Firestore, Google Fonts (Inter), Material Design 3.

---

## 2. System Architecture

VentureLink uses a **feature-first layered architecture**:

```
UI (features/, widgets/)
        ↓ ref.watch / ref.read
State (providers/app_providers.dart)
        ↓
Services (services/firebase_service.dart)
        ↓
Models + Firebase (Auth, Firestore)
```

**Why this structure?** Screens stay focused on UI, Firebase logic stays in services, and Riverpod connects the two without passing dependencies through every widget.

### Navigation
`go_router` handles auth-aware routing:
- Unauthenticated users → `/login`
- Authenticated but not onboarded → `/onboarding`
- Onboarded users → `/home` (bottom navigation shell)

Main tabs: **Discover | Applications | Saved | Profile**

### Architecture Diagram

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Login/Register│────▶│  Onboarding  │────▶│  Home Shell  │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                    ┌─────────────┬───────────────┼───────────────┐
                    ▼             ▼               ▼               ▼
               Discover    Applications      Bookmarks        Profile
                    │                                             │
                    └──────── Opportunity Detail / Apply ─────────┘
```

---

## 3. Firebase Backend

### Collections

| Collection | Purpose | Key Fields |
|------------|---------|------------|
| `users` | Profiles | email, role, displayName, skills, onboardingComplete |
| `startups` | Founder companies | founderId, name, verificationStatus |
| `opportunities` | Job listings | startupId, title, skills, status, applicationCount |
| `applications` | Student submissions | studentId, opportunityId, coverLetter, status |
| `notifications` | In-app alerts | userId, title, body, type, read |
| `users/{uid}/bookmarks` | Saved opportunities | opportunityId |

### Schema Relationships

```
User ──founds──▶ Startup ──posts──▶ Opportunity
  │                                      │
  ├──applies──▶ Application ◀─────────────┘
  ├──receives──▶ Notification
  └──bookmarks──▶ Opportunity
```

**Denormalization:** Fields like `startupName` and `studentName` are copied onto child documents to avoid extra reads on list screens—a common mobile optimization.

### Security Rules
- Users read/update their own profile; admins can update any user.
- Startups are readable by all signed-in users; only founders or admins can update.
- Applications are readable by the student, startup founder, or admin.
- Notifications are scoped to the recipient.

### Indexes
Composite indexes support queries on `status`, `startupId`, `studentId`, and `verificationStatus` combined with `createdAt`.

---

## 4. State Management (Riverpod)

### Why Riverpod?
1. **Firestore streams** map directly to `StreamProvider` for live updates.
2. **Services are injected** via `Provider` without constructor drilling.
3. **Local UI state** (search filters) uses `StateNotifierProvider` separately from server data.

### Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `authStateProvider` | StreamProvider | Firebase Auth session |
| `currentUserProvider` | StreamProvider | Firestore user profile |
| `openOpportunitiesProvider` | StreamProvider | Live opportunity feed |
| `opportunityFilterProvider` | StateNotifierProvider | Search, type, remote filters |
| `filteredOpportunitiesProvider` | Provider | Combines stream + filters |
| `notificationsProvider` | StreamProvider.family | Per-user notifications |

**Pattern:** Streams for reads, imperative service calls for writes (`signIn`, `submitApplication`). Firestore listeners update the UI automatically after mutations.

---

## 5. Application Workflows

### Student
1. Register with ALU email (`@alueducation.com` or `@alustudent.com`)
2. Complete onboarding (major, skills, bio)
3. Browse and filter opportunities on Discover
4. Apply with cover letter; bookmark favorites
5. Track status on Applications tab; receive notifications

> [SCREENSHOT: Discover screen] [SCREENSHOT: Application form]

### Founder
1. Register as Founder; create startup (status: pending)
2. Admin verifies startup
3. Post opportunities via FAB button
4. Review applications and update status (Pending → Reviewing → Accepted/Rejected)

> [SCREENSHOT: Create opportunity] [SCREENSHOT: Review application]

### Admin
1. Role set manually in Firestore (`role: admin`)
2. Open Admin Dashboard from Profile
3. Verify or reject pending startups

> [SCREENSHOT: Admin dashboard]

---

## 6. UI/UX Reasoning

| Decision | Rationale |
|----------|-----------|
| Forest green (`#1B4332`) + tan accent (`#D4A373`) | Professional ALU campus identity |
| Material 3 + Inter font | Modern, readable mobile UI |
| Bottom navigation (4 tabs) | Thumb-friendly; matches browse → act → save → account flow |
| Role cards on registration | Faster than dropdowns on mobile |
| Empty states with CTAs | Guides new users instead of blank screens |
| Verification badges | Builds trust in startup listings |
| Status chips on applications | Clear pipeline visibility |

---

## 7. Scalability

**Current strengths:** Real-time Firestore streams, denormalized documents, feature-based modules, composite indexes, security rules.

**Bottlenecks and mitigations:**

| Issue | Future fix |
|-------|------------|
| Firestore `whereIn` limit (10 items) | Pagination or Cloud Functions |
| Client-side sorting | Server-side `orderBy` using existing indexes |
| Permissive opportunity rules | Tighten rules with founder ownership checks |
| No push notifications | Add Firebase Cloud Messaging |

---

## 8. Challenges & Lessons Learned

| Challenge | Solution | Lesson |
|-----------|----------|--------|
| Android sign-in failed (reCAPTCHA) | Added SHA-1/SHA-256 fingerprints to Firebase Console | Mobile Firebase Auth needs certificate registration |
| Auth vs. profile race condition | Router waits for both Auth UID and Firestore user doc | Auth and app profile are separate data sources |
| Two ALU email domains | Centralized `isAllowedAluEmail()` helper | Validate domains in one place, not per screen |
| Combining streams + filters | Separate `StreamProvider` and `StateNotifierProvider` | Keep network state and UI state decoupled |

---

## 9. Testing

**Automated:** Unit tests for `filterOpportunities()` (search, skill, remote filters) in `test/widget_test.dart`. Static analysis via `flutter analyze`.

**Manual:** Registration, onboarding, discovery, apply, founder posting, admin verification, notifications, sign out.

**Limitation:** No Firebase mocks or integration tests yet—manual device testing was used for auth and Firestore flows.

---

## 10. Limitations

- No push notifications (in-app only)
- No file uploads (Storage declared but unused)
- No in-app messaging
- Founders cannot edit/close opportunities from UI
- Light theme only
- Thin automated test coverage

---

## 11. Future Improvements

1. Firebase Cloud Messaging for push alerts
2. In-app messaging between students and founders
3. Firebase Storage for startup logos and profile photos
4. Tighter Security Rules with custom admin claims
5. Integration tests with Firebase Emulator Suite
6. Opportunity edit/close and deadline support

---

## 12. Conclusion

VentureLink delivers a functional MVP for ALU's internship ecosystem using Flutter, Firebase, and Riverpod. The feature-based architecture, real-time Firestore streams, and role-based workflows address real campus needs. Documented limitations provide a clear path for production hardening.

---

## References

[1] Google, *Flutter Documentation*, 2026. https://docs.flutter.dev/

[2] Google, *Firebase Documentation*, 2026. https://firebase.google.com/docs

[3] R. Rousselet, *Riverpod Documentation*, 2026. https://riverpod.dev/

[4] Google, *go_router Package*, Pub.dev, 2026. https://pub.dev/packages/go_router

[5] Google, *Cloud Firestore Data Model*, 2026. https://firebase.google.com/docs/firestore/data-model

---

## Appendix: Demo Video Outline (7–10 min)

| Time | Content |
|------|---------|
| 0:00 | Intro: problem and solution |
| 1:00 | Student flow: register → discover → apply |
| 3:00 | Founder flow: create startup → post opportunity |
| 4:30 | Admin verification + application review |
| 6:00 | Show Firebase Console + Riverpod providers in code |
| 7:30 | Challenges, limitations, conclusion |

---

*Replace [Your Full Name] and links before submission. Insert screenshots where marked.*
