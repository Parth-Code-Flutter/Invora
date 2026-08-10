# Repository Working Agreement

This repository is developed from multiple computers and may be continued by
different Codex sessions.

For every material implementation or behavior change:

1. Update `docs/PROJECT_HANDOFF.md` in the same commit.
2. Add a dated entry under **Implementation log** describing the user-visible
   change, important files, migrations or storage changes, and verification.
3. Update **Current implementation** when a feature or architectural fact
   changes.
4. Update **Known issues / next work** when an item is fixed, discovered, or
   reprioritized.
5. Never include machine-specific generated files, credentials, signing keys,
   Flutter SDK paths, Pods, build output, or IDE state in the handoff document.

`docs/CODEX_IMPLEMENTATION_PLAN.md` is the product scope and design reference.
`docs/PROJECT_HANDOFF.md` is the source of truth for current implementation and
cross-system development status.

