# Continue DayBrief — Phases 1–4

Use this after **Phase 0** is done, committed, and pushed.

## Before you paste the prompt

1. `git pull` (if continuing on another machine)
2. Confirm Phase 0 landed: auth fix, Claude proxy, month CRUD, `VoiceTemplateProvider`, Firebase rules, bundle IDs
3. Optional: `flutter pub get && flutter analyze`

## Copy-paste prompt (Session 2)

```
Continue DayBrief remediation.

Read docs/REMEDIATION-PLAN.md, docs/DECISIONS.md, and docs/CODE-REVIEW.md for full context.
Assume Phase 0 is complete — verify with git log and flutter analyze before starting.

Execute Phases 1, 2, 3, and 4 in order from docs/REMEDIATION-PLAN.md.
After each phase: run flutter analyze, fix issues, then commit with a message like "refactor: Phase N …".
Do not skip subsections unless blocked — if blocked, say what and stop.
Push when I ask.
```

## What each phase covers (reminder)

| Phase | Focus |
|-------|--------|
| **1** | Delete dead code, single theme, single voice parser |
| **2** | freezed models, repositories, AsyncValue, go_router |
| **3** | Wire orphan/stub screens, Firestore backends, i18n, service hardening |
| **4** | Accessibility, tests, logger, documentation refresh |

Full checklists: `docs/REMEDIATION-PLAN.md`.
