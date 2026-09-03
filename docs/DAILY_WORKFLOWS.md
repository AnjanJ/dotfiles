# My Personal Aerospace Setup
## Work/Personal Split Organization

**Last Updated**: 2026-09-03 (chords and workspace numbers follow the generated table in [KEYBINDINGS.md](KEYBINDINGS.md); `dotfiles keys` prints the live list)

---

## 🎯 My Workspace Layout

### TERMINAL, BROWSERS, EDITOR (Workspaces 1-4)

```
┌─────────────────────────────────────┐
│ WORKSPACE 1: Terminal               │
│ → Warp                              │
│ → Commands, git, servers            │
│ Shortcut: Ctrl+Shift+1              │
│ Launch: Ctrl+Shift+W                │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ WORKSPACE 2: Personal Browser       │
│ → Zen                               │
│ → Personal browsing, research       │
│ Shortcut: Ctrl+Shift+2              │
│ Launch: Ctrl+Shift+X                │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ WORKSPACE 3: Work Browser           │
│ → Google Chrome                     │
│ → Work tabs, docs, web apps         │
│ Shortcut: Ctrl+Shift+3              │
│ Launch: Ctrl+Shift+C (new window)   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ WORKSPACE 4: Code Editor            │
│ → Zed (primary)                     │
│ → VS Code (alternative)             │
│ Shortcut: Ctrl+Shift+4              │
│ Launch: Ctrl+Shift+Z (Zed)          │
│         Ctrl+Shift+V (VS Code)      │
└─────────────────────────────────────┘
```

---

### MAIL, NOTES, CHAT, AI (Workspaces 5-7)

```
┌─────────────────────────────────────┐
│ WORKSPACE 5: Email                  │
│ → Proton Mail                       │
│ Shortcut: Ctrl+Shift+5              │
│ Launch: Ctrl+Shift+M                │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ WORKSPACE 6: Notes, Chat, 2FA       │
│ → Obsidian (tiled)                  │
│ → Slack, Ente Auth (floating)       │
│ Shortcut: Ctrl+Shift+6              │
│ Launch: Ctrl+Shift+O (Obsidian)     │
│         Ctrl+Shift+S (Slack)        │
│         Ctrl+Shift+E (Ente Auth)    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ WORKSPACE 7: AI                     │
│ → Claude, ChatGPT (both floating)   │
│ Shortcut: Ctrl+Shift+7              │
│ Launch: Ctrl+Shift+A (Claude)       │
│         Ctrl+Shift+T (ChatGPT)      │
└─────────────────────────────────────┘
```

---

### SCRATCH (Workspaces 8-9) AND FLOATERS

```
┌─────────────────────────────────────┐
│ WORKSPACES 8-9: Unassigned          │
│ → Free space for whatever the day   │
│   needs; 10-12 are overflow         │
│ Shortcut: Ctrl+Shift+8 / 9          │
│ Overflow: Ctrl+Shift+0 (next),      │
│           Ctrl+Alt+0 (previous)     │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ NO HOME WORKSPACE                   │
│ → 1Password floats where opened, so │
│   its Touch ID prompt follows you   │
│ → Ghostty opens on the current      │
│   workspace                         │
│ Launch: Ctrl+Shift+P (1Password)    │
└─────────────────────────────────────┘
```

---

## ⚡ Quick Reference Card

### App Launchers (Print This!)

```
TERMINAL, BROWSERS, EDITOR
--------------------------
Ctrl+Shift+W  →  Warp (terminal, workspace 1)
Ctrl+Shift+X  →  Zen (personal browser, workspace 2)
Ctrl+Shift+C  →  Chrome (work browser, opens NEW window, workspace 3) 🆕
Ctrl+Shift+Z  →  Zed (editor, workspace 4)
Ctrl+Shift+V  →  VS Code (editor, workspace 4)

MAIL, NOTES, CHAT, AI
---------------------
Ctrl+Shift+M  →  Proton Mail (workspace 5)
Ctrl+Shift+O  →  Obsidian (notes/PKM, workspace 6)
Ctrl+Shift+S  →  Slack (workspace 6, floating)
Ctrl+Shift+E  →  Ente Auth (workspace 6, floating)
Ctrl+Shift+A  →  Claude (workspace 7, floating)
Ctrl+Shift+T  →  ChatGPT (workspace 7, floating)

UTILITIES
---------
Ctrl+Shift+P      →  1Password (floats on the current workspace)
Ctrl+Shift+Space  →  dotfiles menu (theme, toggles, launchers, update…)
Ctrl+Shift+Enter  →  Finder
Ctrl+Shift+R      →  Re-launch the whole startup session

BROWSER WINDOW CYCLING 🆕
-------------------------
Ctrl+Shift+N  →  Next Chrome window (all workspaces)
Ctrl+Shift+B  →  Previous Chrome window (all workspaces)
Alt+Shift+N   →  Next Zen window (all workspaces)
Alt+Shift+B   →  Previous Zen window (all workspaces)
```

