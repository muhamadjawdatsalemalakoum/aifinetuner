#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
#  AI Fine-Tuner — Production Readiness Test Suite
#  Run: ./tests/run-tests.sh
# ─────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"

PASS=0
FAIL=0
TOTAL=0

green() { printf "\033[32m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }
dim()   { printf "\033[2m%s\033[0m\n" "$1"; }

assert() {
  TOTAL=$((TOTAL + 1))
  local desc="$1"
  local result="$2"
  if [[ "$result" == "true" ]]; then
    PASS=$((PASS + 1))
    printf "  \033[32m✓\033[0m %s\n" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf "  \033[31m✗\033[0m %s\n" "$desc"
  fi
}

assert_file() { assert "$1 exists" "$([[ -f "$2" ]] && echo true || echo false)"; }
assert_executable() { assert "$1 is executable" "$([[ -x "$2" ]] && echo true || echo false)"; }
assert_contains() { assert "$1 contains '$2'" "$(grep -q -- "$2" "$3" 2>/dev/null && echo true || echo false)"; }
assert_not_contains() { assert "$1 does NOT contain '$2'" "$(grep -q -- "$2" "$3" 2>/dev/null && echo false || echo true)"; }
assert_char_limit() {
  local file="$1"
  local field="$2"
  local limit="$3"
  local value
  value="$(grep "^${field}:" "$file" | sed "s/^${field}: *//" | head -1)"
  local len=${#value}
  assert "$field in $(basename "$file") is under ${limit} chars (got ${len})" "$([[ $len -le $limit ]] && echo true || echo false)"
}

echo ""
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║   AI Fine-Tuner — Test Suite              ║"
echo "  ╚═══════════════════════════════════════════╝"
echo ""

# ─── 1. REQUIRED FILES EXIST ──────────────────────────
echo "  1. Required files"
assert_file "AGENTS.md" "$ROOT/AGENTS.md"
assert_file "SKILL.md" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_file "plugin.json" "$ROOT/.claude-plugin/plugin.json"
assert_file "marketplace.json" "$ROOT/.claude-plugin/marketplace.json"
assert_file "LICENSE" "$ROOT/LICENSE"
assert_file "README.md" "$ROOT/README.md"
assert_file "CLAUDE.md" "$ROOT/CLAUDE.md"
assert_file "single.html template" "$ROOT/assets/templates/single.html"
assert_file "small.html template" "$ROOT/assets/templates/small.html"
assert_file "full.html template" "$ROOT/assets/templates/full.html"
assert_file "install-utils.sh" "$ROOT/install-utils.sh"
assert_file "install-claude.sh" "$ROOT/install-claude.sh"
assert_file "install-codex.sh" "$ROOT/install-codex.sh"
assert_file "install-cursor.sh" "$ROOT/install-cursor.sh"
assert_file "install-windsurf.sh" "$ROOT/install-windsurf.sh"
assert_file "install-cline.sh" "$ROOT/install-cline.sh"
assert_file "install-aider.sh" "$ROOT/install-aider.sh"
assert_file "index.html (website)" "$ROOT/samples/index.html"
assert_file "single demo" "$ROOT/samples/single-button-glow.html"
assert_file "small demo" "$ROOT/samples/small-pricing-card.html"
assert_file "full demo" "$ROOT/samples/full-dashboard-card.html"
echo ""

# ─── 2. INSTALLER EXECUTABILITY ───────────────────────
echo "  2. Installer permissions"
for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh install-utils.sh; do
  assert_executable "$f" "$ROOT/$f"
done
echo ""

# ─── 3. INSTALLER SYNTAX CHECK (bash 3.2) ─────────────
echo "  3. Bash syntax check"
for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh install-utils.sh; do
  result="$(/bin/bash -n "$ROOT/$f" 2>&1 && echo true || echo false)"
  assert "$f syntax OK" "$result"
done
echo ""

# ─── 4. NO FORBIDDEN PATTERNS ─────────────────────────
echo "  4. No forbidden patterns in installers"
for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh; do
  assert_not_contains "$f" "set -e" "$ROOT/$f"
  assert_not_contains "$f" "set -u" "$ROOT/$f"
  assert_not_contains "$f" 'read -e' "$ROOT/$f"
  assert_not_contains "$f" 'BASH_SOURCE' "$ROOT/$f"
  assert_not_contains "$f" '^source ' "$ROOT/$f"
done
echo ""

# ─── 5. INSTALLERS SOURCE UTILS ───────────────────────
echo "  5. Installers source install-utils.sh"
for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh; do
  assert_contains "$f" 'install-utils.sh' "$ROOT/$f"
done
echo ""

# ─── 6. NO HOOKS (removed by design) ─────────────────
echo "  6. No hooks in installers (manual invocation only)"
for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh; do
  assert_not_contains "$f" "hook" "$ROOT/$f"
done
echo ""

# ─── 7. SKILL.MD DESCRIPTION LENGTH ──────────────────
echo "  7. SKILL.md description under 250 chars"
desc="$(sed -n '/^description:/,/^[a-z]/p' "$ROOT/skills/ai-fine-tuner/SKILL.md" | head -1 | sed 's/^description: //')"
len=${#desc}
assert "Description is ${len} chars (limit 250)" "$([[ $len -le 250 ]] && echo true || echo false)"
echo ""

# ─── 8. TEMPLATE PLACEHOLDERS ─────────────────────────
echo "  8. Template placeholders exist"
for tmpl in single.html small.html full.html; do
  f="$ROOT/assets/templates/$tmpl"
  assert_contains "$tmpl" "__TITLE__" "$f"
  assert_contains "$tmpl" "__ELEMENT__" "$f"
  assert_contains "$tmpl" "__UPDATE_BODY__" "$f"
  assert_contains "$tmpl" "__PRESET_BUTTONS__" "$f"
  assert_contains "$tmpl" "__CTA_LABEL__" "$f"
  assert_contains "$tmpl" "__BODY_CLASS__" "$f"
done
echo ""

# ─── 9. ZOOM SYSTEM CORRECTNESS ──────────────────────
echo "  9. Zoom system (all 6 canvas files)"
for f in "$ROOT/assets/templates/single.html" "$ROOT/assets/templates/small.html" "$ROOT/assets/templates/full.html" \
         "$ROOT/samples/single-button-glow.html" "$ROOT/samples/small-pricing-card.html" "$ROOT/samples/full-dashboard-card.html"; do
  name="$(basename "$f")"
  assert_contains "$name" 'zoomBtn(1)' "$f"
  assert_contains "$name" 'zoomBtn(-1)' "$f"
  assert_not_contains "$name" 'zoomBtn(10)' "$f"
  assert_contains "$name" 'cx.*=.*0' "$f"
  assert_contains "$name" 'rect.width/2' "$f"
done
echo ""

# ─── 10. NAMING CONSISTENCY ──────────────────────────
echo "  10. Naming consistency"
# Check no bare "Akoum" (without "Al" prefix)
# Match "Akoum" only when NOT preceded by "Al" prefix — exclude this test file
akoum_count=$(grep -rn '[^l]Akoum\|^Akoum' "$ROOT" --include="*.md" --include="*.json" --include="*.html" --include="*.sh" --exclude="run-tests.sh" 2>/dev/null | wc -l | tr -d ' ')
assert "No bare 'Akoum' without 'Al' prefix (found $akoum_count)" "$([[ "$akoum_count" == "0" ]] && echo true || echo false)"

# Check no MIT license references
mit_count=$(grep -ri '\bMIT\b' "$ROOT" --include="*.md" --include="*.json" --include="*.html" 2>/dev/null | wc -l | tr -d ' ')
assert "No MIT license references (found $mit_count)" "$([[ "$mit_count" == "0" ]] && echo true || echo false)"
echo ""

# ─── 11. JSON VALIDITY ────────────────────────────────
echo "  11. JSON validity"
result="$(python3 -m json.tool "$ROOT/.claude-plugin/plugin.json" >/dev/null 2>&1 && echo true || echo false)"
assert "plugin.json is valid JSON" "$result"
assert_not_contains "plugin.json" '"hooks"' "$ROOT/.claude-plugin/plugin.json"

# marketplace.json must be valid and contain the ai-fine-tuner plugin entry
# so `claude plugin install ai-fine-tuner@<git-url>` resolves (see GitHub issue #1)
result="$(python3 -m json.tool "$ROOT/.claude-plugin/marketplace.json" >/dev/null 2>&1 && echo true || echo false)"
assert "marketplace.json is valid JSON" "$result"
assert_contains "marketplace.json" '"name": "ai-fine-tuner"' "$ROOT/.claude-plugin/marketplace.json"
assert_contains "marketplace.json" '"plugins"' "$ROOT/.claude-plugin/marketplace.json"
result="$(cd "$ROOT" && python3 -c "import json,sys; d=json.load(open('.claude-plugin/marketplace.json')); sys.exit(0 if any(p.get('name')=='ai-fine-tuner' for p in d.get('plugins',[])) else 1)" 2>/dev/null && echo true || echo false)"
assert "marketplace.json lists 'ai-fine-tuner' in plugins" "$result"
echo ""

# ─── 12. WEBSITE SECTIONS ────────────────────────────
echo "  12. Website completeness"
site="$ROOT/samples/index.html"
assert_contains "index.html" "Four ways it activates" "$site"
assert_contains "index.html" "Bespoke UI" "$site"
assert_contains "index.html" "Any language" "$site"
assert_contains "index.html" "Integration depth" "$site"
assert_contains "index.html" "Claude Plugin" "$site"
assert_contains "index.html" "Codex" "$site"
assert_contains "index.html" "Cursor" "$site"
assert_contains "index.html" "Windsurf" "$site"
assert_contains "index.html" "Cline" "$site"
assert_contains "index.html" "Aider" "$site"
assert_contains "index.html" "Source Available" "$site"
assert_contains "index.html" "Alakoum" "$site"
assert_not_contains "index.html" "codex plugin install" "$site"
echo ""

# ─── 13. IFRAME EMBED SUPPORT ────────────────────────
echo "  13. Iframe embed support (demos only)"
for f in "$ROOT/samples/single-button-glow.html" "$ROOT/samples/small-pricing-card.html" "$ROOT/samples/full-dashboard-card.html"; do
  name="$(basename "$f")"
  assert_contains "$name" "ft-embedded" "$f"
  assert_contains "$name" "window.self!==window.top" "$f"
done
echo ""

# ─── 14. LIGHT/DARK TOGGLE ──────────────────────────
echo "  14. Light/dark toggle (all 6 canvas files)"
for f in "$ROOT/assets/templates/single.html" "$ROOT/assets/templates/small.html" "$ROOT/assets/templates/full.html" \
         "$ROOT/samples/single-button-glow.html" "$ROOT/samples/small-pricing-card.html" "$ROOT/samples/full-dashboard-card.html"; do
  name="$(basename "$f")"
  assert_contains "$name" "ft-bg-icon" "$f"
  assert_contains "$name" "ft-bg-label" "$f"
done
echo ""

# ─── 15. BEHAVIORAL RULES IN DOCS ─────────────────────
echo "  15. Behavioral rules consistency"

# "Apply ALL values exactly" must be in all instruction files
assert_contains "AGENTS.md" "values EXACTLY" "$ROOT/AGENTS.md"
assert_contains "SKILL.md" "values EXACTLY" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "CLAUDE.md" "Apply ALL" "$ROOT/CLAUDE.md"

# "Confirm before generating" must be in all instruction files
assert_contains "AGENTS.md" "Confirm" "$ROOT/AGENTS.md"
assert_contains "SKILL.md" "Confirm" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "CLAUDE.md" "Confirm Before" "$ROOT/CLAUDE.md"

# Proactive triggers (all 4) in AGENTS.md and SKILL.md
assert_contains "AGENTS.md" "Iteration detection" "$ROOT/AGENTS.md"
assert_contains "AGENTS.md" "During a build" "$ROOT/AGENTS.md"
assert_contains "AGENTS.md" "Vague visual" "$ROOT/AGENTS.md"
assert_contains "AGENTS.md" "Agent self-expression" "$ROOT/AGENTS.md"
assert_contains "SKILL.md" "Iteration detection" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "SKILL.md" "During a build" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "SKILL.md" "Vague visual" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "SKILL.md" "Agent self-expression" "$ROOT/skills/ai-fine-tuner/SKILL.md"

# "bespoke" / "pre-built" messaging
assert_contains "SKILL.md" "pre-built" "$ROOT/skills/ai-fine-tuner/SKILL.md"

# Template search order documented
assert_contains "SKILL.md" "Finding templates" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "AGENTS.md" "Finding templates" "$ROOT/AGENTS.md"
echo ""

echo ""

# ─── 17. CROSS-FILE CONSISTENCY ──────────────────────
echo "  17. Cross-file consistency"

# Same name everywhere
assert_contains "plugin.json" "Alakoum" "$ROOT/.claude-plugin/plugin.json"
assert_contains "LICENSE" "Alakoum" "$ROOT/LICENSE"

# Same license everywhere
assert_not_contains "plugin.json" '"MIT"' "$ROOT/.claude-plugin/plugin.json"

# GitHub URLs consistent
assert_contains "plugin.json" "muhamadjawdatsalemalakoum" "$ROOT/.claude-plugin/plugin.json"

# No speculative commands
assert_not_contains "README.md" "codex plugin install" "$ROOT/README.md"
assert_not_contains "index.html" "codex plugin install" "$ROOT/samples/index.html"

# No __CONTROLS__ phantom placeholder
assert_not_contains "AGENTS.md" "__CONTROLS__" "$ROOT/AGENTS.md"
assert_not_contains "SKILL.md" "__CONTROLS__" "$ROOT/skills/ai-fine-tuner/SKILL.md"
echo ""

# ─── 18. BEHAVIORAL RULES IN DOCS ────────────────────
echo "  18. Behavioral rules in all docs"

# Apply ALL values exactly
assert_contains "AGENTS.md" "values EXACTLY" "$ROOT/AGENTS.md"
assert_contains "SKILL.md" "values EXACTLY" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "CLAUDE.md" "Apply ALL" "$ROOT/CLAUDE.md"

# Confirm before generating
assert_contains "SKILL.md" "Confirm" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "CLAUDE.md" "Confirm Before" "$ROOT/CLAUDE.md"

# All 4 proactive triggers in AGENTS.md
assert_contains "AGENTS.md" "Iteration detection" "$ROOT/AGENTS.md"
assert_contains "AGENTS.md" "During a build" "$ROOT/AGENTS.md"
assert_contains "AGENTS.md" "Vague visual" "$ROOT/AGENTS.md"
assert_contains "AGENTS.md" "Agent self-expression" "$ROOT/AGENTS.md"

# All 4 proactive triggers in SKILL.md
assert_contains "SKILL.md" "Iteration detection" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "SKILL.md" "During a build" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "SKILL.md" "Vague visual" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "SKILL.md" "Agent self-expression" "$ROOT/skills/ai-fine-tuner/SKILL.md"

# Template search order documented
assert_contains "SKILL.md" "Finding templates" "$ROOT/skills/ai-fine-tuner/SKILL.md"
assert_contains "AGENTS.md" "Finding templates" "$ROOT/AGENTS.md"
echo ""

# ─── 19. MANUAL INVOCATION ONLY ──────────────────────
echo "  19. No hooks anywhere (manual invocation only)"
assert_not_contains "plugin.json" '"hooks"' "$ROOT/.claude-plugin/plugin.json"
for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh install-utils.sh; do
  assert_not_contains "$f" "register_claude_hook" "$ROOT/$f"
done
echo ""

# ─── 20. INSTALLER FUNCTIONAL COMPLETENESS ───────────
echo "  20. Installer functional completeness"

for f in install-claude.sh install-codex.sh install-cursor.sh install-windsurf.sh install-cline.sh install-aider.sh; do
  assert_contains "$f" "banner" "$ROOT/$f"
  assert_contains "$f" "complete_msg" "$ROOT/$f"
  assert_contains "$f" "preflight" "$ROOT/$f"
  assert_contains "$f" "Proceed" "$ROOT/$f"
done


# install-utils.sh farewell
assert_contains "install-utils.sh" "Press Enter" "$ROOT/install-utils.sh"
assert_contains "install-utils.sh" "yottocode" "$ROOT/install-utils.sh"
assert_contains "install-utils.sh" "ancientprayers" "$ROOT/install-utils.sh"
echo ""

# ─── 21. DEMO-SPECIFIC CHECKS ───────────────────────
echo "  21. Demo-specific checks"

# Single demo presets are shadow-appropriate
assert_contains "single-button-glow.html" "Flat" "$ROOT/samples/single-button-glow.html"
assert_contains "single-button-glow.html" "Subtle" "$ROOT/samples/single-button-glow.html"
assert_contains "single-button-glow.html" "Deep" "$ROOT/samples/single-button-glow.html"
assert_not_contains "single-button-glow.html" "Neon" "$ROOT/samples/single-button-glow.html"
assert_contains "single-button-glow.html" "Button Shadow" "$ROOT/samples/single-button-glow.html"

# All demos have nav with logo mark
for f in "$ROOT/samples/single-button-glow.html" "$ROOT/samples/small-pricing-card.html" "$ROOT/samples/full-dashboard-card.html"; do
  assert_contains "$(basename "$f")" "ft-nav-mark" "$f"
done

# syncPreviewBottom in single+small, NOT full
assert_contains "single-button-glow.html" "syncPreviewBottom" "$ROOT/samples/single-button-glow.html"
assert_contains "small-pricing-card.html" "syncPreviewBottom" "$ROOT/samples/small-pricing-card.html"
assert_not_contains "full-dashboard-card.html" "syncPreviewBottom" "$ROOT/samples/full-dashboard-card.html"
echo ""

# ─── 22. WEBSITE COMPLETENESS ────────────────────────
echo "  22. Website all sections"
site="$ROOT/samples/index.html"
assert_contains "index.html" "What the agent says" "$site"
assert_contains "index.html" "Proceed?" "$site"
assert_contains "index.html" "Four ways it activates" "$site"
assert_contains "index.html" "Strongest where it matters" "$site"
assert_contains "index.html" "Button Shadow" "$site"
assert_not_contains "index.html" "codex plugin install" "$site"
echo ""

# ─── 23. TEMPLATE vs DEMO CONSISTENCY ─────────────────
echo "  23. Template vs demo consistency"

# Each demo should have the SAME infrastructure as its template.
# Templates have __PLACEHOLDER__ tokens; demos have real values in their place.
# But the CSS classes, JS functions, and HTML structure must match.

# Infrastructure CSS classes that MUST exist in both template and demo
INFRA_CLASSES="ft-preview ft-canvas ft-zoom-controls ft-zoom-btn ft-zoom-label ft-reset-btn ft-collapse-btn ft-expand-tab"

# Infrastructure JS functions that MUST exist in both template and demo
INFRA_FUNCS="applyTransform zoomBtn centerCanvas toggleBg togglePanel updateTrack"

# single.html <-> single-button-glow.html
for cls in $INFRA_CLASSES; do
  assert_contains "single.html" "$cls" "$ROOT/assets/templates/single.html"
  assert_contains "single-button-glow.html" "$cls" "$ROOT/samples/single-button-glow.html"
done
for fn in $INFRA_FUNCS syncPreviewBottom; do
  assert_contains "single.html" "$fn" "$ROOT/assets/templates/single.html"
  assert_contains "single-button-glow.html" "$fn" "$ROOT/samples/single-button-glow.html"
done

# small.html <-> small-pricing-card.html
for cls in $INFRA_CLASSES; do
  assert_contains "small.html" "$cls" "$ROOT/assets/templates/small.html"
  assert_contains "small-pricing-card.html" "$cls" "$ROOT/samples/small-pricing-card.html"
done
for fn in $INFRA_FUNCS syncPreviewBottom; do
  assert_contains "small.html" "$fn" "$ROOT/assets/templates/small.html"
  assert_contains "small-pricing-card.html" "$fn" "$ROOT/samples/small-pricing-card.html"
done

# full.html <-> full-dashboard-card.html
for cls in $INFRA_CLASSES; do
  assert_contains "full.html" "$cls" "$ROOT/assets/templates/full.html"
  assert_contains "full-dashboard-card.html" "$cls" "$ROOT/samples/full-dashboard-card.html"
done
for fn in $INFRA_FUNCS; do
  assert_contains "full.html" "$fn" "$ROOT/assets/templates/full.html"
  assert_contains "full-dashboard-card.html" "$fn" "$ROOT/samples/full-dashboard-card.html"
done

# Template-specific classes
assert_contains "single.html" "ft-bar" "$ROOT/assets/templates/single.html"
assert_contains "single-button-glow.html" "ft-bar" "$ROOT/samples/single-button-glow.html"
assert_contains "small.html" "ft-panel" "$ROOT/assets/templates/small.html"
assert_contains "small-pricing-card.html" "ft-panel" "$ROOT/samples/small-pricing-card.html"
assert_contains "full.html" "ft-controls" "$ROOT/assets/templates/full.html"
assert_contains "full-dashboard-card.html" "ft-controls" "$ROOT/samples/full-dashboard-card.html"

# Verify demos have NO leftover __PLACEHOLDER__ tokens
for f in "$ROOT/samples/single-button-glow.html" "$ROOT/samples/small-pricing-card.html" "$ROOT/samples/full-dashboard-card.html"; do
  name="$(basename "$f")"
  assert_not_contains "$name" '__TITLE__' "$f"
  assert_not_contains "$name" '__ELEMENT__' "$f"
  assert_not_contains "$name" '__UPDATE_BODY__' "$f"
  assert_not_contains "$name" '__PRESET_BUTTONS__' "$f"
  assert_not_contains "$name" '__CONTROL_GROUPS__' "$f"
  assert_not_contains "$name" '__BODY_CLASS__' "$f"
done

# Verify CSS variables are consistent
CSS_VARS="--ft-bg --ft-surface --ft-surface-2 --ft-surface-3 --ft-border --ft-border-strong --ft-text --ft-text-dim --ft-text-faint --ft-accent --ft-accent-hover --ft-green --ft-ease --ft-duration"
for var in $CSS_VARS; do
  for f in "$ROOT/assets/templates/single.html" "$ROOT/assets/templates/small.html" "$ROOT/assets/templates/full.html" \
           "$ROOT/samples/single-button-glow.html" "$ROOT/samples/small-pricing-card.html" "$ROOT/samples/full-dashboard-card.html"; do
    assert_contains "$(basename "$f")" "$var" "$f"
  done
done
echo ""

# ─── SUMMARY ─────────────────────────────────────────
echo "  ═══════════════════════════════════════════"
if [[ $FAIL -eq 0 ]]; then
  green "  ALL $TOTAL TESTS PASSED"
else
  red "  $FAIL FAILED out of $TOTAL tests"
fi
echo "  $PASS passed, $FAIL failed"
echo ""
