# VS Code on macOS — Speed Cheat Sheet (GPT-5.2)

> **Audience:** macOS users who want fast navigation in VS Code.
> **Note:** Keybindings can vary by VS Code version, keyboard layout, and extensions.
> Verify/change: `Cmd + Shift + P` → **Preferences: Open Keyboard Shortcuts**.

---

## Core navigation

### `Cmd + P` — Quick Open
- Find any file by name (fuzzy search)
- Type `:` to jump to a line, `@` to jump to a symbol

### `Cmd + Shift + P` — Command Palette
- Run any command (settings, extensions, refactors)

### `Cmd + Shift + F` — Global Search
- Search across the whole workspace
- Regex and file filters supported

**After you search (focus back to code):**
- `Cmd + 1` (or `Cmd + 2/3`) to focus an editor group
- `Ctrl + 1` to move focus to the editor area (UI focus)
- `Cmd + B` to hide the sidebar and return to editing

---

## Sidebar & focus control

### `Cmd + B` — Toggle Sidebar
- Show/hide Explorer/Search/SCM/Extensions

### `Cmd + 0` — Focus Sidebar
- Moves keyboard focus into the sidebar (typically the Explorer tree)

**After `Cmd + 0` (get back to the editor):**
- `Cmd + 1` to focus editor group 1
- `Ctrl + 1` to focus the editor area
- Optional: `Cmd + B` to hide the sidebar

### `Ctrl + 1 / 2 / 3 / 4` — Move focus between UI areas
- `Ctrl + 1`: Editor
- `Ctrl + 2`: Sidebar
- `Ctrl + 3`: Panel (Terminal/Output)
- `Ctrl + 4`: Secondary panel / other UI area

---

## Editor workflow

### `Cmd + 1 / 2 / 3` — Focus editor groups
- Jump between split panes (left → right)

### `Cmd + \\` — Split editor
- View files side-by-side

### `Cmd + W` / `Cmd + Shift + T` — Close & reopen tab
- `Cmd + W` closes current tab
- `Cmd + Shift + T` reopens last closed editor

### `Cmd + Opt + Left/Right` — Navigate back/forward
- Like browser back/forward, but for code navigation

---

## Terminal

### `Ctrl + \`` — Toggle integrated terminal
- Open/hide the terminal panel

**After you run a command (focus back to code):**
- `Cmd + 1` to focus editor group 1
- `Ctrl + 1` to focus the editor area

---

## Multi-cursor edits

### `Cmd + D` — Add next match
- Select the next occurrence of the current selection

### `Cmd + Shift + L` — Select all occurrences
- Select all matches of the current selection

---

## GitHub Copilot (common defaults)

### `Tab` — Accept inline suggestion

### `Esc` — Dismiss suggestion

### `Cmd + I` — Copilot inline chat
- Ask Copilot in-place (best with a selection)

### `Cmd + Shift + I` — Copilot chat panel
- Persistent chat panel

### `Opt + ]` / `Opt + [` — Cycle suggestions

---

## Claude Code (extension-dependent)

> Defaults vary by extension/version.

### `Cmd + Shift + Esc` — Open Claude tab (if configured)

### `Cmd + Esc` — Toggle focus between editor and Claude (if configured)

---

## At-a-glance table

| Shortcut | Action |
|---|---|
| `Cmd + P` | Quick Open (file) |
| `Cmd + Shift + P` | Command Palette |
| `Cmd + Shift + F` | Global Search |
| `Cmd + B` | Toggle Sidebar |
| `Cmd + 0` | Focus Sidebar |
| `Cmd + 1/2/3` | Focus Editor Group |
| `Ctrl + 1/2/3/4` | Focus UI Area |
| `Cmd + \\` | Split Editor |
| `Ctrl + \`` | Toggle Terminal |
| `Cmd + D` | Next match selection |
| `Cmd + Shift + L` | Select all matches |
| `Cmd + I` | Copilot inline chat |
| `Cmd + Shift + I` | Copilot chat panel |

---

## Vim-like shortcuts

### Line operations

- **`Cmd + Shift + K`** — Delete line (like `dd`)
  - Deletes entire line where cursor is, no selection needed
- **`Cmd + X`** — Cut line (when nothing selected)
  - Acts like `dd` but puts line in clipboard
- **`Cmd + C`** — Copy line (when nothing selected)
  - Acts like `yy` - copies whole line

### Selection (Visual mode equivalents)

- **`Cmd + L`** — Select line
  - Like `V` in vim - selects current line
- **`Cmd + Shift + L`** — Select all occurrences (after selecting text)
  - Creates cursors at all matches
- **`Opt + Shift + I`** — Insert cursor at end of each selected line
  - Like `A` in visual block mode

### Navigation

- **`Cmd + G`** — Go to line
  - Like `:123` in vim
- **`Cmd + Up/Down`** — Jump to start/end of file
  - Like `gg` and `G`
- **`Opt + Left/Right`** — Jump by word
  - Like `w` and `b` movements

### Copy/Paste/Move

- **`Opt + Up/Down`** — Move line up/down
  - Like `ddkP` or `ddp` in vim
- **`Shift + Opt + Up/Down`** — Copy line up/down
  - Like `yyP` or `yyp`
- **`Cmd + Enter`** — Insert line below
  - Like `o` in vim
- **`Cmd + Shift + Enter`** — Insert line above
  - Like `O` in vim

### Multiple cursors (vim's dot command on steroids)

- **`Cmd + D`** — Add next match to selection
  - Select word, then `Cmd + D` repeatedly to add more
- **`Cmd + U`** — Undo last cursor
  - Back out if you added too many
- **`Opt + Click`** — Add cursor at click position
  - Like multiple insert points

### For full vim modal editing

Install the **Vim extension** (`vscodevim.vim`) for complete `hjkl` navigation, visual mode, commands, etc.

---

## Fast "focus recipes" (muscle memory)

- **Search → open result → code:** `Cmd + Shift + F` → `Enter` → `Cmd + 1`
- **Explorer → open file → code:** `Cmd + 0` → `Enter` → `Cmd + 1`
- **Terminal → run → code:** `Ctrl + \`` → run → `Cmd + 1`
