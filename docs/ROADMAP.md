# Roadmap

## Phase 1 — MVP (Build First)

Priority order matters. Build medicine reminder first — it's the most critical.

### 1. Medicine Reminder
The most important feature. TB medication cannot be missed.

**Behavior:**
- User adds medicine: name, optional dosage, time(s) per day
- At scheduled time: full-screen alarm-style notification fires
- If not acknowledged within 10 min → re-notifies
- Keeps re-notifying on 10-min interval until "Taken" is tapped
- "Snooze 15 min" option available
- Logs: taken / missed / snoozed per day
- Streak counter (consecutive days taken)

**Notification behavior:**
- Full-screen intent (shows even if phone is locked)
- Appears on Huawei watch
- Cannot be silently dismissed — must tap "Taken" or "Snooze"

### 2. Water Reminder
- Set daily goal (number of glasses, default 8)
- Set reminder interval (e.g., every 2 hours)
- Set active window (e.g., 7 AM – 10 PM — no reminders while sleeping)
- Tap to log a glass
- Progress indicator for the day
- Gentle notification (not alarm-grade, just a nudge)

### 3. General Habits
- Create habit: name, emoji/icon, schedule (daily or specific days)
- Optional reminder time
- Tap to complete for the day
- Streak counter
- Skip day without breaking streak (for doctor-approved rest days)
- Archive habit (pause without deleting — for when treatment ends)

### 4. Routine Stacking
Chain habits into a named sequence. One prompt at a time, not a wall of checkboxes.

**Behavior:**
- Create routine: "Morning Routine", "Evening Routine"
- Add habits in order — medicine always anchored first
- Completing one auto-prompts the next
- Routines are time-anchored ("after waking") not clock-strict
- Separate routine streak from individual habit streak
- Medicine → Water → Breakfast enforced naturally (medically correct)

### 5. Today View (Home Screen)
- All today's items: active routines, standalone habits, water progress
- Clear status at a glance: done / pending / missed
- Routine shown as a unit, not individual items

### 6. TB Treatment Mode
Pre-configured setup for TB patients. No manual habit building required.

**Behavior:**
- Onboarding asks: "Are you in TB treatment?"
- If yes: medicine reminder pre-configured, treatment countdown starts
- Treatment duration: 6 months (standard) or custom
- Days remaining shown on home screen: "142 days to go"
- Adherence score visible: "89% — great consistency"
- One-tap adherence report (PDF) — show to doctor or DOTS officer

### 7. Localization
- **Default language: Bahasa Indonesia**
- English available in settings
- Designed for low-end Android devices (common Huawei mid-range)
- Offline-first: every feature works with zero internet connection

---

## Phase 2 — Polish

- Weekly completion stats per habit
- Habit categories (health, productivity, etc.)
- Caregiver view — read-only share so family can see "did he take his medicine today"
- Huawei Health Kit integration
  - Read daily step count
  - Smart water nudge: "Only 1,500 steps today — stay hydrated"
- WhatsApp status share of daily adherence (how Indonesian families communicate)
- Notes on completion ("took with food", "felt nauseous") — medically useful log

---

## Phase 3 — ADA Portfolio Ready

- Onboarding flow (first-time setup: TB mode or custom, water goal, routines)
- App icon + splash screen
- Data backup/export (JSON)
- App store screenshots and description
- Second Brain integration — habit completions → markdown log in Obsidian

---

## What We're NOT Building

- Social features
- Cloud sync
- Premium/paid tier
- Gamification (points, rewards)
- Habit suggestions or AI coaching
- iOS version (Phase 1 Android only)

Keep it focused. One thing done well beats ten things done mediocrely.

---

## The Mission

Indonesia is #2 in TB cases worldwide — ~969,000 new cases per year. MDR-TB (drug-resistant TB) is rising, largely because patients miss doses. The drugs are free via BPJS. The problem is adherence.

This app exists because good medicine reminder tools cost money, and TB patients in Indonesia shouldn't have to pay for reliable healthcare tools. Open source, free forever, built by someone with TB.
