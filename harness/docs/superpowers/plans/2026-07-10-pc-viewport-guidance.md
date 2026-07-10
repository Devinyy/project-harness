# PC Viewport Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a consistent PC design-canvas, default-viewport, and responsive-adaptation rule to the harness template.

**Architecture:** Keep visual reference information in the UI component guide and implementation constraints in coding standards. Both rules apply only to the PC micro-app template and do not alter generated project specs.

**Tech Stack:** Markdown documentation, Git.

---

### Task 1: Document PC design and responsive sizing rules

**Files:**
- Modify: `spec-templates/pc-microapp/06_UI_COMPONENT_GUIDE.md`
- Modify: `spec-templates/pc-microapp/04_CODING_STANDARDS.md`
- Test: `git diff --check`

- [x] **Step 1: Add UI-guide reference dimensions**

Add a `PC 画布与自适应` subsection below `PC 设计 Token` stating that Figma restoration uses a `1440 × 900` design canvas and default development/acceptance uses a `1920 × 1080` viewport.

- [x] **Step 2: Add coding-standard implementation constraints**

Add a `PC 尺寸与自适应` subsection under styles that requires layouts to adapt to the available viewport, prohibits fixed full-page `1440px`/`1920px` widths, and permits a reasonable minimum width with horizontal scrolling for data-dense desktop screens.

- [x] **Step 3: Validate Markdown whitespace**

Run: `git diff --check`

Expected: no output and exit status 0.

- [x] **Step 4: Commit**

Run: `git add spec-templates/pc-microapp/04_CODING_STANDARDS.md spec-templates/pc-microapp/06_UI_COMPONENT_GUIDE.md docs/superpowers/plans/2026-07-10-pc-viewport-guidance.md && git commit -m "docs: add pc viewport guidance"`

Expected: commit contains exactly the two PC template files and this implementation plan.
