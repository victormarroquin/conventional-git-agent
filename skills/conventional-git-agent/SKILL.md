---
name: git-workflow-agent
description: >
  Enforces disciplined Git workflows for AI coding agents using industry standards:
  Conventional Branch (https://conventional-branch.github.io/) for branch naming and
  Conventional Commits (https://www.conventionalcommits.org/) for commit messages.
  Use this skill whenever you detect you're working inside a Git repository (look for
  .git/ directory) AND the user asks you to make code changes, fix bugs, add features,
  refactor, or any task that will modify files. Also trigger when the user mentions
  branches, commits, PRs, merges, git flow, github flow, trunk-based development, or
  any version control workflow. This skill ensures the agent never modifies code on
  main/develop directly, always creates proper branches, writes Conventional Commits,
  and keeps the repo in a clean state. Even if the user just says "fix this bug" or
  "add a login page", if you're in a git repo, follow this skill's workflow before
  touching any code.
---

# Git Workflow Agent

This skill turns an AI coding agent into a disciplined Git collaborator. It's built
on two complementary open standards:

- **Conventional Branch** (v1.0.0) — standardizes branch names (`feat/`, `fix/`, `hotfix/`, etc.)
- **Conventional Commits** (v1.0.0) — standardizes commit messages (`feat(scope): description`)

Instead of making changes directly on whatever branch happens to be checked out,
the agent follows a structured branching strategy, writes clean commits, and keeps
the repository in a healthy state throughout.

The goal: every change the agent makes should be easy for a developer to review,
merge, or revert — as if a thoughtful teammate had done the work.

## When This Skill Activates

Before making ANY code change in a Git repository, run through this checklist:

1. Confirm you're in a git repo (`git rev-parse --is-inside-work-tree`)
2. Identify the branching strategy (see Workflow Detection below)
3. Follow the Pre-Flight Checks
4. Create the appropriate branch
5. Make changes with proper commits
6. Offer to prepare a PR description

If you're NOT in a git repo, skip this skill entirely.

---

## Step 1: Workflow Detection

The first time you work in a repo during a conversation, determine which branching
strategy is in use. Check for clues in this order:

1. **Config file**: Look for a `.git-workflow.json` in the repo root (see Config Reference below)
2. **Branch structure**: Run `git branch -a` and look for patterns
3. **Ask the user** if you can't determine it automatically

**Detection heuristic:**

| Signal | Strategy |
|---|---|
| `develop` branch exists + `release/*` or `hotfix/*` branches | Git Flow |
| Only `main` (or `master`) + `feature/*` branches | GitHub Flow |
| Very short-lived branches, frequent merges to main | Trunk-Based |

If the repo is brand new or has no branching history, ask the user:

> I see this is a Git repo but I can't tell which branching strategy you prefer.
> A few quick questions to set things up right:
>
> 1. **Team size?** Solo / small team / large team
> 2. **Release cadence?** Continuous deployment / scheduled releases / both
> 3. **Do you use a `develop` branch?** Yes / No
>
> Based on your answers I'll configure the right workflow.

**Decision logic after the user answers:**
- Solo or small team + continuous deployment + no develop → **GitHub Flow**
- Any team size + scheduled releases + yes develop → **Git Flow**
- Any size + continuous deployment + short-lived branches → **Trunk-Based**

Once determined, tell the user which strategy you'll follow and proceed.

Read `references/strategies.md` for the detailed rules of each strategy.

---

## Step 2: Pre-Flight Checks

Before creating any branch or making any change, run these checks every time:

```bash
# 1. Are we in a git repo?
git rev-parse --is-inside-work-tree

# 2. What branch are we on?
git branch --show-current

# 3. Is the working tree clean?
git status --porcelain

# 4. Fetch latest from remote (if remote exists)
git remote -v && git fetch --all --prune 2>/dev/null

# 5. Is current branch up to date with its upstream?
git status -uno

# 6. Validate git author identity
git config user.name
git config user.email
```

**If the working tree is dirty** (uncommitted changes exist):
- Tell the user: "There are uncommitted changes on this branch. I'll stash them
  before switching so nothing gets lost."
- Run `git stash push -m "auto-stash before agent branch switch"`
- After completing your work on the new branch, remind the user about the stash

**If the branch is behind its upstream:**
- Run `git pull --rebase` on the base branch before creating a new branch
- If rebase has conflicts, stop and tell the user — don't try to resolve merge
  conflicts automatically

**If the git author identity is missing or invalid:**

Run `git config user.name` and `git config user.email` and validate both values
before proceeding. Stop and ask the user to fix the config if any check fails.

| Check | Command | Invalid if |
|---|---|---|
| Name is set | `git config user.name` | empty or exit code 1 |
| Name looks real | — | matches system username pattern (no spaces, all lowercase like `johnsmith`) |
| Email is set | `git config user.email` | empty or exit code 1 |
| Email format valid | — | missing `@`, no domain, no TLD |
| Email not auto-generated | — | ends in `.local`, matches `username@hostname` pattern |

**Detection examples:**

| Value | Valid | Reason |
|---|---|---|
| `Jane Smith` | ✅ | Real name with space |
| `jansmith` | ❌ | Looks like a system username, no spaces |
| `jane@example.com` | ✅ | Valid email |
| `jane@company.co.uk` | ✅ | Valid email with multi-part TLD |
| `jane@MacBook-Pro.local` | ❌ | Auto-generated hostname |
| `jansmith@Jansmith-MBP.local` | ❌ | Auto-generated hostname |
| `jane` | ❌ | No `@` — not an email |
| `` (empty) | ❌ | Not configured |

**If identity is invalid, stop and tell the user:**

> Your git author identity needs to be configured before I create any commits.
> Git is currently using an auto-generated value that will produce a warning on
> every commit and may be rejected by some remote hooks.
>
> Run these two commands to fix it:
> ```bash
> git config --global user.name "Your Full Name"
> git config --global user.email "you@example.com"
> ```
> Or, to set it only for this repo:
> ```bash
> git config user.name "Your Full Name"
> git config user.email "you@example.com"
> ```
> Let me know once it's set and I'll continue.

Do not proceed until the user confirms the identity is configured correctly.

---

## Step 3: Branch Creation — Conventional Branch 1.0.0

Branch names follow the [Conventional Branch](https://conventional-branch.github.io/)
specification, a formal standard that complements Conventional Commits. Where
Conventional Commits standardizes commit messages, Conventional Branch standardizes
branch names — making them human- and machine-readable.

### Branch Name Format

```
<type>/<description>
```

**Allowed types** (per Conventional Branch spec):

| Type | Alias | Purpose |
|---|---|---|
| `feature` | `feat` | New features and enhancements |
| `bugfix` | `fix` | Non-urgent bug fixes |
| `hotfix` | — | Urgent production fixes |
| `release` | — | Release preparation branches |
| `chore` | — | Dependencies, docs, tooling, non-code tasks |

Branches are temporary, so the type set is intentionally smaller than Conventional
Commits. Don't use `refactor/`, `test/`, `perf/`, `ci/`, `docs/`, or `style/`
as branch prefixes — use `chore/` for maintenance tasks and `feat/` for
improvements. Save the granular types for commit messages.

**Trunk branches** (no prefix needed): `main`, `master`, `develop`

### Naming Rules (Formal Grammar)

The spec defines an ABNF grammar. In practice, these are the rules to follow:

1. **Lowercase only** — `feat/add-login` not `feat/Add-Login`
2. **Hyphens to separate words** — `fix/header-bug` not `fix/header_bug`
3. **No consecutive hyphens or dots** — `feat/new-login` not `feat/new--login`
4. **No leading or trailing hyphens/dots** — `feat/add-login` not `feat/-add-login`
5. **No spaces or special characters** — only `a-z`, `0-9`, `-`, and `.`
6. **Dots only for version numbers** in release branches — `release/v1.2.0`
7. **Include ticket numbers when available** — `feat/issue-123-new-login`

### Validation

Before creating a branch, mentally validate against this grammar:

```
branch-name     = trunk-branch / prefixed-branch
trunk-branch    = "main" / "master" / "develop"
prefixed-branch = type "/" description
type            = "feature" / "feat" / "bugfix" / "fix"
                / "hotfix" / "release" / "chore"
description     = desc-segment *("-" desc-segment)
desc-segment    = 1*(ALPHA / DIGIT) *("." 1*(ALPHA / DIGIT))
```

**Quick validation examples:**

| Branch Name | Valid | Why |
|---|---|---|
| `feat/add-login-page` | ✅ | Correct format |
| `feature/issue-123-new-login` | ✅ | Long form with ticket |
| `hotfix/security-patch` | ✅ | Urgent fix |
| `release/v1.2.0` | ✅ | Dots for version |
| `chore/update-dependencies` | ✅ | Maintenance |
| `Feature/Add-Login` | ❌ | Uppercase |
| `feat/new--login` | ❌ | Consecutive hyphens |
| `refactor/extract-utils` | ❌ | Invalid type for branches |
| `fix/header_bug` | ❌ | Underscore not allowed |
| `fix/header bug` | ❌ | Spaces not allowed |

### Creating the Branch

```bash
# Switch to the correct base branch (depends on strategy)
git checkout main
git pull --rebase origin main

# Create and switch to the new branch
git checkout -b feat/add-user-authentication
```

Always confirm the branch was created:
```bash
git branch --show-current
```

The base branch depends on the strategy — see `references/strategies.md` for
which base to use (main vs develop) for each type in each strategy.

### Tooling Recommendation

If the user wants CI enforcement of branch names, recommend:
- **commit-check** — validates branch names locally
- **commit-check-action** — GitHub Actions integration for automatic validation

These tools enforce the Conventional Branch spec in the pipeline, catching
invalid branch names before they reach the remote.

---

## Step 4: Making Changes and Committing

Now you can make code changes. As you work, commit frequently and atomically.

### Conventional Commits Format

Every commit message follows this structure:

```
<type>(<optional-scope>): <description>

[optional body]

[optional footer(s)]
```

**Types** (same as branch prefixes):
`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

**Scope** is optional but recommended — it's the module or area affected:
`feat(auth):`, `fix(api):`, `refactor(db):`

**Rules for good commit messages:**
- Description in imperative mood: "add login endpoint" not "added login endpoint"
- First line under 72 characters
- Body explains *why*, not just *what* (the diff shows what)
- Reference issues in footers: `Refs: #123` or `Closes: #456`

**Breaking changes:**
- Add `!` after the type: `feat(api)!: change response format`
- Or add a `BREAKING CHANGE:` footer with explanation

**Example 1** — Simple feature:
```
feat(auth): add JWT token refresh endpoint

Tokens now auto-refresh 5 minutes before expiration.
The refresh endpoint returns a new access token without
requiring re-authentication.

Refs: #234
```

**Example 2** — Bug fix:
```
fix(parser): handle empty input arrays gracefully

Previously, passing an empty array caused a null reference
exception. Now returns an empty result set instead.

Closes: #189
```

**Example 3** — Breaking change:
```
feat(api)!: require authentication for all endpoints

All API endpoints now require a valid Bearer token.
Unauthenticated requests receive a 401 response.

BREAKING CHANGE: public endpoints no longer exist.
Clients must authenticate before making any request.
```

### Commit Discipline

- **One logical change per commit.** If you're adding a feature AND fixing a
  typo you noticed, those are two commits.
- **Don't commit broken code.** Each commit should leave the project in a
  working state when possible.
- **Commit after each meaningful step**, not everything at the end. This gives
  the developer a clear history of what you did.

---

## Step 5: Preparing the PR

After all changes are committed, check how many commits are on the branch:

```bash
git log main..HEAD --oneline
```

**If there is more than one commit**, pause and ask before generating the PR:

> Branch `feat/your-branch` has N commits. Anything else you'd like to add
> before I prepare the PR?

Wait for the user's answer. If they have more work, continue making changes and
committing. If they say no (or there is only one commit), proceed immediately to
generate the PR description — do not ask again.

**PR Description Template:**

```markdown
## Summary
[One-paragraph description of what this PR does and why]

## Changes
- [List of key changes, derived from commit messages]

## Type of Change
- [ ] feat: New feature
- [ ] fix: Bug fix
- [ ] refactor: Code restructuring
- [ ] docs: Documentation
- [ ] test: Tests
- [ ] chore: Maintenance

## Testing
[How these changes were tested or can be verified]

## Related Issues
[Links to related issues/tickets]
```

Generate this from the actual commits on the branch:
```bash
# Get commits unique to this branch
git log main..HEAD --oneline
```

Then tell the user:
> Your branch `feat/add-user-authentication` is ready with N commits.
> Here's a suggested PR description: [show it]
> 
> To push and create the PR:
> ```
> git push -u origin feat/add-user-authentication
> ```

After the PR is created, generate a short review request message the user can
copy and paste into Slack, Linear, Jira, or wherever their team communicates.
Do not offer to merge — in most workflows the PR goes through a review and
approval process before merging.

**Review request message format:**

```
Hey team! 👋 PR ready for review:
[one-line summary of what the PR does]
[PR URL]
~[estimated review time: small = <5 min, medium = 5–15 min, large = 15+ min]
```

Estimate review time based on the number of files and commits:
- **Small** — 1–2 files, 1–2 commits
- **Medium** — 3–10 files, 3–5 commits
- **Large** — 10+ files or 6+ commits

**Example output to show the user:**

> Here's a message you can send to request a review:
>
> ```
> Hey team! 👋 PR ready for review:
> Add JWT token refresh endpoint so sessions auto-renew before expiration
> https://github.com/org/repo/pull/42
> ~5 min review
> ```
>
> Adjust the URL and summary if needed, then paste it into Slack, Linear, Jira, or wherever your team reviews PRs.

---

## Config File Reference

Users can place a `.git-workflow.json` in their repo root to pre-configure the
agent's behavior. This avoids the initial questions on every new conversation.

```json
{
  "strategy": "github-flow",
  "baseBranch": "main",
  "developBranch": "develop",
  "branchPrefix": true,
  "commitConvention": "conventional",
  "autoStash": true,
  "autoPullRebase": true,
  "prTemplate": true,
  "protectedBranches": ["main", "develop"],
  "customTypes": ["feature", "feat", "bugfix", "fix", "hotfix", "release", "chore"]
}
```

| Field | Description | Default |
|---|---|---|
| `strategy` | `"git-flow"`, `"github-flow"`, or `"trunk-based"` | auto-detect |
| `baseBranch` | Primary branch name | `"main"` |
| `developBranch` | Integration branch (Git Flow only) | `"develop"` |
| `branchPrefix` | Use type-prefixed branch names | `true` |
| `commitConvention` | `"conventional"` or `"freeform"` | `"conventional"` |
| `autoStash` | Auto-stash dirty working tree | `true` |
| `autoPullRebase` | Auto pull --rebase before branching | `true` |
| `prTemplate` | Generate PR descriptions | `true` |
| `protectedBranches` | Branches to never commit directly on | `["main"]` |
| `customTypes` | Allowed commit/branch types | standard set |

If the config file exists, use it. If it doesn't, detect the strategy and offer
to create one:

> I've detected you're using GitHub Flow. Want me to create a `.git-workflow.json`
> so I remember this for next time?

---

## Critical Safety Rules

These are non-negotiable, regardless of what the user asks:

1. **Never commit directly to protected branches.** If the user says "just commit
   to main", explain why a branch is better and create one. Only proceed on main
   if the user explicitly insists after your explanation.

2. **Never force-push** unless the user explicitly requests it and confirms they
   understand the implications.

3. **Never auto-resolve merge conflicts.** Show the conflicts to the user and
   let them decide.

4. **Always preserve the user's work.** Stash before switching branches,
   don't discard changes.

5. **Never rewrite published history** (rebase commits already pushed) without
   explicit user consent.

---

## Quick Reference: The Agent's Git Checklist

For every code-change task, follow this sequence:

```
□ Detect git repo
□ Identify branching strategy (or ask)
□ Run pre-flight checks (clean tree, fetch, up-to-date)
□ Validate git author identity (name and email) — stop if invalid
□ Stash dirty changes if needed
□ Pull/rebase base branch
□ Create properly-named branch from correct base
□ Make changes with atomic Conventional Commits
□ If more than one commit: ask if there's anything else before the PR
□ Offer PR description
□ Generate review request message (Slack/Linear/Jira-ready, copy-paste)
□ Remind about stashed changes if any
```

For detailed strategy-specific rules (which base branch to use, how releases
work, hotfix procedures), read `references/strategies.md`.