### Workspace Switching

```
TERMINAL, BROWSERS, EDITOR
--------------------------
Ctrl+Shift+1  →  Terminal (Warp)
Ctrl+Shift+2  →  Personal Browser (Zen)
Ctrl+Shift+3  →  Work Browser (Chrome)
Ctrl+Shift+4  →  Code Editor (Zed/VS Code)

MAIL, NOTES, CHAT, AI
---------------------
Ctrl+Shift+5  →  Email (Proton Mail)
Ctrl+Shift+6  →  Notes, Chat, 2FA (Obsidian, Slack, Ente Auth)
Ctrl+Shift+7  →  AI (Claude, ChatGPT)

SCRATCH
-------
Ctrl+Shift+8  →  Free
Ctrl+Shift+9  →  Free
Ctrl+Shift+0  →  Cycle forward through overflow workspaces 10-12 (Ctrl+Alt+0 backward)

QUICK TOGGLE
------------
Ctrl+Shift+Tab  →  Toggle between last 2 workspaces ⭐
```

---

## 🚀 My Daily Workflows

### Morning Startup (Work Mode)

```bash
# Start work context (or Ctrl+Shift+R to relaunch the whole session at once)
Ctrl+Shift+3    # Chrome (check calendar, work docs)
Ctrl+Shift+4    # Zed or VS Code (open work project)
Ctrl+Shift+1    # Warp (start dev server)
Ctrl+Shift+6    # Slack (check messages)

# Now ready to work!
# Focus on workspace 4 (code editor)
Ctrl+Shift+4
```

### Work Development Flow

```bash
# The main workflow loop
Workspace 4 (Zed / VS Code)
  ↓
Ctrl+Shift+1 (Warp terminal)
  ↓
Run tests/server
  ↓
Ctrl+Shift+Tab (back to the editor)
  ↓
Write code
  ↓
Ctrl+Shift+Tab (back to Warp)
  ↓
Check output
  ↓
Repeat!

# Need to check docs?
Ctrl+Shift+3 (Chrome)
# Back to coding
Ctrl+Shift+4 (editor)

# Need password?
Ctrl+Shift+P (1Password floats right here)
# Back to work
Ctrl+Shift+Tab
```

### Evening Transition (Personal Mode)

```bash
# Switch to personal context
Ctrl+Shift+2    # Zen (personal browsing)
Ctrl+Shift+5    # Proton Mail (email)
Ctrl+Shift+4    # Zed (side project)
Ctrl+Shift+1    # Warp (personal terminal)
Ctrl+Shift+6    # Obsidian (journaling, notes)
```

### Writing/Note-Taking Flow

```bash
Ctrl+Shift+6    # Obsidian (writing)
Ctrl+Shift+2    # Zen (research)
Ctrl+Shift+Tab  # Toggle between them

# Quick capture in Obsidian
Ctrl+Shift+O    # Launch Obsidian if not open
Ctrl+Shift+6    # Go to Obsidian workspace
```

---

## 🧰 The dotfiles CLI in a Working Day

The window manager is half the setup; the other half is `dotfiles`, one command with a verb per job. `dotfiles menu` (or `Ctrl+Shift+Space`, which opens it in a Ghostty window) is the fzf tree over all of them, so nothing here has to be memorised.

### Start of the day

```bash
# The login notice already said "dotfiles: 3 commits, 2 brew upgrades…" in yellow if anything waits.
# .zshrc refreshes that once a day in a detached job; the shell only reads the cache.
dotfiles update available        # The same check, live: commits, brew upgrades, migrations, restarts
dotfiles update                  # Apply it all (pull → brew upgrade → relink → migrate → mise → restart what changed)
dotfiles toggle update-notice off   # If the login line annoys you

dotfiles agent usage             # Claude plan usage: the 5-hour session and the 7-day window, with reset times
# The sketchybar item shows the same ("5h 86% · 7d 25%"), yellow at 70%, red at 90%;
# click it for a notification. dotfiles toggle agent-usage off hides it.
```

### While coding

```bash
gwa feature/login                # New worktree + branch beside the repo (myapp--feature-login), mise-trusted, cd into it
# ... work, commit, push ...
gwr                              # From inside it: remove the worktree and delete the branch, after a y/N

dotfiles reminder 25             # "Your 25 minutes are up" as a macOS notification; a launchd agent, so it fires
dotfiles reminder 15 "Stand-up"  # even if you close the terminal or the Mac sleeps in between
dotfiles reminder show           # What is pending and when; `clear` cancels

fip nyc-dev 3000 5432            # SSH port forwards: localhost:3000 and :5432 answer from the remote box
lip                              # List active forwards
dip 3000                         # Stop one

compress ./dist                  # → dist.tar.gz next to it; decompress dist.tar.gz unpacks it here
```

