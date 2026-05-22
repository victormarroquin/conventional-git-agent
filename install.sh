#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# conventional-git-agent installer
# Installs the git workflow skill for your AI coding agent(s).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/victormarroquin/conventional-git-agent/main/install.sh | bash
#
#   Or clone the repo and run:
#   ./install.sh [options]
#
# Options:
#   --ai <agent>    Install for a specific agent (claude, cursor, windsurf,
#                   copilot, codex, gemini, opencode, kiro, trae, qoder,
#                   rovodev, pi, all)
#   --global        Install globally (~/) instead of project-local (./)
#   --uninstall     Remove the skill
#   --help          Show this help message
# ─────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Config ───────────────────────────────────────────────────────
SKILL_NAME="conventional-git-agent"
REPO_URL="https://github.com/victormarroquin/conventional-git-agent"
RAW_BASE="https://raw.githubusercontent.com/victormarroquin/conventional-git-agent/main"
SKILL_FILES=(
  "skills/conventional-git-agent/SKILL.md"
  "skills/conventional-git-agent/references/strategies.md"
)

# ── Agent path definitions ───────────────────────────────────────
# Each agent has its own skill directory convention.
# Format: AGENT_NAME|LOCAL_SKILL_DIR|GLOBAL_SKILL_DIR
AGENTS=(
  "claude|.claude/skills|~/.claude/skills"
  "cursor|.cursor/skills|~/.cursor/skills"
  "windsurf|.windsurf/skills|~/.windsurf/skills"
  "copilot|.github/skills|~/.github/skills"
  "codex|.agents/skills|~/.agents/skills"
  "gemini|.gemini/skills|~/.gemini/skills"
  "opencode|.opencode/skills|~/.opencode/skills"
  "kiro|.kiro/skills|~/.kiro/skills"
  "trae|.trae/skills|~/.trae/skills"
  "rovodev|.rovodev/skills|~/.rovodev/skills"
  "pi|.pi/skills|~/.pi/skills"
  "qoder|.qoder/skills|~/.qoder/skills"
)

# ── Globals ──────────────────────────────────────────────────────
TARGET_AI=""
GLOBAL_INSTALL=false
UNINSTALL=false
INSTALLED_COUNT=0
SOURCE_DIR=""

# ── Helpers ──────────────────────────────────────────────────────
info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "${RED}✗${NC}  $1"; }

banner() {
  echo ""
  echo -e "${CYAN}${BOLD}  🌿 conventional-git-agent installer${NC}"
  echo -e "  ${CYAN}Conventional Branch + Conventional Commits for AI agents${NC}"
  echo ""
}

usage() {
  echo "Usage: ./install.sh [options]"
  echo ""
  echo "Options:"
  echo "  --ai <agent>    Install for a specific agent:"
  echo "                  claude, cursor, windsurf, copilot, codex,"
  echo "                  gemini, opencode, kiro, trae, qoder,"
  echo "                  rovodev, pi, all"
  echo "  --global        Install globally (~/) instead of project-local"
  echo "  --uninstall     Remove the skill from detected agents"
  echo "  --help          Show this help"
  echo ""
  echo "Examples:"
  echo "  ./install.sh --ai claude          # Install for Claude Code"
  echo "  ./install.sh --ai cursor --global # Install globally for Cursor"
  echo "  ./install.sh --ai all             # Install for all agents"
  echo "  ./install.sh                      # Auto-detect and install"
  echo ""
  echo "One-liner install:"
  echo "  curl -fsSL ${RAW_BASE}/install.sh | bash"
  echo "  curl -fsSL ${RAW_BASE}/install.sh | bash -s -- --ai claude"
}

# ── Parse arguments ──────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ai)
        TARGET_AI="${2:-}"
        if [[ -z "$TARGET_AI" ]]; then
          error "Missing agent name after --ai"
          usage
          exit 1
        fi
        shift 2
        ;;
      --global)
        GLOBAL_INSTALL=true
        shift
        ;;
      --uninstall)
        UNINSTALL=true
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

# ── Resolve source directory ─────────────────────────────────────
# If running from a cloned repo, use local files.
# If running via curl pipe, download from GitHub.
resolve_source() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

  if [[ -f "${script_dir}/skills/conventional-git-agent/SKILL.md" ]]; then
    SOURCE_DIR="$script_dir"
    info "Using local files from ${SOURCE_DIR}"
  else
    SOURCE_DIR=$(mktemp -d)
    info "Downloading skill files from GitHub..."
    mkdir -p "${SOURCE_DIR}/skills/conventional-git-agent/references"

    for file in "${SKILL_FILES[@]}"; do
      curl -fsSL "${RAW_BASE}/${file}" -o "${SOURCE_DIR}/${file}" 2>/dev/null || {
        error "Failed to download ${file}"
        error "Check that the repo URL is correct: ${REPO_URL}"
        rm -rf "$SOURCE_DIR"
        exit 1
      }
    done
    success "Downloaded skill files"
  fi
}

# ── Get agent path ───────────────────────────────────────────────
get_agent_path() {
  local agent_name="$1"
  local use_global="$2"

  for entry in "${AGENTS[@]}"; do
    IFS='|' read -r name local_path global_path <<< "$entry"
    if [[ "$name" == "$agent_name" ]]; then
      if [[ "$use_global" == "true" ]]; then
        echo "${global_path/#\~/$HOME}"
      else
        echo "$local_path"
      fi
      return
    fi
  done
  echo ""
}

