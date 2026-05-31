# Development Workflow

## Environment

| Tool | Purpose |
|---|---|
| Flutter 3.44 | Framework + CLI (`flutter run`, `flutter build`) |
| VS Code | Editor (Flutter + Dart extensions) |
| Android Studio | Android emulator + SDK tools only |
| Physical Android device | Primary testing target |

## Daily Dev Loop

```
1. flutter run          # start app on device/emulator (hot reload enabled)
2. Edit code in VS Code
3. Save -> hot reload   # changes appear instantly, no restart needed
4. Test on physical device for notifications (emulator is unreliable for alarms)
```

## Branch Strategy

```
main          # stable, working app
dev           # active development
feat/xxx      # individual features (feat/medicine-reminder, feat/water-tracker)
fix/xxx       # bug fixes
```

## Feature Build Order

Follow this order - each builds on the previous:

1. **Project scaffold** - Flutter init, packages, folder structure, theme
2. **Hive setup** - data models, storage init
3. **Medicine feature** - model -> repository -> notification service -> UI
4. **Water feature** - model -> repository -> reminder -> UI
5. **Habits feature** - model -> repository -> UI
6. **Home screen** - combine all three into today view
7. **Polish** - transitions, empty states, edge cases

## Testing Approach

| What | How |
|---|---|
| Notifications | Physical device only - emulators skip alarms |
| UI | Hot reload on device |
| Data persistence | Kill app, reopen - data should survive |
| Alarm reliability | Lock phone, wait for scheduled time |

## Reminder Reliability Notes (Realme GT 2 Pro / Android 14)

- Notification permission must be enabled manually in system settings.
- Exact alarm permission ("Alarms & reminders") must be enabled manually.
- OEM battery manager can suppress repeat/full-screen behavior; set battery mode to unrestricted for this app while testing.
- Use [MANUAL_TEST_CHECKLIST.md](../MANUAL_TEST_CHECKLIST.md) as source of truth for manual QA.
- Current known gap: forced full-screen re-open on every repeat is not yet consistently reliable across all cases/devices.

## Sleep Mode Cross-Device Notes

- Sleep mode does not read body sensors. Its foreground service must use Android type `specialUse`, not `health`.
- Native manifest changes require a full `flutter run` rebuild. Hot restart does not replace the installed Android manifest.
- Native Kotlin notification-copy changes also require a full rebuild. Hot restart is enough for Dart-only copy changes after the rebuilt app is installed.
- The morning gate home-button intercept requires the Rutin Accessibility Service to be enabled on each phone.
- Infinix X6873 startup fix: register SleepModeService dynamic receivers as `RECEIVER_NOT_EXPORTED` on Android 13+.
- Morning Gate deduplication fix: accessibility recovery brings the existing MainActivity task forward without sending a new `/morning-gate` route extra.
- Both sleep-mode fixes were manually verified on Infinix X6873 after the full native rebuild.
- Enabling Mode Tidur outside the nightly window arms a silent native bedtime alarm. It does not run `SleepModeService` or show a notification all day.
- At bedtime, `SleepScheduleReceiver` starts the foreground service and Android shows `Mode tidur aktif` with the `Saya masih terjaga` action.
- After the wake window or normal gate dismissal, the service stops and schedules tomorrow's bedtime alarm.

## Useful Flutter Commands

```bash
flutter pub get           # install packages after adding to pubspec.yaml
flutter run               # run app (connects to device or emulator)
flutter run --release     # test release build performance
flutter build apk         # build installable APK
flutter clean             # clear build cache (fixes weird errors)
flutter doctor            # check environment health
```

## Adding a Package

1. Open `pubspec.yaml`
2. Add under `dependencies:`
   ```yaml
   package_name: ^version
   ```
3. Run `flutter pub get`
4. Import in Dart file: `import 'package:package_name/package_name.dart';`
