# Manual Test Checklist (Android)

Date: 5/25/2026 - Test 1  
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