### Shaping the desk

```bash
dotfiles webapp install Linear https://linear.app --workspace 3   # Chrome --app launcher with its own AeroSpace rule
dotfiles tui install Top btop                                       # A terminal program as a floating Ghostty app
dotfiles webapp remove --list                                       # What launchers exist on this machine
dotfiles theme aura              # Switch every app's palette; dotfiles theme bg next cycles the desktop picture
dotfiles font set "JetBrainsMono Nerd Font"   # One monospace family for every terminal and editor
dotfiles keys                    # The live keybinding cheatsheet (also service mode: Ctrl+Shift+; then K)
```

### When something is off

```bash
dotfiles restart sketchybar      # Or aerospace, borders: restart a component now
dotfiles health                  # Tools, symlinks, runtimes, services, pending migrations and restarts
dotfiles doctor                  # Fix the symlink and permission problems health found
dotfiles debug --print           # One report of the whole state; without --print it lands in
                                 # ~/.local/state/dotfiles/debug.log and on the clipboard, ready for an issue or an agent
```

---

## 🎨 App-Specific Tips

### VS Code (Workspace 4)

**Best setup:**
- Full-screen (`F11`)
- Split editor for multiple files
- Integrated terminal at bottom

**Toggle terminal:**
```
Ctrl+` (VS Code shortcut)
```

**Or use the dedicated terminal:**
```
Ctrl+Shift+1 (full Warp in workspace 1)
```

### Terminal (Workspace 1)

**Multiple sessions:**
- Split panes within Warp, or Zellij inside Ghostty
- Or open multiple terminal windows in same workspace (Ghostty has no home workspace: it opens where you are)

**Common commands:**
```bash
r           # bin/rails
rs          # bin/rails server
rc          # bin/rails console
rt          # bin/rails test
gst         # git status
```

### Obsidian (Workspace 6)

**Quick capture:**
```
Ctrl+Shift+O    # Launch/focus Obsidian
Cmd+N           # New note (Obsidian shortcut)
```

**Daily note:**
```
Ctrl+Shift+6    # Go to Obsidian
Cmd+D           # Open daily note (if configured)
```

### 1Password (floats on the current workspace)

**Quick access:**
```
Ctrl+Shift+P    # Launch 1Password
Cmd+\           # Autofill (1Password shortcut)
```

**Or use browser extension:**
- Chrome: Cmd+\ in workspace 3
- Zen: Cmd+\ in workspace 2

---

## 🔄 Context Switching Patterns

### Work ↔ Personal

```bash
# Working on work project
Workspaces 1, 3, 4 (Warp, Chrome, editor)

# Break time, check personal stuff
Ctrl+Shift+2 (Zen)

# Back to work
Ctrl+Shift+4 (editor)

# End of day, switch to personal project
Ctrl+Shift+4 (Zed)
Ctrl+Shift+1 (Warp)
```

### Deep Work Mode (Work)

```bash
# Focus on coding only
Ctrl+Shift+4    # Zed / VS Code
F11             # Full-screen

# Kill distractions
Ctrl+Shift+;    # Service mode
Backspace       # Close all other windows in workspace

# Only editor + Warp toggle
Ctrl+Shift+Tab  # Quick switch
```

### Deep Work Mode (Personal)

```bash
# Focus on side project
Ctrl+Shift+4    # Zed
F11             # Full-screen

# Or focus on writing
Ctrl+Shift+6    # Obsidian
F11             # Full-screen
```

### Multi-Browser Window Flow 🆕

```bash
# Use same browser in multiple workspaces

# Chrome's home is workspace 3, so a new window lands there wherever
# you pressed the chord; move it afterwards with Ctrl+Alt+<n>.

# Work research (workspace 3)
Ctrl+Shift+C    # Open NEW Chrome window (lands on workspace 3)
# Browse work docs, Rails guides, etc.

# Reference next to the editor (workspace 4)
Ctrl+Shift+C    # Open ANOTHER Chrome window
Ctrl+Alt+4      # Move it to the editor workspace
# Browse API docs beside the code

# Cycle between browser windows (no workspace switching!)
Ctrl+Shift+N    # Next Chrome window → jumps to workspace 3
Ctrl+Shift+N    # Next Chrome window → jumps to workspace 4
Ctrl+Shift+N    # Wraps around → back to workspace 3

