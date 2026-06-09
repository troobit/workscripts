## Nav

| | | | |
| --- | --- | --- | --- |
| **⌘ P** | Quick Open (fuzzy file) | **⇧ ⌘ P** | Command Palette |
| **⌘ B** | Toggle sidebar | **⌘ 0** | Focus sidebar |
| **⌘ 1** | Focus editor | **⌘ 1 / 2 / 3** | Switch editor groups |
| **⌃ 1 / 2 / 3 / 4** | Focus UI area (editor / sidebar / panel) | | |

## Find

| | | | |
| --- | --- | --- | --- |
| **⇧ ⌘ F** | Global search (regex + filters) | **⌘ G** | Go to line |
| **⌘ ↑** | Start of file | **⌘ ↓** | End of file |

## Edit

| | | | |
| --- | --- | --- | --- |
| **⌘ \\** | Split editor | **⌥ ⌘ ← / →** | Navigate file history (back/forward) |
| **⌘ W** | Close tab | **⇧ ⌘ T** | Reopen last closed tab |
| **⇧ ⌘ K** | Delete line | **⌘ L** | Select line |
| **⌘ X** | Cut line (no selection) | **⌘ C** | Copy line (no selection) |
| **⌘ ⏎** | Insert line below | **⇧ ⌘ ⏎** | Insert line above |
| **⌥ ← / →** | Jump by word | **⌥ ↑ / ↓** | Move line up/down |
| **⇧ ⌥ ↑ / ↓** | Copy line up/down | **⌘ K Z** | Zen mode (full-screen) |

## Multi-Select

| | | | |
| --- | --- | --- | --- |
| **⌘ D** | Add next match | **⇧ ⌘ L** | Select all occurrences |
| **⇧ ⌥ I** | Cursor at end of each line | **⌘ U** | Undo last cursor |
| **⌥ Click** | Add cursor at click | | |

## Terminal & ML

| | | | |
| --- | --- | --- | --- |
| **⌃ `** | Toggle integrated terminal | **⌥ K** | context / @-mention files |
| **⇥** | Accept Copilot suggestion | **⎋** | Dismiss suggestion |
| **⌘ I** | Copilot inline chat | **⇧ ⌘ I** | Copilot chat panel |
| **⌥ ] / [** | Cycle Copilot suggestions | | |
| **⇧ ⌘ ⎋** | Open Claude tab | **⌘ ⎋** | Toggle focus editor ↔ Claude |

Claude actions via `⇧ ⌘ P` → "Claude: Open Chat / Explain / Refactor / Fix Errors". Credential note: `~/.claudecreds` must hold your model string.

## Combos

| | |
| --- | --- |
| Search → open → code | **⇧ ⌘ F** → **⏎** → **⌘ 1** |
| Explorer → open → code | **⌘ 0** → **⏎** → **⌘ 1** |
| Terminal → run → code | **⌃ `** → run → **⌘ 1** |
| Quick Open → line / symbol | **⌘ P** then `:` / `@` |
| Quick Open → command / help | **⌘ P** then `>` / `?` |
| Global search filters | regex · `*.ts` include · `!dist` exclude |

Glyphs: `⌘` Cmd · `⌥` Option · `⇧` Shift · `⌃` Control · `⏎` Return · `⎋` Esc · `⇥` Tab