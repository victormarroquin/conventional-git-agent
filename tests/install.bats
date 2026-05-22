#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)

  mkdir -p "${TEST_DIR}/skills/conventional-git-agent/references"
  echo "# SKILL"      > "${TEST_DIR}/skills/conventional-git-agent/SKILL.md"
  echo "# Strategies" > "${TEST_DIR}/skills/conventional-git-agent/references/strategies.md"

  cp "${BATS_TEST_DIRNAME}/../install.sh" "${TEST_DIR}/install.sh"
  chmod +x "${TEST_DIR}/install.sh"

  # Redirect HOME so global installs never touch the real home dir
  export HOME="${TEST_DIR}/home"
  mkdir -p "$HOME"

  ORIG_DIR="$PWD"
  cd "${TEST_DIR}"
}

teardown() {
  cd "$ORIG_DIR"
  rm -rf "${TEST_DIR}"
}

# ── Argument parsing ──────────────────────────────────────────────

@test "--help exits 0" {
  run bash install.sh --help
  [ "$status" -eq 0 ]
}

@test "--help prints usage" {
  run bash install.sh --help
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown flag exits 1" {
  run bash install.sh --bogus-flag
  [ "$status" -eq 1 ]
}

@test "--ai without a value exits 1" {
  run bash install.sh --ai
  [ "$status" -eq 1 ]
}

# ── Local install ─────────────────────────────────────────────────

@test "--ai claude installs SKILL.md locally" {
  run bash install.sh --ai claude
  [ "$status" -eq 0 ]
  [ -f ".claude/skills/conventional-git-agent/SKILL.md" ]
}

@test "--ai claude installs references/strategies.md locally" {
  run bash install.sh --ai claude
  [ -f ".claude/skills/conventional-git-agent/references/strategies.md" ]
}

@test "--ai cursor installs to .cursor/skills" {
  run bash install.sh --ai cursor
  [ "$status" -eq 0 ]
  [ -f ".cursor/skills/conventional-git-agent/SKILL.md" ]
}

@test "--ai windsurf installs to .windsurf/skills" {
  run bash install.sh --ai windsurf
  [ "$status" -eq 0 ]
  [ -f ".windsurf/skills/conventional-git-agent/SKILL.md" ]
}

@test "--ai copilot installs to .github/skills" {
  run bash install.sh --ai copilot
  [ "$status" -eq 0 ]
  [ -f ".github/skills/conventional-git-agent/SKILL.md" ]
}

# ── Global install ────────────────────────────────────────────────

@test "--ai claude --global installs SKILL.md to HOME" {
  run bash install.sh --ai claude --global
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.claude/skills/conventional-git-agent/SKILL.md" ]
}

@test "--ai claude --global installs references/strategies.md to HOME" {
  run bash install.sh --ai claude --global
  [ -f "${HOME}/.claude/skills/conventional-git-agent/references/strategies.md" ]
}

# ── Install all ───────────────────────────────────────────────────

@test "--ai all installs for claude and cursor" {
  run bash install.sh --ai all
  [ "$status" -eq 0 ]
  [ -f ".claude/skills/conventional-git-agent/SKILL.md" ]
  [ -f ".cursor/skills/conventional-git-agent/SKILL.md" ]
}

@test "--ai all exits 0" {
  run bash install.sh --ai all
  [ "$status" -eq 0 ]
}

# ── Unknown agent ─────────────────────────────────────────────────

@test "unknown agent name warns and exits 0" {
  run bash install.sh --ai not-a-real-agent
  [ "$status" -eq 0 ]
  [[ "$output" == *"Unknown agent"* ]]
}

# ── Uninstall ─────────────────────────────────────────────────────

@test "--uninstall removes previously installed skill" {
  bash install.sh --ai claude
  run bash install.sh --uninstall --ai claude
  [ "$status" -eq 0 ]
  [ ! -d ".claude/skills/conventional-git-agent" ]
}

@test "--uninstall exits 0 when skill is not installed" {
  run bash install.sh --uninstall --ai claude
  [ "$status" -eq 0 ]
}

@test "--uninstall prints warning when nothing to remove" {
  run bash install.sh --uninstall --ai claude
  [[ "$output" == *"No installations found"* ]]
}

@test "--uninstall --ai all removes multiple agents" {
  bash install.sh --ai all
  run bash install.sh --uninstall --ai all
  [ "$status" -eq 0 ]
  [ ! -d ".claude/skills/conventional-git-agent" ]
  [ ! -d ".cursor/skills/conventional-git-agent" ]
}