# Same for Zen
Ctrl+Shift+X    # Open Zen (lands on workspace 2)
Cmd+N           # ANOTHER Zen window, then Ctrl+Alt+6 to park it by your notes
Alt+Shift+N     # Cycle through Zen windows
```

**Why this is powerful:**
- Same browser extensions in both work & personal contexts
- No need to remember which workspace has which tab
- Faster than `Ctrl+Shift+3` or `Ctrl+Shift+2` for switching
- Perfect for tutorials: docs in workspace 3, video in workspace 2

---

## 🎨 Common Window Layout Scenarios

### Scenario 1: Temporarily Maximize One Window

**Situation:** You have 2 apps side-by-side and want to temporarily focus on one, then go back.

**Current:** `[App A] [App B]` (side-by-side)

**Goal:** Maximize App A → Work → Back to side-by-side

#### Solution A: Accordion Layout (Recommended)

```bash
# 1. With App A focused, toggle accordion mode
Ctrl+Shift+,

# Now App A fills the screen

# 2. Do your work...

# 3. Switch to App B (it auto-fills the screen)
Ctrl+Shift+L

# 4. Toggle back to side-by-side
Ctrl+Shift+,
```

**How it works:**
- Accordion mode makes the focused window fill the workspace
- Switching focus automatically maximizes the new window
- Toggle off to return to tiles (side-by-side)

#### Solution B: Cycle Layouts

```bash
# 1. Cycle through layouts
Ctrl+Shift+/

# Cycles: tiles → horizontal → vertical → back to tiles
# Press until focused app fills screen

# 2. Do your work...

# 3. Cycle back to tiles (side-by-side)
Ctrl+Shift+/
```

#### Solution C: Reset Layout (Emergency)

```bash
# If stuck in any layout:
Ctrl+Shift+;    # Enter service mode
R               # Reset to default tiles
Esc             # Exit service mode

# Now you're back to side-by-side
```

---

### Scenario 2: Create Split Layouts (2 Top, 1 Bottom)

**Situation:** You have 3 apps side-by-side and want a custom split layout.

**Current:** `[App A] [App B] [App C]` (3 apps side-by-side)

**Goal:**
```
[App A] [App B]
[    App C     ]
```

#### Solution: Move Window Down

```bash
# 1. Focus the app you want on bottom (App C)
Ctrl+Shift+L    # Move focus right to App C
# or
Ctrl+Shift+H    # Move focus left to App C

# 2. Move App C down to create bottom row
Ctrl+Alt+J      # Move down

# Done! App C is now on bottom, A & B are side-by-side on top
```

#### Other Split Layout Patterns

**1 Left, 2 Right (stacked):**
```
[   A   ] [B]
[   A   ] [C]
```

```bash
# Focus App B or C, then:
Ctrl+Alt+L      # Move right (creates right column)
```

**1 Top, 2 Bottom:**
```
[    App A     ]
[App B] [App C]
```

```bash
# Focus App A, then:
Ctrl+Alt+K      # Move up (creates top row)
```

**2 Left, 1 Right:**
```
[A] [   C   ]
[B] [   C   ]
```

```bash
# Focus App C, then:
Ctrl+Alt+L      # Move right
# Then adjust as needed
```

#### Reverse Back to Side-by-Side

**Option 1: Reset layout**
```bash
Ctrl+Shift+;    # Service mode
R               # Reset to tiles
Esc             # Exit
```

**Option 2: Move window back**
```bash
# Focus the window you moved (App C), then:
Ctrl+Alt+K      # Move back up
# or
Ctrl+Alt+H      # Move back left
```

---

### Window Movement Shortcuts Reference

```
FOCUS WINDOW (Ctrl+Shift)
-----------------------------
Ctrl+Shift+H  →  Focus left
Ctrl+Shift+J  →  Focus down
Ctrl+Shift+K  →  Focus up
Ctrl+Shift+L  →  Focus right

MOVE WINDOW (Ctrl+Alt)
-----------------------------
Ctrl+Alt+H    →  Move left
Ctrl+Alt+J    →  Move down (creates bottom row)
Ctrl+Alt+K    →  Move up (creates top row)
Ctrl+Alt+L    →  Move right (creates right column)

RESIZE WINDOW
-----------------------------
Ctrl+Shift+-  →  Shrink (resize smart -50)
Ctrl+Shift+=  →  Grow (resize smart +50)

LAYOUT TOGGLES
-----------------------------
Ctrl+Shift+/  →  Cycle: tiles → horizontal → vertical
Ctrl+Shift+,  →  Cycle: accordion → horizontal → vertical

