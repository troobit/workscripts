# VS Code on macOS — Speed Cheat Sheet (Distilled)

**Core Navigation**
- **`Cmd + P`**: Quick Open (fuzzy file search; use `:` for line, `@` for symbol).
- **`Cmd + Shift + P`**: Command Palette (run commands; open Keyboard Shortcuts to verify mappings).
- **`Cmd + B`**: Toggle Sidebar (show/hide Explorer/Search/SCM/Extensions).
- **`Cmd + 0`**: Focus Sidebar (use `Cmd + 1` to return to the editor).
- **`Cmd + 1 / Cmd + 2 / Cmd + 3`**: Focus Editor Group (jump between splits).

**Search & Jump**
- **`Cmd + Shift + F`**: Global Search (regex and file filters supported).
- **`Cmd + G`**: Go to line.
- **`Cmd + Up/Down`**: Jump to start/end of file.

**Editor Workflow**
- **`Cmd + \`**: Split editor (side-by-side).
- **`Cmd + W`** / **`Cmd + Shift + T`**: Close tab / Reopen last closed tab.
- **`Cmd + Opt + Left/Right`**: Navigate back/forward between files.
- **`Cmd + Shift + K`**: Delete line.
- **`Cmd + X`** (no selection): Cut line.
- **`Cmd + C`** (no selection): Copy line.
- **`Cmd + L`**: Select line.
- **`Cmd + Enter`** / **`Cmd + Shift + Enter`**: Insert line below / above.
- **`Opt + Left/Right`**: Jump by word.
- **`Opt + Up/Down`**: Move line up/down.  **`Shift + Opt + Up/Down`**: Copy line up/down.

**Multi-cursor & Selection**
- **`Cmd + D`**: Add next match (multi-cursor).
- **`Cmd + Shift + L`**: Select all occurrences.
- **`Opt + Shift + I`**: Insert cursor at end of each selected line.
- **`Cmd + U`**: Undo last cursor.
- **`Opt + Click`**: Add cursor at click position.

**Terminal**
- **`Ctrl + \``** (backtick): Toggle integrated terminal.

**AI & Extensions (Copilot / Claude)**
- **`Tab`**: Accept Copilot inline suggestion.  **`Esc`**: Dismiss suggestion.
- **`Cmd + I`**: Copilot inline chat (ask about code in-place).
- **`Cmd + Shift + I`**: Copilot chat panel (persistent repo-aware chat).
- **`Opt + ]` / `Opt + [`**: Cycle Copilot suggestions.
- **`Cmd + Shift + P → "Claude: Open Chat"`**: Open Claude Code chat (if configured).
- **`Cmd + Shift + P → "Claude: Explain Selection"`**: Explain highlighted code.
- **`Cmd + Shift + P → "Claude: Refactor Selection"`**: Refactor highlighted code.
- **`Cmd + Shift + P → "Claude: Fix Errors"`**: Target diagnostics in the active file.
- **`Cmd + Shift + Esc`**: Open Claude tab (if configured).
- **`Cmd + Esc`**: Toggle focus between editor and Claude (if configured).
- **`Alt + K`**: AI Context / @-mention files in Claude.
- **Credential note**: Ensure `~/.claudecreds` contains your model string for Claude extensions.

**Vim-like / Power Habits**
- Use `Cmd + P` instead of clicking the tree; `Cmd + 0` to open explorer then `Enter` → `Cmd + 1` to return to code.
- Split editor + AI chat = review changes live.
- Select → Ask AI (Claude or Copilot) for focused results.

**Quick Recipes**
- **Search → open → code:** `Cmd + Shift + F` → `Enter` → `Cmd + 1`.
- **Explorer → open file → code:** `Cmd + 0` → `Enter` → `Cmd + 1`.
- **Terminal → run → code:** `Ctrl + \`` → run → `Cmd + 1`.

