# Manual Test Checklist (Android)

---

## Release Candidate Gate - Before Public Release

Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Release candidate APK / final debug candidate

### Install / upgrade safety

- [ ] Fresh install opens without red screen.
- [ ] Upgrade over an existing installed build keeps user data and still opens cleanly.
- [ ] App cold start succeeds after the device has been restarted.

### Onboarding / first-run setup

- [ ] Fresh install shows onboarding only once.
- [ ] Permission bottom sheet advances step by step and does not disappear after the first permission tap.
- [ ] Returning from Android settings does not break navigation or leave the app in a stuck state.
- [ ] Settings -> Tutorial replays the coach marks correctly.

### Medicine reliability

- [ ] Medicine alarm fires when the app is foregrounded.
- [ ] Medicine alarm still fires when the app is backgrounded.
- [ ] Medicine alarm still fires when the phone is locked.
- [ ] `Sudah diminum` stops the repeating alarm loop.
- [ ] Ignoring a medicine alarm causes it to return about 1 minute later.
- [ ] Overdue untaken dose appears correctly in UI on the same day.
- [ ] Previous-day untaken dose is finalized as `missed` after day rollover.

### Habit reminder reliability

- [ ] Habit reminder appears when the screen is on.
- [ ] Habit reminder appears when the screen is off / lock screen is shown.
- [ ] Multi-time habit fires at both scheduled times.
- [ ] Habit with schedule `Mon, Wed, Fri` does not notify on Tuesday / Thursday.
- [ ] Reboot restores habit reminders with the same weekday rules.

### Water reminder reliability

- [ ] Water reminder continues on the expected cadence while the app is closed.
- [ ] Reboot does not reset the water cadence.
- [ ] `Sudah minum` action updates the app after reopening Water.
- [ ] Inline undo still works after repeated add/remove actions.

### Sleep mode reliability

- [ ] Battery guidance opens app settings successfully.
- [ ] Accessibility settings shortcut opens successfully.
- [ ] Accessibility status updates after returning from settings.
- [ ] Nightly sleep notification appears only during the configured sleep window.
- [ ] Morning Gate launches from a real sleep trigger, not only from the test button.
- [ ] Completing the wake-up game exits back to the app cleanly.
- [ ] Home / app switching during Morning Gate still returns to one active gate.

### Localization / UI consistency

- [ ] Main user flows have no mixed Indonesian/English leaks.
- [ ] Date and weekday formatting follows the selected locale.
- [ ] Native notification copy follows the selected locale.

### Data / settings safety

- [ ] Backup export succeeds and produces a shareable file.
- [ ] Profile name, age, and avatar persist after restart.
- [ ] Language choice persists after restart.
- [ ] Sleep settings persist after restart.

### Play Store / release sanity

- [ ] Release APK installs manually on the real phone.
- [ ] App icon, app name, and splash all appear correctly.
- [ ] No obvious debug-only labels, test buttons, or broken placeholders remain in the release candidate build.

---

## Session 21 - 2026-05-31

Date: 2026-05-31
Device: Infinix X6873
Build: Debug - full native rebuild required

### Runtime localization

- [ ] Fresh-install with phone language Indonesian. Expected: Rutin opens in Indonesian.
- [ ] Fresh-install with an unsupported phone language. Expected: Rutin opens in English.
- [ ] Open `Profile` -> `Settings`, select `🇬🇧 EN`. Expected: visible navigation and normal-use screen copy switch immediately without restart.
- [ ] Close and reopen Rutin. Expected: English remains selected.
- [ ] Select `🇮🇩 ID`. Expected: Indonesian returns immediately.
- [ ] Trigger medicine, water, habit, and active sleep-mode notifications in both languages.
- [ ] Expected: native channel labels, title, body, actions, and medicine full-screen controls follow the selected language.

### Wake-up game test buttons

- [ ] Open `Mode Tidur`.
- [ ] Tap `Test Sequence`, `Test Rhythm`, and `Test Dots`.
- [ ] Expected: each button launches its own game directly.

---

## Session 22 - 2026-06-02

Date: 2026-06-02
Device: Realme GT 2 Pro / current test phone
Build: Debug - hot restart sufficient for latest Dart-only Obat fix, full restart required for prior native alarm settings change

### Obat - delete-only flow

- [ ] Open `Obat`.
- [ ] Expected: no archive button appears in the top-right header.
- [ ] Swipe a medicine card from right to left.
- [ ] Expected: only the red delete affordance appears.
- [ ] Confirm delete.
- [ ] Expected: the medicine disappears and does not return after reopening Obat.

### Obat - empty schedule safety