SERVICE MODE RESET
-----------------------------
Ctrl+Shift+;  →  Enter service mode
R             →  Reset layout (flatten workspace tree)
F             →  Toggle floating/tiling
Backspace     →  Close all windows except current
Esc           →  Reload config & exit service mode
```

---

### Pro Tips for Window Management

**1. Use Accordion for Focus Work**
```bash
# When you need full screen for one app:
Ctrl+Shift+,    # Toggle accordion
# Work on focused app
# Switch apps with Ctrl+Shift+H/J/K/L
# Each app auto-maximizes when focused
```

**2. Create Custom Layouts**
```bash
# Build your perfect layout using Ctrl+Alt+H/J/K/L
# Then stay in that workspace
# Aerospace remembers your layout per workspace
```

**3. Quick Reset When Lost**
```bash
# If layouts get messy:
Ctrl+Shift+; → R → Esc
# Instantly back to clean tiles
```

**4. Practice These Common Patterns**
- 2 side-by-side (default tiles)
- 1 focused (accordion mode)
- 2 top, 1 bottom (coding + terminal)
- 1 left, 2 right (editor + references)

---

## 🖥️ Multi-Monitor Workflow (BenQ Monitor + AirPlay TV)

### Overview: Your Multi-Monitor Setup

**Hardware**:
- 💻 **Laptop Screen** (Main display - built-in)
- 🖥️ **BenQ Monitor** (External via USB-C/HDMI)
- 📺 **TV** (AirPlay when connected)

**How It Works** (i3-style Independent Workspaces):
```
Each monitor shows ONE workspace at a time
You control which workspace shows on which monitor

Example:
Laptop Screen          BenQ Monitor
─────────────          ────────────
Workspace 4            Workspace 2
(Zed / VS Code)        (Zen)

You can change either monitor independently:
Ctrl+Shift+1  → Changes laptop to workspace 1
Ctrl+Shift+7  → Changes BenQ to workspace 7
```

**Key Concepts**:
- **Independent Control**: Each monitor can show any workspace (1-9)
- **Focus-Based Switching**: `Ctrl+Shift+1-9` changes workspace on the **focused monitor**
- **Default Behavior**: When you connect BenQ, it shows an empty workspace by default
- **Manual Control**: YOU decide what workspace shows on each monitor

---

### Understanding Independent Workspace Control

**Example: Setting Up Custom Layout**

```bash
# Start: Both monitors showing workspace 1
Laptop: Workspace 1       BenQ: Workspace 1

# You want: Workspace 2 on laptop, Workspace 3 on BenQ

Step 1: Setup laptop
Ctrl+Shift+2              # Laptop now shows workspace 2

Laptop: Workspace 2       BenQ: Workspace 1 (unchanged!)

Step 2: Setup BenQ
Alt+Shift+L               # Focus BenQ monitor
Ctrl+Shift+3              # BenQ now shows workspace 3

Laptop: Workspace 2       BenQ: Workspace 3 ✓

# Result: Each monitor shows different workspace!
```

**Key Point**: Workspace switching (`Ctrl+Shift+1-9`) only affects the **currently focused monitor**, not both monitors. This gives you complete flexibility!

---

### Scenario 1: Working with External Monitor (BenQ)

#### Setup
When you connect your BenQ monitor:
1. It becomes your "secondary" monitor
2. It starts showing an empty workspace (or the last workspace it showed)
3. You manually choose which workspaces to display on each monitor

#### Workflow Example: Coding Session with Dual Monitor

**Goal**: Code on laptop (workspace 4), have notes on BenQ (workspace 6)

```bash
# Setup laptop screen
Ctrl+Shift+4         # Switch laptop to workspace 4 (Zed / VS Code)

# Setup BenQ monitor
Alt+Shift+L          # Focus BenQ monitor
Ctrl+Shift+6         # Switch BenQ to workspace 6 (Obsidian)

# Now you have:
# Laptop: Workspace 4 (editor)
# BenQ:   Workspace 6 (Obsidian)

# Work between them
Ctrl+Shift+Tab       # Quick toggle between workspace 4 ↔ 6

# Or focus monitors directly
Alt+Shift+H          # Focus laptop (shows workspace 4)
Alt+Shift+L          # Focus BenQ (shows workspace 6)
```

#### Moving Windows Between Monitors

**Move individual window**:
```bash
# Have the editor open on laptop, want it on BenQ
Ctrl+Shift+Cmd+M     # Move focused window to next monitor

# Or be specific
Ctrl+Shift+Cmd+L     # Move window to right monitor (BenQ)
Ctrl+Shift+Cmd+H     # Move window back to left monitor (laptop)
```

**Move entire workspace**:
```bash
# Working in workspace 4 on laptop, want whole workspace on BenQ
Ctrl+Alt+Tab         # Move entire workspace 4 to BenQ
Ctrl+Alt+Tab         # Move back to laptop
```

---

### Scenario 2: AirPlay to TV (Third Monitor)

#### Setup
When you AirPlay to TV:
1. TV becomes a third monitor
2. You can cycle: Laptop → BenQ → TV → Laptop

#### Workflow Example: Presentation or Video

```bash
# Open browser with presentation
Ctrl+Shift+2         # Zen (personal browser)

