# Rutin

**Build the day. Keep the routine.**

---

## Problem

Most people know what they should do every day — take their medicine, drink enough water, build a habit. The hard part isn't knowing. It's remembering. And when life gets busy, the routine breaks.

Existing reminder apps either feel clinical (just alarms) or overwhelming (too many features, too much setup). There's no app that feels like a quiet, consistent companion for your daily health routine.

---

## What Rutin Does

Rutin is a daily health companion that helps you build and maintain three core routines:

- **Medicine** — Set alarms for each medicine. Rutin notifies you at the exact time, shows a full-screen reminder even on a locked screen, and repeats if you miss it — until you confirm you've taken it.
- **Water** — Track your daily water intake with one tap. Simple progress, no judgment.
- **Habits** — Define the small things you want to do every day. Check them off. See your streak.

No social feed. No gamification gimmicks. Just your routine, every day.

---

## Who It's For

Anyone trying to stay consistent — whether that's managing a health condition, recovering from illness, or simply trying to build better daily habits.

Rutin was originally built for patients managing TB treatment, where missing a medicine dose has real consequences. That origin shapes the core value: **reliability over everything**. The alarm must fire. The reminder must be impossible to miss. The loop must stop only when the user says so.

---

## Why It's Different

| | Generic reminder apps | Rutin |
|---|---|---|
| Full-screen alarm on locked screen | Rarely | ✅ Always |
| Repeats until confirmed | ❌ | ✅ |
| Medicine + water + habits in one place | ❌ | ✅ |
| Works offline, no account needed | Sometimes | ✅ Always |
| Feels like a tool, not a product | ❌ | ✅ |

---

## The Builder

**Ilham Maulana Sulaeman** — Bina Nusantara University

Built Rutin because someone close to him needed it. Learned Flutter, Kotlin, Android alarm systems, and local storage to make it real. Every piece — the alarm that fires through a locked screen, the snooze that actually stops — was built from scratch, problem by problem.

Rutin is the kind of app I would have wanted to exist before I built it.

---

## Stack

- **Flutter 3.44** (Dart) — cross-platform UI
- **Kotlin** — native Android alarm receiver and full-screen activity
- **AlarmManager** — exact alarms that survive battery optimization
- **Hive** — offline-first local storage
- **Riverpod** — state management

---

## Status

Core alarm system is complete and tested on Android 14 (Realme GT 2 Pro).
Water tracker and habit check-off are in active development.

---

*Rutin — because consistency is the hardest part.*
