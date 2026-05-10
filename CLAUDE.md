# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

AI Fine-Tuner — a Claude Code plugin (skill) that teaches AI coding agents to generate interactive HTML fine-tuning GUIs. When a user is iterating on visual parameters (shadows, border-radius, spacing, colors, etc.), the agent generates a self-contained HTML file with sliders and a live preview of the user's actual element instead of going back and forth in chat.

This repo is the plugin source — not a runtime application. There is no build step, no dependencies, and no tests. The deliverables are markdown instruction files and HTML templates.

## Architecture

```
ai-fine-tuner/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest (name, version, keywords)
│   └── marketplace.json         # Marketplace catalog (so `claude plugin install …@<git-url>` works)
├── skills/ai-fine-tuner/
│   └── SKILL.md                 # Claude Code skill definition (YAML frontmatter + instructions)
├── AGENTS.md                    # Universal spec — the core document any AI agent reads
├── agents/                      # Per-agent setup guides (codex.md, cursor.md, generic.md)
├── assets/templates/            # 3 pre-built HTML templates (single, small, full)
├── samples/                     # 4 HTML files (index.html landing page + 3 demos)
├── install-claude.sh            # Claude Code installer
├── install-codex.sh             # OpenAI Codex installer
├── install-cursor.sh            # Cursor installer
├── install-windsurf.sh          # Windsurf installer
├── install-cline.sh             # Cline installer
├── install-aider.sh             # Aider installer
├── install-utils.sh             # Shared installer utilities
├── LICENSE                      # Source Available License
└── README.md                    # Documentation
```

**Two key instruction files:**
- `AGENTS.md` — the universal spec. Contains template placeholders, control patterns, output formats, cross-platform rendering rules, and the generation workflow. This is the source of truth.
- `skills/ai-fine-tuner/SKILL.md` — Claude-specific skill wrapping `AGENTS.md`. Searches for it at `../../AGENTS.md` (plugin root), `references/AGENTS.md` (CLI install), or `AGENTS.md` in project root. Contains the YAML frontmatter trigger description and Claude-specific workflow steps.

**Three template tiers** (in `assets/templates/`):
- `single.html` — 1 control: full-screen preview + bottom bar
- `small.html` — 2-4 controls: full-screen preview + bottom panel grid
- `full.html` — 5+ controls: left sidebar with grouped sliders + right preview

Templates use `__PLACEHOLDER__` tokens that the agent fills in. Template CSS/layout must not be modified.

## Key Conventions

- The plugin generates standalone HTML files that work via `file://` — no build tools, no external JS, only Google Fonts CDN allowed.
- Templates use CSS variables prefixed `--ft-` (e.g., `--ft-bg`, `--ft-surface`, `--ft-accent`).
- Control HTML uses class names prefixed `ft-` (e.g., `ft-control`, `ft-val`, `ft-btn-sm`).
- Generated tuners are stored in `.fine-tune/[element]-[property]/` at the project root. Each folder has the HTML (user-facing) and `context.md` (agent-facing, for reuse across sessions).
- The agent checks `.fine-tune/*/context.md` before creating new tuners to reuse existing ones (regenerating the HTML from current source).
- All range/color/text inputs must use `oninput` (not `onchange`) for instant feedback.
- The `update()` function uses direct `el.style` manipulation for <16ms updates.
- Output formats: CSS, Tailwind, Flutter, SwiftUI, React Native, JSON — detected from the user's stack.
- `__CTA_LABEL__` placeholder controls the copy button text (default: `Copy to Clipboard`). `__BODY_CLASS__` placeholder on `<body>` accepts `ft-no-panel` and/or `ft-no-cta` to hide controls or the copy button for canvas-only mode.
- Multiple elements can be placed in `__ELEMENT__` for compound tuning or showcases — control groups should be labeled per target element.

## Installers

Six shell installers (`install-claude.sh`, `install-codex.sh`, `install-cursor.sh`, `install-windsurf.sh`, `install-cline.sh`, `install-aider.sh`) are interactive with colored output. They:
1. Pre-flight check that all source files exist
2. Offer scope/method choices where applicable
3. Show a summary and confirm before copying files
4. Copy AGENTS.md + templates to the correct location
5. Handle existing AGENTS.md (append/replace/skip)
6. Add `.fine-tune/` to `.gitignore`

Run with: `./install-claude.sh` or `./install-codex.sh`

## Three Non-Negotiable Rules

1. **Preview Authenticity** — the preview must be a pixel-faithful reproduction of the user's actual element. Read real source, resolve all abstractions to concrete values. No placeholders.
2. **Confirm Before Generating** — always ask user before generating. Explain that the editor is pre-built (infinite canvas, zoom, presets) and you only fill in their element and values. It costs extra tokens but saves many rounds of back-and-forth. Skip only if user said "just do it."
3. **Apply ALL Values Exactly** — when the user pastes tuned values back, apply every single property without modification. Do NOT skip properties, preserve design tokens over tuned values, or make judgment calls about which values to keep. The user tuned them intentionally.

## Proactive Behavior

The agent should proactively suggest the fine-tuner when: (1) it has adjusted visual values on the same element 2+ times, (2) it just built a new component with visual styling, (3) the user gives vague visual feedback, or (4) the agent itself wants to communicate visual options — use the tuner as a visual voice instead of describing CSS values in text. Works on existing AND newly created elements.