# Move to TV for presentation
Ctrl+Alt+Tab         # Cycles through monitors
# First press: BenQ
# Second press: TV ✓

# Control from laptop while presenting
Alt+Shift+H          # Focus back to laptop
# Presentation stays on TV, you work on laptop

# When done, move workspace back
Ctrl+Alt+Tab         # Cycle back to BenQ or laptop
```

---

### Scenario 3: Laptop Only (No External Display)

#### What Happens?
When you disconnect external monitor:
- The workspaces it was showing move to the laptop screen
- All your windows preserved
- No manual rearrangement needed

#### Workflow
```bash
# At coffee shop (laptop only)
Ctrl+Shift+2         # Zen (now on laptop)
Ctrl+Shift+4         # Editor (still on laptop)
Ctrl+Shift+Tab       # Quick toggle between workspaces

# Back home, connect BenQ
# It comes up showing an empty workspace; pick what goes there ✓
```

---

### Complete Multi-Monitor Shortcuts Reference

```
MOVE ENTIRE WORKSPACE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ctrl+Alt+Tab         →  Move workspace to next monitor
                         (cycles: laptop → BenQ → TV → laptop)

MOVE INDIVIDUAL WINDOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ctrl+Shift+Cmd+M     →  Move window to next monitor (cycles)
Ctrl+Shift+Cmd+H     →  Move window to left monitor
Ctrl+Shift+Cmd+L     →  Move window to right monitor

FOCUS MONITOR (without moving windows)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Alt+Shift+M          →  Focus next monitor
Alt+Shift+H          →  Focus left monitor (laptop)
Alt+Shift+L          →  Focus right monitor (BenQ)

WORKSPACE SHORTCUTS (no forced monitor assignment)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ctrl+Shift+1-9       →  Show that workspace on the focused monitor
Ctrl+Shift+0         →  Overflow workspaces 10-12 on the focused monitor
```

---

### Common Multi-Monitor Workflows

#### Workflow 1: Code + Documentation

```bash
# Laptop: Zed / VS Code
Ctrl+Shift+4

# BenQ: Documentation/Browser
Ctrl+Shift+3

# Quick reference while coding
Alt+Shift+M          # Glance at docs on BenQ
Alt+Shift+H          # Back to coding on laptop
```

#### Workflow 2: Code + Terminal + Logs

```bash
# Laptop: editor + a Ghostty window (side by side in workspace 4)
Ctrl+Shift+4

# BenQ: Full-screen Warp with logs
Ctrl+Shift+1

# Watch logs on BenQ while coding on laptop
# No need to switch - both visible!
```

#### Workflow 3: Writing + Research

```bash
# Laptop: Obsidian for writing
Ctrl+Shift+6         # Opens on whichever monitor is focused

# If that was BenQ, move it to laptop for focused writing
Ctrl+Shift+Cmd+H     # Move Obsidian to laptop

# BenQ: Zen for research
Ctrl+Shift+2

# Write on laptop, research on BenQ simultaneously
```

#### Workflow 4: Presentation Mode (TV)

```bash
# Prepare on laptop
Ctrl+Shift+3         # Open presentation in Chrome

# Move to TV
Ctrl+Alt+Tab         # Move workspace to BenQ
Ctrl+Alt+Tab         # Move workspace to TV

# Control from laptop
Alt+Shift+H          # Focus laptop
Ctrl+Shift+6         # Open notes in workspace 6

# Presentation on TV, notes on laptop!
```

---

### Pro Tips for Multi-Monitor Setup

**1. Apps Auto-Assign, Monitors Do Not**
```bash
# Every app has a home workspace (aerospace.toml [[on-window-detected]]),
# so Ctrl+Shift+O always lands Obsidian on workspace 6.
# Which monitor shows workspace 6 is up to you: it opens on the focused one.
```

**2. Use Ctrl+Alt+Tab for Flexibility**
```bash
# Want workspace 4 on BenQ sometimes?
Ctrl+Shift+4         # Open workspace 4 (laptop)
Ctrl+Alt+Tab         # Move to BenQ for bigger screen

# Done? Move back
Ctrl+Alt+Tab         # Back to laptop
```

**3. Focus vs. Move**
```bash
# Alt+Shift = Focus only (look at other monitor)
# Ctrl+Shift+Cmd = Move windows (rearrange)
# Ctrl+Alt = Move entire workspaces (big changes)
```

**4. Monitor-Specific Layouts**
```bash
# Laptop: Prefer vertical splits (smaller screen)
# BenQ: Prefer horizontal splits (wider screen)
# TV: Full-screen single apps (viewing distance)
```

**5. Remember: Mouse Follows Focus**
```bash
# When you focus a monitor, mouse moves there automatically ✓
# on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
```

---

### Troubleshooting Multi-Monitor

**Problem: Workspace not on expected monitor**

```bash
# There is no forced assignment; a workspace shows where you last put it
aerospace list-workspaces --all --format '%{workspace} %{monitor-name}'

