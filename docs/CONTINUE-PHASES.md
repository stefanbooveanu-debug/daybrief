# Continue DayBrief — Phases 1–4

Use this after **Phase 0** is done, committed, and pushed.

## Before you paste the prompt

1. `git pull` (if continuing on another machine)
2. Confirm Phase 0 landed: `git log --oneline -5` — look for `14e8914 fix: complete Phase 0`
3. Run `flutter pub get` then `flutter analyze` — must show **0 errors**
4. Read `.cursor/rules/phase-execution.mdc` — those rules govern how phases are run

## Copy-paste prompt (Session 2)

```
Continue DayBrief remediation.

Read docs/REMEDIATION-PLAN.md, docs/DECISIONS.md, docs/CODE-REVIEW.md, and .cursor/rules/phase-execution.mdc before writing any code.

Phase 0 is complete (commit 14e8914). Verify with git log and flutter analyze first.

Execute Phases 1, 2, 3, and 4 strictly in order, one subsection at a time:
- Before each subsection: state which subsection you are starting.
- After each subsection: run flutter analyze. Zero errors before continuing.
- If blocked: stop, explain what is blocking, wait for me.
- After each full phase: commit with message "refactor: Phase N — <description>".
- Never start a new phase until the previous one is committed and clean.

Do not skip subsections. Do not add anything not in REMEDIATION-PLAN.md. Push only when I ask.
```

## Rules file

`.cursor/rules/phase-execution.mdc` — always-on for this repo. Covers:
- Pre-flight checks (analyze + clean tree)
- One subsection at a time
- Commit discipline
- What is forbidden

## What each phase covers

| Phase | Focus | Est. |
|-------|--------|------|
| **1** | Delete dead code, port AddEventSheet features, unify theme, consolidate voice | ~0.5 day |
| **2** | freezed models, repository layer, AsyncValue, go_router | ~2–3 days |
| **3** | Wire orphans, complete stub screens + Firestore backends, service hardening, i18n | ~2–3 days |
| **4** | Accessibility, tests (mocktail), logger, docs refresh | ~1–2 days |

Full checklists and exact file paths: `docs/REMEDIATION-PLAN.md`.
