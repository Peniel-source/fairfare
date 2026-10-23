# Contributing to FairFare

## The workflow in short

1. Pull the latest `dev`.
2. Create a branch from `dev`.
3. Make your changes, commit often.
4. Push and open a pull request **into `dev`**.
5. Get a review, make sure CI passes, then squash and merge.

```bash
git checkout dev
git pull origin dev
git checkout -b type/id-and-name
# ...work...
git push -u origin type/id-and-name
```

Never commit directly to `dev` or `main`.

## Task IDs

Every task in the Team Task Plan has an ID such as A1 or C3. Put the lowercase ID at the start of your branch name and mention it in your PR title, so the Git history shows who did what and why. Example: branch `feature/c1-report-screen`, PR title "C1: Report screen".

## Branch naming

Use `type/task-id-short-description` in lowercase with hyphens.

| Prefix | Use for | Example |
|---|---|---|
| `feature/` | New functionality | `feature/c1-report-screen` |
| `fix/` | Bug fixes | `fix/b4-reset-email-error` |
| `chore/` | Setup, dependencies, config | `chore/a1-nestjs-migration` |
| `ci/` | Build and check workflows | `ci/c5-coverage-step` |
| `docs/` | Documentation only | `docs/e7-report-draft` |
| `test/` | Adding or fixing tests | `test/d6-wallet-widget-tests` |

## Pull requests

- **One PR per feature** where possible. 
- Target branch is `dev`. 
- Fill in the PR template completely.
- **Review ring:** A reviews B, B reviews C, C reviews D, D reviews E, E reviews A. We can be flexible here
- Resolve all review comments before merging.
- Use **squash and merge**. The author/reviwer merges the PR once it has the required approvals and green checks. The branch is deleted automatically.
- Don't approve your own PR.

### Reviewing

- Aim to review within 24 hours.
- Check that the code runs, you can even clone into that branch and do local tests.

## Code rules

- Follow `flutter_lints`. Run `dart format .` and `flutter analyze` before pushing. The target is zero issues.
- **Clean Architecture:** every feature has `data`, `domain`, and `presentation` folders. The domain layer imports no Flutter or Firebase packages. Screens never call Firestore directly. UI files contain no business logic.
- **State management:** use Riverpod. Do not use `setState` for app state.
- No hardcoded colors, font sizes, or corner radii in widgets. They belong in `lib/core/theme/` or a shared component in `lib/shared/widgets/`.
- Every new screen needs **loading, empty, and error states** and a landscape check before it counts as done.
- Match the Figma prototype. If your screen visibly differs, say so in the PR.
- Use only the names in the Firestore data model in the roadmap. If you need a new field or collection, update the roadmap and the ERD in the same PR, and tell the team.
- Never commit secrets (see the Secrets section).

## First time setup

You need Git, Flutter (stable channel), and Node.js **22.18 or newer** (check with `node -v`). Use the same npm major version that the CI workflow uses, because a different npm can write a lock file that `npm ci` rejects. Run `flutter doctor` to check your Flutter setup. Android emulator.

### Flutter app

```bash
cd app
flutter pub get
flutter run
```

### Backend (NestJS service)

```bash
cd backend
npm ci
```

Use `npm ci`, not `npm install`, so everyone has identical package versions. Open `backend/.env` and fill in the values. **Ask Person A for them privately**, never in a public channel or in the repo.

Check that everything builds with `npm run build && npm run lint && npm test`.

## Before opening a PR

Run the checks for the part you changed. CI runs the same ones and blocks the merge if they fail.

```bash
# Flutter app
cd app
dart format .
flutter analyze
flutter test

# Backend
cd backend
npm run build
npm run lint
npm test
```

## Releases

When `dev` is stable at the end of a phase or before a demo, we will open a PR from `dev` into `main`. It needs 2 approvals.