# Reload config
Ctrl+Shift+; → Esc

# Or use aerospace CLI
aerospace list-monitors
```

**Problem: Lost track of which monitor has which workspace**

```bash
# Quick check
aerospace list-workspaces --monitor focused

# Or just cycle through
Ctrl+Shift+1         # If it appears, it's visible
Ctrl+Shift+2         # Cycle through to find it
```

**Problem: Want different workspace assignments**

```bash
# Edit ~/.config/aerospace/aerospace.toml
# Add a [workspace-to-monitor-force-assignment] section (none exists today)
# Reload: Ctrl+Shift+; → Esc
```

---

### Your Optimal Multi-Monitor Setup

**Morning (Work Mode)**:
```
Laptop                    BenQ Monitor
━━━━━━━━━━━━━━━━━━━━     ━━━━━━━━━━━━━━━━━━━━
4. Zed / VS Code (coding) 3. Chrome (docs, testing)
1. Warp (commands, logs)  6. Obsidian + Slack (chat)
                          7. Claude / ChatGPT
```

**Evening (Personal Mode)**:
```
Laptop                    BenQ Monitor
━━━━━━━━━━━━━━━━━━━━     ━━━━━━━━━━━━━━━━━━━━
3. (Chrome closed)        2. Zen (browsing)
4. Zed (side project)     5. Proton Mail
1. Warp (personal)        6. Obsidian (writing)
```

**Presentation (with TV)**:
```
Laptop                    BenQ                  TV
━━━━━━━━━━━━━━━━━━━━     ━━━━━━━━━━━━━━━━     ━━━━━━━━━━━━
6. Notes/Control          (not used)            3. Presentation (Chrome)
```

---

## 📝 Mnemonic Guide (Remember Your Shortcuts)

### App Launchers (Letters Match Apps)

```
W → Warp
X → Zen (Z was taken by Zed)
C → Chrome
Z → Zed
V → VS Code (Visual Studio Code)
M → (Proton) Mail
O → Obsidian
S → Slack
E → Ente Auth
A → Claude (AI, Anthropic)
T → ChaTGPT
P → 1Password
R → Restore session
```

### Workspace Numbers (Logical Flow)

```
1-4  → Build (the tools you code with)
  1 → Terminal (Warp)
  2 → Personal browser (Zen)
  3 → Work browser (Chrome)
  4 → Editor (Zed / VS Code)

5-7  → Communicate and think
  5 → Mail
  6 → Notes, chat, 2FA
  7 → AI

8-9  → Scratch (nothing assigned; 10-12 overflow via Ctrl+Shift+0)
```

---

## 🎯 Optimization Tips

### 1. **Keep Work/Personal Separate**

**Don't:**
- ❌ Log into personal accounts in Chrome
- ❌ Mix work and personal tabs in the same browser
- ❌ Park work web apps in Zen

**Do:**
- ✅ Chrome = workspace 3 (work browsing only)
- ✅ Zen = workspace 2 (personal browsing only)
- ✅ Work web apps as their own launchers: `dotfiles webapp install <name> <url> --workspace 3`
- ✅ Warp on workspace 1 for both; the git identity is per directory (`work-setup`), not per terminal

### 2. **Use the Toggle (Ctrl+Shift+Tab)**

**Most common patterns:**
```
Code ↔ Terminal
  Workspace 4 ↔ Workspace 1

Browse ↔ Code
  Workspace 3 ↔ Workspace 4 (work)
  Workspace 2 ↔ Workspace 4 (personal)

Notes ↔ Browser
  Workspace 6 ↔ Workspace 2 (research + write)
```

### 3. **Launch Apps in Their Workspace**

**Workflow:**
```bash
# Every app has a home workspace, so the launcher does the placing:
Ctrl+Shift+C    # Launch Chrome; the window lands on workspace 3 wherever you are

# Even better:
Ctrl+Shift+3    # Just switch (Chrome already open)

