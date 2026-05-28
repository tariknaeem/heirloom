# Heirloom — family-tree app (Flutter, Android + iOS)

**Date:** 2026-05-28
**Status:** Approved design
**Location:** `~/projects/heirloom` (new project)

## 1. Goal
A bright, **apple.com-style** family-tree app for Android + iOS: build your family, add photos, life events, stories, and get birthday/anniversary reminders. **Local-first** (fast, private, offline) but architected so cloud sync can be added later. Built personal-first but at **publishable quality** (could ship to the App/Play Store).

## 2. Decisions (from brainstorming, 2026-05-28)
- **Purpose:** Both — personal keepsake, clean enough to publish later.
- **Data:** Local-first, **sync-ready** (repository interface; cloud impl deferred).
- **Features (all four bundles):** core tree + profiles + photos · life events & timeline · stories & memories · reminders & sharing.
- **Tree view:** **3 switchable layouts** — top-down pedigree, horizontal generations, vertical card list. (Radial fan chart deferred; the view-switcher makes adding it later easy.)
- **Name:** Heirloom.

## 3. Stack
- **Flutter** (one codebase → Android + iOS), **Riverpod** for state.
- **Drift (SQLite)** behind a **`FamilyRepository` interface** — local impl now; future `CloudFamilyRepository` (Firebase/Supabase) implements the same interface = sync-ready.
- `image_picker` (photos → app docs dir, paths in DB), `flutter_local_notifications` (reminders), `share_plus` (export/share), `intl`, `uuid`, `path_provider`.

## 4. Data model
- **Person**: id, displayName, given/family, gender, birthDate, deathDate, isLiving, photoPath, bio.
- **Relationship**: type (`parent_child` | `spouse`), personA, personB. (parent→child edges build the tree; spouse edges link partners.)
- **Event**: personId, type (birth/death/marriage/custom), date, place, note → drives timeline + reminders.
- **Story**: personId, title, body, createdAt. **MediaItem**: personId, filePath, caption (per-person gallery).
- Repository query primitives: ancestors, descendants, siblings, spouses.

## 5. Screens
- Onboarding → create "Me".
- **Tree** (signature): `InteractiveViewer` canvas (pan + pinch-zoom) + **layout switcher** (3 views); tap card → profile; "focus" re-centers tree on any person.
- **Profile**: hero photo, details, relationships, timeline, stories, photo gallery, edit.
- Add/Edit person + relationship picker.
- Settings: backup/export & share (portable tree file: zip of JSON + images), reminders toggle, "hide living people's details on share" (privacy).

## 6. Theme
White/`#fbfbfd` backgrounds, San Francisco type (Cupertino on iOS, system on Android), 18px rounded cards, soft shadows, Apple-blue accent, generous whitespace, hero photo transitions.

## 7. Build phasing (one app, shipped in slices)
1. **Core** — data layer + repository + add people/relationships + photos + the 3 tree views + profile. (the heart)
2. **Events & timeline.**
3. **Stories & photo gallery.**
4. **Reminders & share/export.**

## 8. Testing
Unit: repository CRUD + ancestor/descendant/sibling queries; tree-layout algorithm (node positions per generation); reminder-date computation. Widget: Tree + Profile screens.

## 9. Out of scope (v1)
Real-time multi-user cloud collaboration (deferred to the sync-ready layer); GEDCOM import from Ancestry/MyHeritage; radial fan view.
