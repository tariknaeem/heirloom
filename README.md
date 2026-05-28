# Heirloom 🌳

A bright, Apple-style **family-tree app** for Android & iOS. Build your family,
add photos, life events and stories, and get birthday & anniversary reminders.
**Local-first** — everything stays on your device (fast, private, offline).

## ⬇️ Download (Android)

Grab the latest APK from the **[Releases page](../../releases/latest)**.

1. Download `heirloom.apk` to your Android phone.
2. Open it — if prompted, allow installing from this source ("Install unknown apps").
3. Launch **Heirloom** and create your profile to start your tree.

> The APK is **debug-signed** for free distribution. Android will show an
> "unknown developer" warning — that's expected for apps installed outside the
> Play Store. It is safe to install; the source is in this repo.

## Features

- **Family tree** with 3 switchable layouts — pedigree, horizontal generations, and a card list — pan & pinch to explore, tap to focus.
- **Profiles** — hero photo, details, relationships, timeline, stories, and a photo gallery.
- **Timeline** — births, marriages, deaths and custom milestones per person.
- **Stories & photos** — capture memories and build a per-person gallery.
- **Reminders** — birthday & anniversary notifications for living relatives.
- **Backup & share** — export your whole tree as a portable `.zip` (data + photos), with an option to redact living relatives' private details.

## Tech

Flutter · Riverpod · SQLite (sqflite) behind a `FamilyRepository` interface
(local now, sync-ready). `flutter_local_notifications`, `image_picker`,
`share_plus`, `archive`.

## Build it yourself

```bash
flutter pub get
flutter test          # unit + widget tests
flutter build apk --release
flutter install       # to a connected device
```

## License

Personal project. Free to use.
