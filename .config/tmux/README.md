# tmux config

Prefix: **`Ctrl+Space`**. Press it once, release, then press the next key.

---

## Status Bar (top)

```
 main │ 1  dirname   2  dirname  │        prefix  Sun 26 Apr  08:24
```

- **Left**: session name (gold)
- **Middle**: windows — index + current directory; active window highlighted gold
- **Right**: state indicators + date/time

### State indicators (top-right)

| Shows | When |
|-------|------|
| `zoom` | A pane is zoomed fullscreen |
| `copy` | Copy mode is active |
| **`prefix`** (gold) | Prefix key was pressed, waiting for next key |

Multiple indicators can appear at once, e.g. `zoom prefix 08:24`.

---

## Splits & Panes

| Key | Action |
|-----|--------|
| `prefix v` | Vertical split (left \| right) |
| `prefix h` | Horizontal split (top / bottom) |
| `Alt+h` | Move to left pane _(no prefix)_ |
| `Alt+j` | Move to pane below _(no prefix)_ |
| `Alt+k` | Move to pane above _(no prefix)_ |
| `Alt+l` | Move to right pane _(no prefix)_ |
| `prefix Left` | Resize pane left (repeatable) |
| `prefix Down` | Resize pane down (repeatable) |
| `prefix Up` | Resize pane up (repeatable) |
| `prefix Right` | Resize pane right (repeatable) |
| `prefix z` | Toggle zoom (fullscreen) current pane — shows `zoom` in bar |
| `prefix x` | Kill current pane |
| `prefix q` | Show pane numbers |
| `prefix e` | Toggle sync panes (type in all panes simultaneously) |

---

## Windows

| Key | Action |
|-----|--------|
| `prefix c` | New window (inherits current path) |
| `prefix n` | Next window |
| `prefix p` | Previous window |
| `prefix Tab` | Last active window |
| `Alt+1` … `Alt+5` | Jump to window 1–5 _(no prefix)_ |

Windows are numbered from 1 and renumber automatically when one is closed.

---

## Sessions

| Key | Action |
|-----|--------|
| `prefix d` | Detach from session |
| `prefix k` | Kill current session |
| `prefix S` | Open session picker |

---

## Layouts

| Key | Action |
|-----|--------|
| `prefix w` | Dev workspace layout |

```
┌──────────────┬──────────────┐
│              │              │
│     nvim     │    claude    │
│              │              │
├──────────────┴──────────────┤
│          terminal           │
└─────────────────────────────┘
```

Top panes 70% height, terminal 30%.

---

## Copy Mode

Scroll and copy terminal output without a mouse. Like vim visual mode on your history.

| Key | Action |
|-----|--------|
| `prefix [` | Enter copy mode (shows `copy` in bar) |
| `k / j` | Scroll up/down line by line |
| `u / d` | Scroll up/down half page |
| `/` | Search forward |
| `?` | Search backward |
| `v` | Begin selection |
| `y` | Yank selection to clipboard, exit copy mode |
| `q` / `Escape` | Exit copy mode |

---

## Misc

| Key | Action |
|-----|--------|
| `prefix r` | Reload config live |
| `prefix Ctrl+Space` | Send literal Ctrl+Space to the application |

---

## Launching tmux

`Mod+Alt+Return` (Niri) — opens Alacritty and attaches to session `main`, creating it if it doesn't exist.

---

## Notable Settings

| Setting | Value | Why |
|---------|-------|-----|
| `escape-time` | 0 | No delay after Escape — required for Neovim |
| `history-limit` | 50 000 | Large scrollback |
| `base-index` | 1 | Windows/panes start at 1 (matches keyboard row) |
| `renumber-windows` | on | No gaps after closing a window |
| `mouse` | off | Keyboard-only |
| `mode-keys` | vi | Vi motions in copy mode |
| `focus-events` | on | Neovim autoread works correctly inside tmux |
