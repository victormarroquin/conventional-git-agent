# Branching Strategies Reference

Detailed rules for each supported branching strategy. The agent reads this file
when it needs strategy-specific guidance beyond what SKILL.md covers.

All branch names in this document follow the **Conventional Branch 1.0.0**
specification (https://conventional-branch.github.io/). Valid branch types are:
`feature`/`feat`, `bugfix`/`fix`, `hotfix`, `release`, `chore`. Trunk branches
(`main`, `master`, `develop`) need no prefix.

---

## Table of Contents
1. [GitHub Flow](#github-flow)
2. [Git Flow](#git-flow)
3. [Trunk-Based Development](#trunk-based-development)
4. [Strategy Comparison](#strategy-comparison)

---

## GitHub Flow

The simplest strategy. Good for teams that deploy continuously.

### Branches

| Branch | Purpose | Lifetime |
|---|---|---|
| `main` | Always deployable production code | Permanent |
| `<type>/<description>` | All work happens here (types: feat, fix, bugfix, hotfix, chore, release) | Until merged |

### Rules

1. `main` is always deployable — never commit broken code to it
2. Create a descriptive branch off `main` for any change
3. Commit to your branch locally and push regularly
4. Open a PR when ready for review (or when you want feedback)
5. After review and CI passes, merge to `main`
6. Deploy immediately after merging

### Agent Behavior

```
Base branch for new work:     main
Branch from:                  main (always)
Merge back to:                main (via PR)
Delete branch after merge:    yes
```

**Creating a branch:**
```bash
git checkout main
git pull --rebase origin main
git checkout -b feat/add-search-bar
```

**After work is done:**
```bash
git push -u origin feat/add-search-bar
# Suggest PR description to user
```

---

## Git Flow

A more structured strategy with dedicated branches for development, releases,
and hotfixes. Good for teams with scheduled release cycles.

### Branches

| Branch | Purpose | Lifetime |
|---|---|---|
| `main` | Production releases only | Permanent |
| `develop` | Integration branch for features | Permanent |
| `feat/<desc>` or `feature/<desc>` | New features | Until merged to develop |
| `release/<version>` | Release preparation | Until merged to main + develop |
| `hotfix/<desc>` | Urgent production fixes | Until merged to main + develop |
| `bugfix/<desc>` or `fix/<desc>` | Non-urgent bug fixes | Until merged to develop |

### Rules

1. Features branch off `develop` and merge back to `develop`
2. When ready to release, branch `release/<version>` off `develop`
3. Release branches get only bug fixes, no new features
4. When release is ready, merge to both `main` AND `develop`
5. Tag `main` with the version number after release merge
6. Hotfixes branch off `main` and merge to both `main` AND `develop`

### Agent Behavior by Task Type

**Feature work:**
```
Base branch:     develop
Branch from:     develop
Merge back to:   develop (via PR)
Branch name:     feat/description
```

```bash
git checkout develop
git pull --rebase origin develop
git checkout -b feat/user-dashboard
# ... work and commit ...
git push -u origin feat/user-dashboard
```

**Bug fix (non-urgent):**
```
Base branch:     develop
Branch from:     develop
Merge back to:   develop (via PR)
Branch name:     fix/description or bugfix/description
```

**Hotfix (urgent production issue):**
```
Base branch:     main
Branch from:     main
Merge back to:   main AND develop (via PRs)
Branch name:     hotfix/description
```

```bash
git checkout main
git pull --rebase origin main
git checkout -b hotfix/fix-payment-crash
# ... fix and commit ...
git push -u origin hotfix/fix-payment-crash
# Remind user: this needs PRs to BOTH main and develop
```

**Release preparation:**
```
Base branch:     develop
Branch from:     develop
Merge back to:   main AND develop
Branch name:     release/v1.2.0
```

```bash
git checkout develop
git pull --rebase origin develop
git checkout -b release/v1.2.0
# Only bug fixes and version bumps from here
```

### Detecting Gitflow Context

When the user asks for a change, determine the type:
- "Fix this crash in production" → `hotfix` (from main)
- "Add a new feature" → `feat` (from develop)
- "Prepare the 2.0 release" → `release` (from develop)
- "Fix this bug" (not production-urgent) → `fix` (from develop)

If ambiguous, ask: "Is this an urgent production fix (hotfix) or a regular fix
that can go in the next release?"

---

## Trunk-Based Development

Developers integrate small, frequent changes directly to the trunk (main).
Feature flags gate incomplete work. Good for experienced teams with strong CI.

### Branches

| Branch | Purpose | Lifetime |
|---|---|---|
| `main` (trunk) | Single source of truth | Permanent |
| `<type>/<desc>` | Short-lived work branches | Hours to 2 days max |

### Rules

1. Branches live no longer than 2 days — prefer hours
2. Keep changes small and incremental
3. Use feature flags for incomplete features, not long-lived branches
4. Integrate to main at least once per day
5. main is always releasable

### Agent Behavior

```
Base branch:     main
Branch from:     main (always)
Merge back to:   main (via PR or direct merge)
Max branch age:  encourage merge within the session
```

```bash
git checkout main
git pull --rebase origin main
git checkout -b feat/add-tooltip
# Small, focused change
# ... work and commit ...
git push -u origin feat/add-tooltip
# Encourage immediate merge
```

**Key difference from GitHub Flow:** The agent should actively encourage the user
to merge quickly. If a change is getting large, suggest breaking it into smaller
PRs. Mention feature flags if the feature isn't complete:

> This feature isn't finished yet, but trunk-based development works best with
> small, frequent merges. Consider wrapping the incomplete parts behind a feature
> flag so we can merge what we have now and continue in a new branch.

---

## Strategy Comparison

| Aspect | GitHub Flow | Git Flow | Trunk-Based |
|---|---|---|---|
| Complexity | Simple | Complex | Simple |
| Best for | Continuous deploy | Scheduled releases | Experienced teams |
| Protected branches | main | main, develop | main |
| Feature branches from | main | develop | main |
| Typical branch lifespan | Days | Days to weeks | Hours to 2 days |
| Release process | Merge to main = deploy | release/* branch | Tag on main |
| Hotfix process | Branch from main | hotfix/* from main | Branch from main |

---

## Common Edge Cases

### User asks to work on an existing branch
Don't create a new branch. Instead:
```bash
git checkout existing-branch
git pull --rebase origin existing-branch
# Continue working
```

### User wants to change strategy mid-project
Acknowledge the request, explain any implications, and adapt. The config file
can be updated to reflect the new strategy.

### Repo has no remote
Skip all fetch/pull/push steps. Work locally but still follow the branching
and commit conventions. Note to the user that no remote is configured.

### Monorepo with multiple projects
Use scoped branch names: `feat/frontend/add-search` or `fix/api/null-check`.
Use scoped commits: `feat(frontend): add search bar`.

### User insists on committing to main
Explain the risks once, clearly:
> Committing directly to main means changes can't be reviewed before they're
> in production, and they're harder to revert cleanly. I recommend a short-lived
> branch — it only takes a few seconds to create.

If they insist after the explanation, comply but note it:
```bash
# User explicitly requested direct commit to main
git add .
git commit -m "feat: add search bar (direct to main per user request)"
```
