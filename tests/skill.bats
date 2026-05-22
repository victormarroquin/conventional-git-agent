#!/usr/bin/env bats

SKILL_FILE="${BATS_TEST_DIRNAME}/../skills/conventional-git-agent/SKILL.md"
STRATEGIES_FILE="${BATS_TEST_DIRNAME}/../skills/conventional-git-agent/references/strategies.md"

# ── File presence ─────────────────────────────────────────────────

@test "SKILL.md exists" {
  [ -f "$SKILL_FILE" ]
}

@test "references/strategies.md exists" {
  [ -f "$STRATEGIES_FILE" ]
}

# ── Required sections ─────────────────────────────────────────────

@test "SKILL.md has Step 1 (Workflow Detection)" {
  grep -q "## Step 1:" "$SKILL_FILE"
}

@test "SKILL.md has Step 2 (Pre-Flight Checks)" {
  grep -q "## Step 2:" "$SKILL_FILE"
}

@test "SKILL.md has Step 3 (Branch Creation)" {
  grep -q "## Step 3:" "$SKILL_FILE"
}

@test "SKILL.md has Step 4 (Making Changes and Committing)" {
  grep -q "## Step 4:" "$SKILL_FILE"
}

@test "SKILL.md has Step 5 (Preparing the PR)" {
  grep -q "## Step 5:" "$SKILL_FILE"
}

@test "SKILL.md has Critical Safety Rules section" {
  grep -q "## Critical Safety Rules" "$SKILL_FILE"
}

@test "SKILL.md has Quick Reference checklist" {
  grep -q "## Quick Reference" "$SKILL_FILE"
}

# ── Pre-flight check coverage ─────────────────────────────────────

@test "SKILL.md documents git author identity validation" {
  grep -q "user.name" "$SKILL_FILE"
  grep -q "user.email" "$SKILL_FILE"
}

@test "SKILL.md checklist includes identity validation step" {
  grep -q "git author identity" "$SKILL_FILE"
}

# ── Conventional Commits ──────────────────────────────────────────

@test "SKILL.md documents conventional commit types" {
  grep -q "feat" "$SKILL_FILE"
  grep -q "fix" "$SKILL_FILE"
  grep -q "chore" "$SKILL_FILE"
}

@test "SKILL.md documents breaking change syntax" {
  grep -q "BREAKING CHANGE" "$SKILL_FILE"
}

# ── Conventional Branch ───────────────────────────────────────────

@test "SKILL.md documents valid branch types" {
  grep -q "feature" "$SKILL_FILE"
  grep -q "hotfix" "$SKILL_FILE"
  grep -q "release" "$SKILL_FILE"
}

# ── Ticket integration ───────────────────────────────────────────

@test "SKILL.md documents ticketTracker config field" {
  grep -q "ticketTracker" "$SKILL_FILE"
}

@test "SKILL.md documents ticketPrefix config field" {
  grep -q "ticketPrefix" "$SKILL_FILE"
}

@test "SKILL.md documents Jira ticket branch format" {
  grep -q "proj-123" "$SKILL_FILE"
}

@test "SKILL.md documents Linear ticket branch format" {
  grep -q "eng-456" "$SKILL_FILE"
}

@test "SKILL.md documents automatic Refs footer for tickets" {
  grep -q "Refs: PROJ-123" "$SKILL_FILE"
}

# ── Frontmatter ───────────────────────────────────────────────────

@test "SKILL.md has frontmatter with name field" {
  grep -q "^name:" "$SKILL_FILE"
}

@test "SKILL.md has frontmatter with description field" {
  grep -q "^description:" "$SKILL_FILE"
}
