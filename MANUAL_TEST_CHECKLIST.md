# Manual Test Checklist (Android)

---

## Session 4 — 2026-05-27

Date: 2026-05-27
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Habits MVP

- [x] Add habit → Simpan → list refreshes immediately (no restart needed). ✅
- [x] Habit appears in list with emoji + name. ✅
- [x] Tap card → marked done, icon fills. ✅
- [x] Tap again → snackbar "Sudah dilakukan hari ini". ✅
- [x] Streak counter shows on card after marking done. ✅

### Notes
- Navigation fix: `context.pop()` instead of `context.go('/habits')` in AddHabitScreen — ensures FAB await resolves and `_load()` fires.
- Habit reminder notification not yet tested (requires waiting until set time).

---

## Session 3 — 2026-05-27

Date: 2026-05-27
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Water Reminder (post-fix)

- [x] Reminder toggle ON → notification fires in ~15 seconds (debug mode). ✅
- [x] "Sudah minum" action button → notification dismissed, no app launch. ✅
- [x] Glass count updates when Water screen is opened after tapping action. ✅
- [x] Reminder toggle OFF → notifications stop. ✅
- [x] Toggle OFF then ON → alarm reschedules correctly. ✅
- [x] +/- buttons do not affect reminder toggle state. ✅
- [x] Settings sheet: change target, glass size, hours → interval recalculates. ✅
- [x] Notification always shows as banner regardless of phone state. ✅

### Notes
- flutter_local_notifications action callbacks blocked by ColorOS on background broadcasts — replaced with native WaterAlarmReceiver + WaterActionReceiver.
- android_alarm_manager_plus is still in pubspec but unused for water (kept to avoid breaking changes).

---

## Session 2 — 2026-05-27

Date: 2026-05-27  
Device: Realme GT 2 Pro (RMX3301), Android 14  
Build: Debug

### Alarm System (post-fix)

- [x] App builds and installs successfully.
- [x] **Screen OFF** — alarm fires → ReminderActivity appears above lock screen (full-screen). ✅
- [x] **Screen ON / home** — alarm fires → notification banner appears. Tap → ReminderActivity opens. ✅
- [x] **Snooze** — tap "Tunda 1 menit" → activity closes → reappears after 1 minute. ✅
- [x] **Add medicine** — after saving, app navigates directly to medicine list (no manual back needed). ✅

### Notes
- Screen-ON behavior shows banner (not forced full-screen) — this is correct Android behavior, intentional.
- "Display over other apps" permission auto-granted on debug install.
- Gradle OOM fixed: daemon disabled, `-Xmx512m` in `gradle.properties`.

---

## Session 1 — 2026-05-25  
Device: Android 16
Build: Debug / Release (circle one)

## 0) Pre-check

- [X] `flutter run` builds successfully.
- [X] App opens to `Beranda`.
- [-] Permission popup appears on `Beranda` (Izin Wajib).
- [-] Tap `Notifikasi` and allow permission.
- [-] Tap `Exact Alarm` and allow permission.
- [-] Tap `Full Screen` and allow permission.
- [-] Tap `Selesai`.

## 1) Navigation Back Behavior

- [X] Tap `Obat` from `Beranda`.
- [X] Press Android back button.
- [X] Expected: returns to `Beranda` (app does not close).
- [X] Repeat for `Air` and `Kebiasaan` screens.

## 2) Add Medicine Flow

- [X] Open `Obat`.
- [X] Tap `+` button.
- [X] Fill `Nama obat`.
- [X] (Optional) Fill `Dosis`.
- [X] Pick `Waktu minum`.
- [X] Tap `Simpan`.
- [-, I needed to go back to beranda and back to obat] Expected: back to medicine list with new item visible.

## 3) Alarm Trigger Baseline

- [X] Create a medicine with near-future time (easy to wait).
- [X] Wait until scheduled time.
- [X] Expected: medicine notification appears with:
  - `Sudah diminum`
  - `Tunda 1 menit`

## 3A) Full-screen Reminder Flow

- [ ] Tap the medicine notification body (not action button).
- [ ] Expected: app opens `Pengingat Obat` full-screen page.
- [ ] Expected: back button is blocked on this page.
- [ ] Expected: only two actions are available:
  - `Sudah diminum`
  - `Tunda 1 menit`

## 4) Re-notify Every 10 Minutes

- [] Ignore the first medicine notification.
- [] Wait ~10 minutes.
- [] Expected: same medicine notification appears again.

## 4A) Fast Persistent Test (1-minute loop)

- [X] Open `Obat`.
- [X] Tap small `timer` button (test persistent 1m).
- [X] Expected: snackbar says first notif in ~10s and repeats every 1 min.
- [X] Wait ~10 seconds.
- [X] Expected: notification appears.
- [X] Ignore it and wait ~1 minute.
- [X] Expected: notification repeats.
- [-] Tap `Sudah diminum`.
- [ ] Wait >1 minute.
- [ ] Expected: repeat stops.

## 5) "Sudah diminum" Stops Loop

- [ ] When notification appears, tap `Sudah diminum`.
- [ ] Wait >10 minutes.
- [ ] Expected: no repeat notification for that reminder cycle.

## 6) "Tunda 15 menit" Works

- [ ] Trigger medicine notification again.
- [ ] Tap `Tunda 1 menit`.
- [ ] Wait ~1 minute.
- [ ] Expected: notification appears again.
- [ ] Ignore this reappeared notification once.
- [ ] Wait ~10 minutes.
- [ ] Expected: loop resumes every ~10 minutes until `Sudah diminum`.

## 7) App Lifecycle Sanity

- [ ] Force close app.
- [ ] Reopen app.
- [ ] Add another medicine reminder.
- [ ] Expected: add flow still works, reminder still notifies.

## 8) Result Summary

### Pass

- [ ] Navigation back behavior
- [ ] Add medicine flow
- [ ] First reminder notification
- [ ] 10-minute re-notify
- [ ] "Sudah diminum" stop logic
- [ ] "Tunda 1 menit" snooze logic

### Notes / Bugs Found

- No pop-up permission when opened the app, its because I already installed? 
- Can't tap sudah diminum dan tunda 1 menit
- ____________________________________________