# Want it somewhere else this once?
Ctrl+Alt+4      # Move the focused window to workspace 4
```

### 4. **Muscle Memory Training**

**Week 1: Learn numbers**
```
Ctrl+Shift+1/3/4  (terminal, work browser, editor)
Ctrl+Shift+2/5/6  (personal browser, mail, notes)
```

**Week 2: Add app launchers**
```
Ctrl+Shift+W (Warp)
Ctrl+Shift+C (Chrome)
Ctrl+Shift+Z (Zed)
Ctrl+Shift+X (Zen)
```

**Week 3: Master toggle**
```
Ctrl+Shift+Tab (most used shortcut!)
```

---

## 🔧 Customization

### Adding More Apps

Edit `~/.config/aerospace/aerospace.toml`:

```toml
# Example: Add Spotify (S is Slack and T is ChatGPT already; Y is free)
# desc: Launch Spotify
ctrl-shift-y = '''exec-and-forget open -a "Spotify"'''
```

Then reload and regenerate the cheatsheet (`dotfiles keys --lint` catches a chord bound twice):
```bash
Ctrl+Shift+; → Esc
# or
aerospace reload-config
dotfiles keys --update
```

A web app or terminal program needs no TOML at all: `dotfiles webapp install Linear https://linear.app --workspace 3` and `dotfiles tui install Top btop` create launchers with their own AeroSpace rules.

### Changing Workspace Assignments

**Current:**
- 1-4: Terminal, personal browser, work browser, editor
- 5-7: Mail, notes/chat/2FA, AI
- 8-9: Scratch (10-12 overflow)

**Want different layout?**
Edit this file and reorganize!

---

## 📊 My Setup Summary

### Apps I Use

**Work:**
- 🌐 Chrome (browser)
- 💻 Zed, VS Code (editors)
- ⚡ Warp (terminal), Ghostty (terminal, no home workspace)
- 💬 Slack (communication)

**Personal:**
- 🦊 Zen (browser)
- 📧 Proton Mail (email)
- 📝 Obsidian (PKM)
- 🤖 Claude, ChatGPT (AI)

**Utilities:**
- 🔐 1Password (passwords), Ente Auth (2FA)
- 🚀 dotfiles menu (Ctrl+Shift+Space)

### My Workspace Organization

```
BUILD               COMMUNICATE, THINK          SCRATCH
────────────────    ─────────────────────────   ─────────
1. Warp             5. Proton Mail              8. (free)
2. Zen              6. Obsidian, Slack, Ente    9. (free)
3. Chrome           7. Claude, ChatGPT
4. Zed / VS Code    (1Password floats anywhere)
```

### Most Used Shortcuts

```
Ctrl+Shift+1/3/4  →  Terminal, work browser, editor
Ctrl+Shift+2/5/6  →  Personal browser, mail, notes
Ctrl+Shift+Tab    →  Quick toggle ⭐
Ctrl+Shift+W      →  Warp
Ctrl+Shift+C      →  Chrome
Ctrl+Shift+Z      →  Zed
Ctrl+Shift+X      →  Zen
Ctrl+Shift+M      →  Proton Mail
Ctrl+Shift+O      →  Obsidian
Ctrl+Shift+P      →  1Password
Ctrl+Shift+Space  →  dotfiles menu
```

---

## 🎓 Learning Path

### Day 1: Work Context
```
□ Learn Ctrl+Shift+1/3/4 (terminal, work browser, editor)
□ Practice Ctrl+Shift+W (Warp)
□ Practice Ctrl+Shift+C (Chrome)
□ Practice Ctrl+Shift+Z (Zed) and Ctrl+Shift+V (VS Code)
```

### Day 2: Personal Context
```
□ Learn Ctrl+Shift+2/5/6 (personal browser, mail, notes)
□ Practice Ctrl+Shift+X (Zen)
□ Practice Ctrl+Shift+M (Proton Mail)
□ Practice Ctrl+Shift+O (Obsidian)
```

### Day 3: Toggle Mastery
```
□ Practice Ctrl+Shift+Tab 50 times
□ Code ↔ Terminal workflow
□ Browser ↔ Code workflow
```

### Week 1: Muscle Memory
```
□ Use ONLY keyboard for workspaces
□ No mouse for window switching
□ Track how many times you forget
```

---

## 🎯 Success Metrics

Track your progress:

```
□ Day 1:  Launched apps with keyboard shortcuts
□ Day 3:  Work/Personal separation feels natural
□ Day 7:  Shortcuts are muscle memory
□ Day 14: Never use mouse for windows
□ Day 21: Teaching someone else your setup
□ Day 30: Can't imagine any other way
```

---

**This is YOUR personalized setup!** 🎉

**Config location:** `~/.config/aerospace/aerospace.toml`

**Quick test:**
```bash
Ctrl+Shift+W    # Should launch Warp
Ctrl+Shift+1    # Should go to workspace 1
Ctrl+Shift+C    # Should launch Chrome on workspace 3
Ctrl+Shift+Z    # Should launch Zed on workspace 4
Ctrl+Shift+X    # Should launch Zen on workspace 2
Ctrl+Shift+M    # Should launch Proton Mail on workspace 5
```

**Everything working?** Start building that muscle memory! 💪
