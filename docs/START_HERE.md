# Creovo Billing — Start Here

Use this as the first instruction on every computer and in every new Codex
session.

Suggested prompt:

> Read `docs/START_HERE.md` completely and follow its document order and
> working agreement before reviewing or changing the project.

## Required reading order

### 1. `PROJECT_HANDOFF.md` — current source of truth

Read this first for the current implementation, latest history, schema and
architecture, known work, verification, and cross-system handoff. Do not repeat
completed work. If code and handoff disagree, inspect recent commits/code and
correct the handoff in the same change.

### 2. `OFFLINE_MARKET_EXPANSION_ROADMAP.md` — what to build next

Follow the approved order:

1. P0 — professional trust and lifecycle completeness;
2. P1 — optional inventory, barcode, and retail;
3. P2 — automation and wider segments;
4. P3 — specialist and scale workflows.

Follow each feature's dependencies, offline boundary, workflow, and definition
of done. Do not start barcode/POS quantity behavior before the immutable stock
ledger. Optional modules must not disturb the fast invoice workflow.

### 3. `CODEX_IMPLEMENTATION_PLAN.md` — product and UX foundation

Use it for the original product promise, architecture, UI direction, and
offline-first principles. If an old V1 exclusion conflicts with an approved
expansion-roadmap item, the expansion roadmap wins.

### 4. Feature-specific documents when applicable

- Purchase foundation: `PURCHASE_READINESS_ROADMAP.md`
- Public release: `PRODUCTION_ROADMAP.md`
- Play / App Store listing and upload: `STORE_DEPLOYMENT.md`
- Licensing/demo: `LICENSING_AND_DEMO.md`
- Account OTP / Firebase console / Firestore rules: `PROJECT_HANDOFF.md`
  section **Account identity (Firebase Phone + Firestore plans)**

These add detail but do not override current facts in `PROJECT_HANDOFF.md` or
the expansion priority order.

### 5. `QA_CHECKLIST.md` — verification and release handoff

Use it during implementation and before handoff. Automated tests do not replace
the documented Android/iOS physical-device checks.

## Conflict order

1. Latest explicit user instruction
2. `PROJECT_HANDOFF.md` for current implementation facts
3. `OFFLINE_MARKET_EXPANSION_ROADMAP.md` for future scope and priority
4. Applicable feature-specific roadmap
5. `CODEX_IMPLEMENTATION_PLAN.md` for original/general direction

Do not silently resolve a genuine product conflict. Ask before implementation
if it materially changes data, accounting behavior, offline guarantees, or the
user journey.

## Working order for every task

1. Pull the latest `parth-dev` branch.
2. Read this file and the documents above in order.
3. Review recent commits and `git status` before editing.
4. Preserve unrelated changes; never stage another user's/system's work.
5. Select the next approved feature or follow the explicit user request.
6. Design ledger, storage, and migration behavior before UI when financial data
   is affected.
7. Reuse shared Sales/Purchase components where appropriate.
8. Add localization, tests, backup/restore, migration, accessibility, responsive
   layout, and offline behavior required by the roadmap definition of done.
9. Update `PROJECT_HANDOFF.md` in the same commit:
   - update Current implementation when facts change;
   - add a dated Implementation log entry;
   - update Known issues / next work;
   - record important files, schema/storage changes, and verification.
10. Update the relevant roadmap/QA document when scope or status changes.
11. Run formatting, analysis, targeted tests, full tests, and applicable builds.
12. Review the final diff and stage only intended files.
13. Commit and push to `parth-dev` before changing computers.

## Offline-first rule

Records, calculations, search, reports, PDFs, print preparation, exports,
backup, and restore must work in airplane mode. External delivery or government
submission may need connectivity, but Creovo prepares data offline and clearly
distinguishes Prepared from Submitted, Delivered, Paid online, or Synchronized.
Never claim a connected outcome that the app cannot verify locally.

## Cross-system handoff checklist

Before leaving a computer:

- commit intended code and documentation together;
- record tests/build status in `PROJECT_HANDOFF.md`;
- confirm `git status` has no forgotten task files;
- push the latest commit to `origin/parth-dev`;
- never commit SDK paths, credentials, signing keys, Pods, build output,
  simulator state, or machine-specific IDE files.

On the next computer:

- pull `origin/parth-dev`;
- read this file, then `PROJECT_HANDOFF.md`;
- confirm the expected latest commit exists before continuing.
