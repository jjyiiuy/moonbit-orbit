# Competition Checklist

This file is kept in the repository so the submission state can be reviewed without guessing.

## Repository

- Project id: `moonbit-orbit`
- MoonBit module: `jjyiiuy/moonbit-orbit`
- License: Apache-2.0
- Default branch target: `main`
- Source scale at local check: 5,643 MoonBit source lines
- Contributor policy: one real repository owner account only; no fictional contributor identity is listed

## Required Quality Gates

- `moon fmt --check`
- `moon check --deny-warn`
- `moon test --deny-warn`
- `moon info`
- `git diff --exit-code` after `moon info`
- `moon run cmd/main`
- `moon check --target all --deny-warn`

## Submission Notes

- README explains project goal, scope, usage, layout, limitations, and roadmap.
- `SOURCES.md` explains implementation origin and standard formulas used.
- CI is present under `.github/workflows/ci.yml`.
- Generated `.mbti` files are committed.
- SGP4 is marked as a reserved extension rather than overstated as complete.
- Mooncakes publication is planned after the API names settle.
