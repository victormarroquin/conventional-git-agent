# 🌿 conventional-git-agent

> Teach your AI coding agent to follow Git best practices — automatically.

A skill that enforces disciplined Git workflows for AI coding agents (Claude Code, Cursor, Windsurf, Copilot, and others). Built on two open standards:

- [**Conventional Branch**](https://conventional-branch.github.io/) — for branch naming
- [**Conventional Commits**](https://www.conventionalcommits.org/) — for commit messages

When an AI agent detects it's in a Git repo and the user asks for code changes, this skill makes the agent behave like a thoughtful teammate: it creates proper branches, writes clean commits, keeps the repo in a healthy state, and prepares PR descriptions — so developers can review, merge, or revert with confidence.

---

## The Problem

AI coding agents are powerful, but they tend to:

- Make changes directly on `main` or whatever branch is checked out
- Write vague commit messages like `"update files"` or `"fix stuff"`
- Skip pulling the latest changes before starting work
- Leave the repo in a messy state with uncommitted changes across branches

This skill fixes all of that.

---

## What It Does

When the agent starts any code-change task, this skill kicks in and follows a 5-step workflow:

### 1. 🔍 Detect the Branching Strategy

The agent checks for a `.git-workflow.json` config file, analyzes existing branches, or asks the developer a few quick questions to determine the right strategy:

| Strategy | Best For |
|---|---|
| **GitHub Flow** | Continuous deployment, small teams |
| **Git Flow** | Scheduled releases, larger teams |
| **Trunk-Based** | Experienced teams, very fast iteration |

### 2. ✅ Pre-Flight Checks

Before touching any code:

- Verifies the working tree is clean (stashes dirty changes automatically)
- Fetches the latest from remote
- Pulls/rebases the base branch to avoid working on stale code
- Stops and alerts the developer if there are merge conflicts
- **Validates git author identity** — checks that `user.name` and `user.email`
  are set and look legitimate before creating any commit. Catches missing values,
  system-username-style names, and auto-generated emails (e.g. `user@MacBook-Pro.local`).
  If invalid, the agent stops and guides you to fix it with `git config --global`.

### 3. 🌿 Create Branches (Conventional Branch)

Branch names follow the [Conventional Branch 1.0.0](https://conventional-branch.github.io/) spec:

```
<type>/<description>
```

Valid types: `feature`/`feat`, `bugfix`/`fix`, `hotfix`, `release`, `chore`

```
feat/add-user-authentication    ✅
fix/issue-123-null-pointer      ✅
hotfix/security-patch           ✅
release/v2.1.0                  ✅
refactor/extract-utils          ❌ (not a valid branch type)
Feature/Add-Login               ❌ (uppercase not allowed)
```

### 4. 📝 Commit with Conventional Commits

Every commit follows the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/) spec:

```
feat(auth): add JWT token refresh endpoint

Tokens now auto-refresh 5 minutes before expiration.

Refs: #234
```

The agent commits atomically (one logical change per commit) and uses the imperative mood.

### 5. 📋 Prepare the PR

When the branch has more than one commit, the agent pauses first and asks:

> Branch `feat/add-search-bar` has 3 commits. Anything else you'd like to add
> before I prepare the PR?

This gives you the chance to add more changes, fix something you noticed, or
say no and get the PR description immediately. For single-commit branches the
agent skips the question and goes straight to the PR.

After all changes are committed, the agent generates a PR description from the actual commits, then produces a short **review request message** ready to paste into Slack, Linear, Jira, or wherever your team communicates:

```markdown
## Summary
Added JWT-based authentication with token refresh...

## Changes
- feat(auth): add JWT token refresh endpoint
- test(auth): add refresh token test coverage

## Related Issues
Refs: #234
```

Then, without prompting, the agent generates a review request message:

```
Hey team! 👋 PR ready for review:
Add JWT token refresh so sessions auto-renew before expiration
https://github.com/org/repo/pull/42
~5 min review
```

Just copy and paste it — no editing needed.

---

## Installation

### Quick Install (One-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/conventional-git-agent/main/install.sh | bash
```

This auto-detects which AI agents you have and installs for all of them.

### Install for a Specific Agent

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/conventional-git-agent/main/install.sh | bash -s -- --ai claude
```

Supported agents: `claude`, `cursor`, `windsurf`, `copilot`, `codex`, `gemini`, `opencode`, `kiro`, `trae`, `qoder`, `rovodev`, `pi`, `all`

### Install from Cloned Repo

```bash
git clone https://github.com/YOUR_USERNAME/conventional-git-agent.git
cd conventional-git-agent
./install.sh --ai claude        # Specific agent
./install.sh --ai all           # All agents
./install.sh                    # Auto-detect
```

> **Note:** `.claude/` (and equivalent agent dirs) are gitignored in this repo.
> `skills/` is the single source of truth. Run `install.sh` after cloning to
> activate the skill locally for your agent(s).

### Global Install (All Projects)

```bash
./install.sh --ai claude --global    # Available in every project
./install.sh --ai cursor --global
```

### Uninstall

```bash
./install.sh --uninstall             # Remove from all detected agents
./install.sh --uninstall --ai claude # Remove from specific agent
```

### Manual Installation (Copy & Paste)

If you prefer not to use the installer, copy the skill folder to the correct
path for your agent:

| Agent | Copy to |
|---|---|
| **Claude Code** | `.claude/skills/conventional-git-agent/` |
| **Cursor** | `.cursor/skills/conventional-git-agent/` |
| **Windsurf** | `.windsurf/skills/conventional-git-agent/` |
| **GitHub Copilot** | `.github/skills/conventional-git-agent/` |
| **Codex CLI** | `.agents/skills/conventional-git-agent/` |
| **Gemini CLI** | `.gemini/skills/conventional-git-agent/` |
| **OpenCode** | `.opencode/skills/conventional-git-agent/` |
| **Kiro** | `.kiro/skills/conventional-git-agent/` |
| **Trae** | `.trae/skills/conventional-git-agent/` |
| **Qoder** | `.qoder/skills/conventional-git-agent/` |
| **Rovo Dev** | `.rovodev/skills/conventional-git-agent/` |
| **Pi** | `.pi/skills/conventional-git-agent/` |

Example for Claude Code:
```bash
mkdir -p .claude/skills/conventional-git-agent/references
cp skills/conventional-git-agent/SKILL.md .claude/skills/conventional-git-agent/
cp skills/conventional-git-agent/references/strategies.md .claude/skills/conventional-git-agent/references/
```

For global (user-wide) install, use `~/.claude/skills/` instead of `.claude/skills/`.

### File Structure

```
conventional-git-agent/
├── README.md                          # This file
├── LICENSE
├── install.sh                         # Installer script
├── .git-workflow.example.json         # Example config for your repos
└── skills/
    └── conventional-git-agent/
        ├── SKILL.md                   # Main skill definition
        └── references/
            └── strategies.md          # Detailed branching strategy rules
```

---

## Configuration

Drop a `.git-workflow.json` in your repo root to pre-configure the agent's behavior. This way it doesn't need to ask questions every time:

```json
{
  "strategy": "github-flow",
  "baseBranch": "main",
  "branchPrefix": true,
  "commitConvention": "conventional",
  "autoStash": true,
  "autoPullRebase": true,
  "prTemplate": true,
  "protectedBranches": ["main"],
  "customTypes": ["feature", "feat", "bugfix", "fix", "hotfix", "release", "chore"]
}
```

| Field | Description | Default |
|---|---|---|
| `strategy` | `"github-flow"`, `"git-flow"`, or `"trunk-based"` | auto-detect |
| `baseBranch` | Primary branch name | `"main"` |
| `developBranch` | Integration branch (Git Flow only) | `"develop"` |
| `commitConvention` | `"conventional"` or `"freeform"` | `"conventional"` |
| `autoStash` | Stash dirty changes before switching branches | `true` |
| `autoPullRebase` | Pull with rebase before creating branches | `true` |
| `prTemplate` | Generate PR descriptions automatically | `true` |
| `protectedBranches` | Branches the agent will never commit to directly | `["main"]` |

---

## Safety Rules

The agent follows these non-negotiable rules:

- **Never commits directly to protected branches** — always creates a feature/fix branch first
- **Never force-pushes** without explicit developer confirmation
- **Never auto-resolves merge conflicts** — shows them to the developer
- **Always preserves work** — stashes before switching branches
- **Never rewrites published history** without explicit consent

---

## Standards

This skill is built on established, documented specifications:

| Standard | Version | What It Covers |
|---|---|---|
| [Conventional Branch](https://conventional-branch.github.io/) | 1.0.0 | Branch naming (`feat/`, `fix/`, `hotfix/`...) |
| [Conventional Commits](https://www.conventionalcommits.org/) | 1.0.0 | Commit messages (`feat(scope): description`) |

### Recommended CI Tooling

To enforce these conventions in your pipeline:

- [**commit-check**](https://github.com/commit-check/commit-check) — Validates branch names and commit messages locally
- [**commit-check-action**](https://github.com/commit-check/commit-check-action) — GitHub Actions integration

---

## Example Workflow

A developer says: *"Add a search bar to the dashboard"*

The agent:

```
1. Detects git repo                          ✓
2. Reads .git-workflow.json → GitHub Flow    ✓
3. Checks working tree is clean              ✓
4. Runs: git fetch --all --prune             ✓
5. Runs: git checkout main                   ✓
6. Runs: git pull --rebase origin main       ✓
7. Runs: git checkout -b feat/add-search-bar ✓
8. Makes changes...                          ✓
9. Commits: feat(dashboard): add search bar  ✓
10. Pushes and suggests PR description       ✓
```

The developer gets a clean branch, a clear commit history, and a ready-to-review PR.

---

## Testing

The project uses [bats-core](https://github.com/bats-core/bats-core) for testing `install.sh` and
validating the structure of `SKILL.md`. CI runs on every push and PR via GitHub Actions.

### Install dependencies

**bats-core**

| OS | Command |
|---|---|
| macOS | `brew install bats-core` |
| Ubuntu / Debian | `sudo apt-get install bats` |
| Other Linux | `git clone https://github.com/bats-core/bats-core.git && sudo ./bats-core/install.sh /usr/local` |
| Any (npm) | `npm install -g bats` |

**shellcheck** (optional, for linting `install.sh`)

| OS | Command |
|---|---|
| macOS | `brew install shellcheck` |
| Ubuntu / Debian | `sudo apt-get install shellcheck` |
| Other Linux | [Download from GitHub releases](https://github.com/koalaman/shellcheck/releases) |

### Run the tests

```bash
# All tests
bats tests/

# Only installer tests
bats tests/install.bats

# Only skill structure tests
bats tests/skill.bats

# Lint the installer
shellcheck install.sh
```

---

## Contributing

Contributions are welcome! If you want to improve the skill, add support for more strategies, or fix an issue:

1. Fork the repo
2. Create your branch: `feat/your-improvement`
3. Commit with Conventional Commits (of course 😄)
4. Open a PR

---

## License

[MIT](LICENSE)

---

<p align="center">
  Built with ❤️ for developers who want their AI agents to follow the rules.
</p>