- [ ] Open `Obat` with any existing medicine data, including legacy data if present.
- [ ] Expected: the screen does not red-screen even if a medicine has no valid dose chips.
- [ ] If a malformed medicine exists with no schedule times, expected: the card shows `Belum ada jadwal dosis` instead of crashing.

### Medicine alarm - full-screen permission path

- [ ] Open `Profile` -> `Settings`.
- [ ] Find the `Full-screen alarm` row under medicine alarm settings.
- [ ] If it shows not allowed, tap `Allow`.
- [ ] Expected: Android opens the app-specific full-screen intent settings page.
- [ ] Enable full-screen alarms, return to Rutin, and reopen Settings.
- [ ] Expected: the row now shows allowed state.
- [x] Trigger a medicine alarm while Rutin is already foregrounded.
- [x] Expected: `ReminderActivity` takes over full-screen.
- [x] Trigger a medicine alarm while another app is in the foreground.
- [x] Observed on target phone: fallback is notification + alarm sound, which is accepted for now.

### Medicine history - missed finalization

- [ ] Create or keep a medicine with at least one scheduled dose.
- [ ] Let one dose pass without tapping `Sudah diminum`.
- [ ] On the same day, open `Riwayat Obat`.
- [ ] Expected: today's overdue untaken dose can show as missed in the UI, even before finalization.
- [ ] After the calendar day rolls over, reopen Rutin or open `Obat` / `Riwayat Obat`.
- [ ] Expected: yesterday's untaken dose now exists as a persisted missed log entry.
- [ ] Expected: the previous day in `Riwayat Obat` remains missed consistently after app restart.

---

## Session 23 - 2026-06-02

Date: 2026-06-02
Device: Realme GT 2 Pro / current test phone
Build: Debug - hot restart sufficient

### Profile identity + avatars

- [ ] Open `Profile`.
- [ ] Expected: header shows avatar area, user identity area, and three stat chips for best streak, medals, and habits done.
- [ ] Tap the avatar or edit badge.
- [ ] Expected: a bottom sheet opens with 10 avatar choices, name field, and age field.
- [ ] Pick a different avatar, enter a name, and save.
- [ ] Expected: the header updates immediately.
- [ ] Close and reopen Rutin.
- [ ] Expected: avatar, name, and age persist.

### EN sweep - low-frequency screens

- [ ] Switch app language to `EN`.
- [ ] Open `Profile` -> `Treatment Program` onboarding.
- [ ] Expected: date label, duration choices, linked-medicine field, and replace-program dialog are all in English.
- [ ] Open treatment detail with an active program.
- [ ] Expected: date formatting and PDF/export labels are English-friendly and no Indonesian leaks remain.
- [ ] Open `Mode Tidur` -> `Test Dots` and `Test Rhythm`.
- [ ] Expected: low-frequency game copy such as `Connect the Colors`, `Perfect`, `Good`, `Miss`, and the completion message appear in English.

---

## Session 20 - 2026-05-31

Date: 2026-05-31
Device: Infinix X6873
Build: Debug

### Settings screen

- [ ] Open `Profile` -> `Pengaturan`.
- [ ] Expected: Mode Tidur status and Accessibility status match the phone.
- [ ] Change Bahasa to `English`, close the app, and reopen Settings.
- [ ] Expected: the selected language preference persists.
- [ ] Expected: About shows `1.0.0 (build 1)` and `Ilham Maulana Sulaeman`.

### Habit history calendar

- [ ] Open `Kebiasaan` and tap the top-bar calendar button.
- [ ] Expected: the overall habit history screen opens, not a single-habit page.
- [ ] Expected: full days are purple, partial days amber, missed days dim white, and off-days stay muted.
- [ ] Expected: previous and next month buttons work.
- [ ] Tap a day and confirm the per-day habit breakdown below the calendar updates.

### Overall history

- [ ] Open `Profile` and tap `History`.
- [ ] Expected: the overall history screen opens from the hamburger/Profile area, not Settings.
- [ ] Expected: the day picker uses wrapped cards, not a sideways sliding strip.
- [ ] Expected: feed entries stack vertically and stay newest-first within the selected day.

### Medicine streak

- [ ] Open Obat with a medicine that has consecutive completed days.
- [ ] Expected: the card shows a `🔥 N` badge only when its computed streak is greater than zero.

### Wake-up game - Connect the Colors

- [ ] Open Mode Tidur and launch `/wakeup-game` with game index `5`.
- [ ] Expected: a seeded 6×6 board appears with four colored endpoint pairs.
- [ ] Drag from one endpoint to its matching color using orthogonal moves only.
- [ ] Expected: cells snap into the path, crossing another path erases that older path, and partial paths remain when you lift your finger.
- [ ] Expected: when all four pairs are connected and all 36 cells are filled, the celebration appears.

---

## Session 19 - 2026-05-31