# ── Install for one agent ────────────────────────────────────────
install_for_agent() {
  local agent_name="$1"
  local base_path
  base_path=$(get_agent_path "$agent_name" "$GLOBAL_INSTALL")

  if [[ -z "$base_path" ]]; then
    warn "Unknown agent: ${agent_name}"
    return
  fi

  local skill_dir="${base_path}/${SKILL_NAME}"

  # Create directories
  mkdir -p "${skill_dir}/references"

  # Copy files
  cp "${SOURCE_DIR}/skills/conventional-git-agent/SKILL.md" \
     "${skill_dir}/SKILL.md"
  cp "${SOURCE_DIR}/skills/conventional-git-agent/references/strategies.md" \
     "${skill_dir}/references/strategies.md"

  success "Installed for ${BOLD}${agent_name}${NC} → ${skill_dir}"
  INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
}

# ── Uninstall for one agent ──────────────────────────────────────
uninstall_for_agent() {
  local agent_name="$1"

  # Check both local and global
  for use_global in "false" "true"; do
    local base_path
    base_path=$(get_agent_path "$agent_name" "$use_global")
    local skill_dir="${base_path}/${SKILL_NAME}"

    if [[ -d "$skill_dir" ]]; then
      rm -rf "$skill_dir"
      local location="local"
      [[ "$use_global" == "true" ]] && location="global"
      success "Removed ${BOLD}${agent_name}${NC} (${location}) → ${skill_dir}"
      INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
  done
}

# ── Auto-detect agents ───────────────────────────────────────────
detect_agents() {
  local detected=()

  for entry in "${AGENTS[@]}"; do
    IFS='|' read -r name local_path global_path <<< "$entry"
    local local_expanded="$local_path"
    local global_expanded="${global_path/#\~/$HOME}"

    # Check if the agent's config directory exists (either local or global)
    local agent_dir
    agent_dir=$(dirname "$local_expanded")
    local global_agent_dir
    global_agent_dir=$(dirname "$global_expanded")

    if [[ -d "$agent_dir" ]] || [[ -d "$global_agent_dir" ]]; then
      detected+=("$name")
    fi
  done

  echo "${detected[@]}"
}

# ── Main ─────────────────────────────────────────────────────────
main() {
  banner
  parse_args "$@"

  # ── Uninstall mode ──
  if [[ "$UNINSTALL" == "true" ]]; then
    info "Uninstalling ${SKILL_NAME}..."

    if [[ -n "$TARGET_AI" && "$TARGET_AI" != "all" ]]; then
      uninstall_for_agent "$TARGET_AI"
    else
      for entry in "${AGENTS[@]}"; do
        IFS='|' read -r name _ _ <<< "$entry"
        uninstall_for_agent "$name"
      done
    fi

    if [[ $INSTALLED_COUNT -eq 0 ]]; then
      warn "No installations found to remove."
    else
      echo ""
      success "${BOLD}Removed from ${INSTALLED_COUNT} location(s).${NC}"
    fi
    exit 0
  fi

  # ── Install mode ──
  resolve_source

  if [[ "$TARGET_AI" == "all" ]]; then
    info "Installing for all supported agents..."
    for entry in "${AGENTS[@]}"; do
      IFS='|' read -r name _ _ <<< "$entry"
      install_for_agent "$name"
    done

  elif [[ -n "$TARGET_AI" ]]; then
    install_for_agent "$TARGET_AI"

  else
    # Auto-detect
    info "Auto-detecting AI agents..."
    local detected
    detected=$(detect_agents)

    if [[ -z "$detected" ]]; then
      warn "No AI agent directories detected in this project."
      echo ""
      echo "  You can specify one manually:"
      echo "    ${BOLD}./install.sh --ai claude${NC}"
      echo "    ${BOLD}./install.sh --ai cursor${NC}"
      echo "    ${BOLD}./install.sh --ai all${NC}"
      echo ""
      echo "  Or install globally:"
      echo "    ${BOLD}./install.sh --ai claude --global${NC}"
      echo ""

      # Offer to install for claude as default
      read -rp "  Install for Claude Code? [Y/n] " answer
      answer="${answer:-Y}"
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        install_for_agent "claude"
      else
        info "No changes made."
        exit 0
      fi
    else
      info "Detected agents: ${BOLD}${detected}${NC}"
      for agent in $detected; do
        install_for_agent "$agent"
      done
    fi
  fi

  # ── Summary ──
  echo ""
  if [[ $INSTALLED_COUNT -gt 0 ]]; then
    success "${BOLD}Installed for ${INSTALLED_COUNT} agent(s).${NC}"
    echo ""
    echo -e "  ${CYAN}What's next:${NC}"
    echo "  1. Open your AI agent and start coding in a Git repo"
    echo "  2. The skill activates automatically when you request code changes"
    echo "  3. Optional: add a ${BOLD}.git-workflow.json${NC} to your repo root"
    echo "     to pre-configure the branching strategy."
    echo ""
    echo -e "  ${CYAN}Example .git-workflow.json:${NC}"
    echo '  {'
    echo '    "strategy": "github-flow",'
    echo '    "baseBranch": "main",'
    echo '    "commitConvention": "conventional"'
    echo '  }'
    echo ""
    echo -e "  📖 Docs: ${BLUE}${REPO_URL}${NC}"
  else
    warn "No agents were installed."
  fi
}

main "$@"
