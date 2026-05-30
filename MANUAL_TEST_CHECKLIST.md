# Manual Test Checklist (Android)

---

## Session 11 - 2026-05-30

Date: 2026-05-30
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Obat - Today workflow

- [ ] Open `Obat`.
- [ ] Expected: the first view is `Hari ini`, not a flat medicine database list.
- [ ] Expected: sections appear for `Perlu diminum sekarang`, `Berikutnya`, `Sudah diminum`, and `Terlewat`.
- [ ] Add one new medicine.
- [ ] Expected: add flow includes food timing options `Bebas`, `Sebelum makan`, `Sesudah makan`, `Saat makan`.
- [ ] Expected: the saved dose card shows the selected food timing as a badge.

### Obat - Riwayat calendar

- [ ] Open `Obat` and tap the calendar button.
- [ ] Expected: a separate `Riwayat Obat` page opens.
- [ ] Expected: the month view shows colored dots for daily adherence state.
- [ ] Tap a date with medicine activity.
- [ ] Expected: the lower panel lists that day's doses with status like `Diminum`, `Terlewat`, or `Belum waktunya`.

### Obat - 1 minute persistence

- [ ] Create one medicine 1 minute ahead.
- [ ] Wait for the reminder.
- [ ] Ignore or dismiss it.
- [ ] Expected: it comes back about 1 minute later until `Sudah diminum`.

---

## Session 10 - 2026-05-30

Date: 2026-05-30
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Obat - daily re-arm + swipe delete

- [ ] Add one medicine 1-2 minutes ahead.
- [ ] Wait until the alarm fires.
- [ ] Open `Obat` after the alarm appears.
- [ ] Expected: the medicine card shows a green debug line like `Berikutnya besok HH:MM`.
- [ ] Tap `Sudah diminum`.
- [ ] Re-open `Obat`.
- [ ] Expected: the green `Berikutnya besok HH:MM` line is still there for that medicine time.
- [ ] Swipe the medicine card left.
- [ ] Expected: red delete background appears.
- [ ] Confirm delete.
- [ ] Expected: medicine is removed and no longer appears in the list.

### Kebiasaan - timer placement

- [ ] Open `Kebiasaan`.
- [ ] Find a habit with a reminder time.
- [ ] Expected: the time pill sits on the right side of the card like Obat, not under the habit name.
- [ ] Expected: the color still feels like Kebiasaan / rutinitas, not pink medicine styling.

### Air - inline undo

- [ ] Open `Air`.
- [ ] Tap the main add-water button.
- [ ] Expected: no snackbar appears.
- [ ] Expected: an inline undo bar appears directly under the main add button.
- [ ] Tap `Urungkan`.
- [ ] Expected: the ml total returns to the previous value.

---

## Session 5 - 2026-05-27

Date: 2026-05-27
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Delete & Medal

- [x] Swipe left on Obat -> confirm dialog -> item removed
- [x] Swipe left on Kebiasaan -> confirm dialog -> item removed
- [x] Long-press Kebiasaan card -> `Jadikan Medali` -> habit removed from list
- [x] Medal snackbar appears after retiring

---

## Session 4 - 2026-05-27

Date: 2026-05-27
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Habits MVP

- [x] Add habit -> `Simpan` -> list refreshes immediately
- [x] Habit appears in list with emoji + name
- [x] Tap card -> marked done
- [x] Tap again -> `Sudah dilakukan hari ini`
- [x] Streak counter shows on card after marking done

---

## Session 3 - 2026-05-27

Date: 2026-05-27
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Water Reminder

- [x] Reminder toggle ON -> notification fires in debug mode
- [x] `Sudah minum` action dismisses notification without app launch
- [x] Water count updates after opening Water screen
- [x] Reminder toggle OFF stops notifications

---

## Session 2 - 2026-05-27

Date: 2026-05-27
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Alarm System

- [x] App builds and installs successfully
- [x] Screen OFF -> alarm fires -> ReminderActivity appears above lock screen
- [x] Screen ON -> banner appears -> tap opens ReminderActivity
- [x] `Tunda 1 menit` reappears after 1 minute
- [x] Add medicine returns directly to medicine list after save
