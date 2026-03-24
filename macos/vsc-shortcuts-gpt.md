# VS Code on macOS — Speed Cheat Sheet (with Claude Code & GitHub Copilot)

> **Audience:** macOS users who want fast, low-friction navigation of large codebases  
> **Note on AI shortcuts:** Claude Code and GitHub Copilot shortcuts are **configurable** and can vary by extension version. The ones below are the **most common defaults**.  
> To verify or change any shortcut: **Cmd + Shift + P → “Keyboard Shortcuts”**.

---

## ⌘ P — Quick File Open
### Open any file by name, instantly
- Fuzzy-search files across the workspace
- Type partial paths (`src/app`, `user.ts`)
- Add `:` to jump to a line, `@` to jump to a symbol

**Habit:** Use this instead of clicking the file tree.

---

## ⌘ Shift P — Command Palette
### Access *everything* VS Code can do
- Open settings, extensions, keybindings
- Run extension commands (Claude, Copilot)
- Prefix with `>` for commands, `?` for help

**Habit:** If you don’t know *where* something is, it’s here.

---

## ⌘ B — Toggle Sidebar
### Show / hide the file tree
- Gives you horizontal space
- Works for Explorer, Search, SCM, Extensions

**Habit:** Hide it when reading or editing code.

---

## ⌘ ⌥ ← / → — Navigate File History
### Move back and forward between files
- Like browser back/forward, but for code

**Habit:** Use instead of reopening files.

---

## ⌘ W / ⌘ Shift T — Close & Reopen Tabs
### Manage open editors fast
- ⌘ W closes current tab
- ⌘ Shift T reopens last closed file

---

## ⌘ \ — Split Editor
### View files side-by-side
- Repeat to create more splits
- Works great with AI-generated diffs

---

## ⌘ 1 / 2 / 3 — Focus Editor Groups
### Jump between split panes
- Left → Right → Far right

**Habit:** Combine with splits to avoid mouse use.

---

## ⌃ ` — Toggle Integrated Terminal
### Open / hide terminal panel
- Respects project root
- Essential for running tests & scripts

---

## ⌘ Shift F — Global Search
### Search across the entire codebase
- Supports regex
- Filter by file type (`*.ts`, `!dist`)

**Habit:** Prefer this over IDE symbol search when exploring unfamiliar repos.

---

## ⌘ D — Multi-Cursor (Next Match)
### Edit multiple identical tokens
- Repeatedly selects next occurrence

---

## ⌘ Shift L — Select All Occurrences
### Mass edit all matches at once

---

# 🧠 Focus & Navigation Control

## ⌃ 1 / 2 / 3 / 4
### Move focus between UI areas
- 1: Editor
- 2: Sidebar
- 3: Panel (Terminal, Output)
- 4: Status / secondary panel

**Habit:** Learn focus movement to stay keyboard-only.

---

## ⌘ K Z — Zen Mode
### Full-screen distraction-free editing

---

# 🤖 Claude Code (VS Code Extension)

> **Assumption:** You store temporary backend connection strings in  
> `~/.claudecreds` (referenced by the extension configuration).

## ⌘ Shift P → “Claude: Open Chat”
### Open Claude Code chat panel
- Uses credentials from `~/.claudecreds`
- Context-aware of open files & selections

---

## ⌘ Shift P → “Claude: Explain Selection”
### Get an explanation of highlighted code

---

## ⌘ Shift P → “Claude: Refactor Selection”
### Ask Claude to rewrite or improve code

---

## ⌘ Shift P → “Claude: Fix Errors”
### Target diagnostics in the active file

**Habit:** Select code *first*, then invoke Claude — you get tighter answers.

---

# 🧠 GitHub Copilot

## Tab — Accept Suggestion
### Insert Copilot’s inline completion

---

## ⌘ I — Inline Copilot Chat
### Ask Copilot about code in-place
- Works best with a selection

---

## ⌘ Shift I — Copilot Chat Panel
### Persistent chat with repo context

---

## ⌥ ] / ⌥ [ — Cycle Suggestions
### Move between alternative completions

---

## Esc — Dismiss Suggestion
### Clear inline ghost text

**Habit:** Let Copilot autocomplete *boring* code; you review logic.

---

# ⚡ Power Habits That Compound

- **⌘ P → ⌘ W → ⌘ Shift T** = fluid file flow
- **Split editor + AI chat** = review changes live
- **Hide sidebar (⌘ B)** when thinking
- **Search before browsing** in new repos
- **Select → Ask AI** (Claude or Copilot) for precision

---

# 📋 At-a-Glance Shortcut Table (Mac)

| Shortcut | What |
|--------|------|
| ⌘ P | Open file |
| ⌘ Shift P | Command palette |
| ⌘ B | Toggle sidebar |
| ⌘ W | Close tab |
| ⌘ Shift T | Reopen tab |
| ⌘ \\ | Split editor |
| ⌘ 1 / 2 / 3 | Focus editor group |
| ⌃ ` | Terminal |
| ⌘ Shift F | Global search |
| ⌘ D | Multi-cursor |
| ⌘ Shift L | Select all matches |
| ⌘ I | Copilot inline chat |
| Tab | Accept AI suggestion |
| ⌘ Shift P → Claude | Claude commands |

---

## Final Tip
If a shortcut isn’t listed here, it’s probably discoverable via  
**⌘ Shift P → “Show Keyboard Shortcuts”** — mastery comes from *not* memorizing everything, but knowing where to look fast.
