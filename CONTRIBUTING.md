# Contributing to FairFare

## The workflow in short

1. Pull the latest `dev`.
2. Create a branch from `dev`.
3. Make your changes, commit often.
4. Push and open a pull request **into `dev`**.
5. Get a review, make sure CI passes, then squash-merge.

```bash
git checkout dev
git pull origin dev
git checkout -b feature/report-screen
# ...work...
git push -u origin feature/report-screen
```

Never commit directly to `dev` or `main`.

## Branch naming

Use `type/short-description` in lowercase with hyphens.

| Prefix | Use for | Example |
|---|---|---|
| `feature/` | New functionality | `feature/report-screen` |
| `fix/` | Bug fixes | `fix/otp-autofill` |
| `docs/` | Documentation only | `docs/update-readme` |
| `test/` | Adding or fixing tests | `test/corridor-widget-tests` |

## Commit messages

Format: `type: short summary in present tense`

```
feat: add price stepper widget
fix: prevent OTP boxes losing focus on paste
docs: update branch workflow in README
test: add widget tests for corridor card
```

Keep the summary under about 70 characters. Commit small and often.

## Pull requests

- **One PR per feature folder or module** where possible. Small PRs get reviewed faster and break less.
- Target branch is `dev`. Only the `dev` → `main` release PR targets `main`.
- Fill in the PR template completely.
- Link the task or issue it relates to.
- Resolve all review comments before merging.
- Use **squash and merge**. The author deletes the branch after merging (or it is deleted automatically).
- Don't approve your own PR.

### Reviewing

- Aim to review within 24 hours.
- Check that the code runs, not just that it reads well.
- Be specific and kind. Ask questions rather than issuing orders.

## Code rules

- Follow `flutter_lints`. Run `flutter analyze` before pushing.
- No hardcoded colors, font sizes, or corner radii in widgets. They belong in `lib/core/theme/` or a shared component in `lib/shared/`.
- Reusable widgets go in `lib/shared/widgets/`. Build once, reuse.
- Every new screen needs **loading, empty, and error states** before it counts as done.
- Respect the folder structure: feature code lives in `lib/features/<feature>/`.
- Match the mockups. If your screen visibly differs, say so in the PR.
- Never commit secrets: API keys, Firebase config with credentials, `.env` files.

## Before opening a PR

```bash
cd app
flutter analyze
flutter test
```

Both must pass. CI runs the same checks and will block the merge if they fail.

## Releases

When `dev` is stable at the end of a sprint or before a demo, open a PR from `dev` into `main`. It needs 2 approvals.

## Need help?

Ask in the team chat before you're stuck for more than 30 minutes.