Date: 2026-05-31
Device: Infinix X6873
Build: Debug - native bedtime scheduler installed

### Sleep mode - night-only notification

- [x] Keep Mode Tidur enabled during the afternoon.
- [x] Expected: no `Mode tidur aktif` foreground notification appears outside the nightly window.
- [x] Expected: native `SleepScheduleReceiver` alarm is armed for the configured bedtime (`21:00` on this device).
- [ ] Wait until the configured bedtime.
- [ ] Expected: `Mode tidur aktif` notification appears with `Saya masih terjaga`.
- [ ] Complete or skip the next Morning Gate, or wait past the wake-window end.
- [ ] Expected: the sleep notification disappears and tomorrow's bedtime alarm is armed.

---

## Session 18 - 2026-05-31

Date: 2026-05-31
Device: Infinix X6873
Build: Debug - full rebuild required

### Water reminder - reboot cadence

- [x] Run a full `flutter run`, open Air once, and confirm reminders are active.
- [x] Reboot the phone.
- [x] Expected: the next water reminder keeps the configured cadence instead of falling back to a stale/default interval.

### Sleep mode - cross-device foreground service

- [x] Run a full `flutter run`; hot restart is not sufficient for this native manifest fix.
- [x] Open `Profile` -> `Mode Tidur`, enable Mode Tidur, and return from Android settings if prompted.
- [x] Expected: Rutin does not request body-sensor permission.
- [x] Tap `Test Sleep Gate`, then press Home.
- [x] Expected: the app returns to Morning Gate while the gate is active.
- [x] Source fix: Android 13+ dynamic receivers are registered as `RECEIVER_NOT_EXPORTED`.
- [x] Source fix: accessibility recovery no longer pushes a duplicate `/morning-gate` route.
- [x] Retest after unlock: enabling Mode Tidur does not force-close Rutin.
- [x] Retest after unlock: pressing Home or switching windows returns to one existing Morning Gate.

---

## Session 17 - 2026-05-31

Date: 2026-05-31
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Kebiasaan - multiple reminder times

- [ ] Open `Tambah Kebiasaan`, tap `+ Tambah` beside `RUTINITAS`, create a stack, and confirm it is selected immediately.
- [ ] Open the same `+ Tambah` dialog and press Android Back or `Batal`; expected: dialog closes without a red screen.
- [ ] Add a habit with two reminder times a few minutes apart.
- [ ] Expected: both times appear in the add/edit form, sorted chronologically.
- [ ] Expected: adding the same time twice does not create a duplicate.
- [ ] Wait for both scheduled times.
- [ ] Expected: both habit notifications fire independently.
- [ ] Edit the habit, remove one time, and add a different time.
- [ ] Expected: the removed time no longer fires and the new time does fire.
- [ ] Delete the habit.
- [ ] Expected: its remaining habit reminders stop firing.

### Kebiasaan - per-reminder completion

- [ ] Create a habit with two reminder times.
- [ ] Expected: Kebiasaan and Home show two completion dots instead of the single check circle.
- [ ] Tap the first dot.
- [ ] Expected: only the first dot fills and Home does not count the habit as fully complete.
- [ ] Tap the second dot.
- [ ] Expected: both dots fill and the habit becomes fully complete.
- [ ] Tap the second filled dot again.
- [ ] Expected: the second dot clears and progress returns to one filled dot.
- [ ] Open `Mode Tidur` -> `Test Sleep Gate`.
- [ ] Expected: Morning Gate shows the same progress dots read-only.

---

## Session 16 - 2026-05-31

Date: 2026-05-31
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### RECEIVE_BOOT_COMPLETED - partial reboot verification

- [x] Reboot test for medicine alarm restore completed by user.
- [x] Expected: scheduled medicine alarm still works after device reboot.
- [ ] Water reminder after reboot still pending verification.

---

## Session 15 - 2026-05-31

Date: 2026-05-31
Device: Realme GT 2 Pro (RMX3301), Android 14
Build: Debug

### Sleep Mode - Morning gate flow

- [x] Open `Profile` -> `Mode Tidur`.
- [x] Tap `Test Sleep Gate`.
- [x] Expected: `Morning Gate` appears first, not the game directly.
- [x] Expected: time, date, greeting, and streak pill are visible at the top.
- [x] Expected: read-only sections show today's medicine and habits when available.
- [x] Drag the slider to the right until it unlocks.
- [x] Expected: `/wakeup-game` opens after the slide threshold.
- [x] Complete or skip the game.
- [x] Expected: the game closes, then `Morning Gate` also closes back to the app.
- [x] Expected: tapping `Lewati` shows the confirm dialog and dismisses the gate after confirmation.
- [x] Expected: pressing Home during the active gate flow re-launches the app back into `Morning Gate`.

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
