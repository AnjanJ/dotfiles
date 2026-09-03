# AI-Augmented Shell

A modern shell needs AI tooling. This setup wires LLMs into the daily flow without taking over the terminal.

## Quick reference

| Tool | What it does | Trigger |
|------|--------------|---------|
| **Claude Code** | Full coding agent (CLI + IDE) | `claude` or VS Code/Zed extension |
| **GitHub Copilot CLI** | Suggests/explains shell commands | `ghcs` / `ghce` |
| **llm** | Pipe text → LLM, get text back | `\| llm "..."` |
| **ollama** | Run LLMs locally (offline + private) | `ollama run <model>` or via `llm` |
| **Gemini CLI** | Google's terminal LLM | `gemini` |
| **explain-last** | "What did that command do?" | `explain-last` |
| **`a`** | Launches whichever agent `dotfiles default-agent` names (Claude Code unless changed) | `a` |

> **Why `llm` and not `mods`?** Earlier versions of this setup used [`mods`](https://github.com/charmbracelet/mods), but Charmbracelet sunset that project on 2026-03-09 (issues like #561 — Ollama streaming output looping — were never patched). Simon Willison's [`llm`](https://llm.datasette.io/) is the modern replacement: actively maintained, plugin-based, works cleanly with Ollama via `llm-ollama`.

## `llm` — your everyday LLM pipe

`llm` reads stdin and prints the model's response. The unix way to use AI.

```bash
# Diagnose an error
cat /var/log/system.log | tail -50 | llm "anything concerning here?"

# Generate a commit message from your diff
git diff --staged | llm -s "write a concise conventional-commit message; output only the message"

# Convert a CSV to JSON
cat data.csv | llm "convert to JSON, keep types"

# Refactor on the fly
cat script.sh | llm "rewrite this in idiomatic Python 3.12, keep behavior identical"

# One-shot questions
llm "explain SIGPIPE in 3 sentences"
```

The `-s` flag sends the next argument as a system prompt. The `-m` flag picks a specific model. `-c` continues the previous conversation. `--no-stream` returns the full response at once instead of streaming.

**First-time setup** (already done by `install.sh`):

```bash
# Plugin for local Ollama models (one-time)
llm install llm-ollama

# Optional: add hosted-API plugins
llm install llm-anthropic llm-gemini

# Set a default model — qwen2.5-coder:7b is local, fast, private
# (Each tool has its own model setting; see "Which model where" below.)
llm models default qwen2.5-coder:7b

# Set API keys when you want hosted models
llm keys set openai           # paste key when prompted
llm keys set anthropic
```

**Switch models per call:**

```bash
llm -m qwen2.5-coder:7b "..."   # local, default
llm -m gpt-4o "..."             # OpenAI, hosted
llm -m claude-sonnet-4-5 "..."  # Anthropic, hosted
llm models                      # list everything available
```

**Templates** save reusable system prompts:

```bash
llm "you are a senior engineer reviewing code; be terse" --save reviewer
cat src/auth.rb | llm -t reviewer

llm 'you write conventional-commit messages: subject under 72 chars, body explains why' --save commit
git diff --staged | llm -t commit
```

Templates live at `~/Library/Application Support/io.datasette.llm/templates/`.

**Continue a conversation:**

```bash
llm "what is currying?"
llm -c "give me a JS example"   # remembers the previous answer
llm logs                         # see history
```

## `gh copilot` — built into `gh`

Already comes with `gh ≥ 2.49`. Two subcommands, two aliases:

```bash
ghcs "find files larger than 100MB modified in the last week"
# Suggests: find . -type f -size +100M -mtime -7

ghce "git rebase --interactive HEAD~5"
# Explains the command in plain English
```

Requires an active GitHub Copilot subscription. First run prompts for auth.

## `ollama` — local LLMs (offline + private)

Local models run on your Mac. No data leaves your machine. Great for:

- Sensitive code/logs you can't send to a hosted API
- Offline work (flight, travel)
- Cheap experimentation without per-token costs
- Latency-sensitive use cases

**Architecture:**

- **Ollama** is the *server* — it loads `.gguf` weights, runs them on Apple Silicon GPU, exposes an HTTP API at `localhost:11434`. Internally it uses [llama.cpp](https://github.com/ggerganov/llama.cpp).
- **`llm` + `llm-ollama` plugin** is the *client* — pipes stdin to the server. You don't talk to ollama directly except to `pull` / `list` / `rm` models.

**Setup:**

```bash
# Pull a coding-tuned model (~5GB) — recommended default
ollama pull qwen2.5-coder:7b

# List what you have on disk
ollama list

# Tell `llm` about it (rescan plugin registrations)
llm models | grep -i ollama
```

**Use directly (occasional):**

```bash
ollama run qwen2.5-coder:7b "write a bash function that retries N times"
```

**Use via `llm` (the daily driver):**

```bash
cat error.log | llm -m qwen2.5-coder:7b "explain"
# Or, if you set qwen2.5-coder:7b as default:
cat error.log | llm "explain"
```

**Recommended models** (download once, use forever):

| Model | Size | Best for |
|-------|------|----------|
| `qwen2.5-coder:7b` | 4.7 GB | **Recommended default.** Code review, refactoring, explanations |
| `qwen2.5-coder:14b` | 9 GB | Stronger code reasoning, larger refactors |
| `qwen3:14b` | ~9 GB | General reasoning / harder thinking tasks (when 7b isn't enough) |
| `llama3.1:8b` | 4.7 GB | General Q&A, summarization |
| `nomic-embed-text` | 274 MB | Embeddings (RAG, semantic search) |

> Two-model strategy: keep `qwen2.5-coder:7b` as default for fast coding tasks, and a larger general model (e.g. `qwen3:14b`) for harder reasoning. Switch per call: `llm -m qwen3:14b "..."`.

## `explain-last` — instant context

Custom function in `.zshrc-terminal-enhancements`. Pipes your last shell command through `llm`:

```bash
$ find . -name "*.rb" -mtime -1 -exec rg -l "TODO" {} \;
# ...output...

$ explain-last
# llm explains what the find/rg pipeline does
```

## Picking the right tool

- **"I need a coding agent that can edit my files."** → Claude Code
- **"I forgot the syntax for X."** → `ghcs "X"`
- **"What does this regex/pipe do?"** → `ghce "..."` or `explain-last`
- **"Process this stdin and give me text back."** → `llm`
- **"I'm offline / this is sensitive."** → ollama via `llm` (default), or `ollama run` directly
- **"I want a chat-style interface."** → Claude Code app, Perplexity, or `llm chat`

## Claude usage in the menu bar

sketchybar shows `5h 86% · 7d 25%`: how full the 5-hour session window and the 7-day window of the Claude plan are. White below 70%, yellow from 70%, red from 90%, grey when the last fetch failed and the cached figure is showing. The 7-day figure is the fullest of the weekly limits (all models, or a per-model one), because whichever fills first is the one that blocks. Click the item for a notification with the reset times, or ask the terminal:

```bash
dotfiles agent usage             # Session (5h)  86%  resets 10:19 (in 1h 12m) ...
dotfiles agent usage --json      # the same, for scripts
dotfiles agent usage --refresh   # ignore the cache
dotfiles agent usage --max-age 300   # accept a cache up to 300 s old (default 60)
dotfiles toggle agent-usage off  # drop the item (then: dotfiles restart sketchybar)
```

The figures come from the endpoint behind Claude Code's own `/usage` screen, read with the token Claude Code keeps in the keychain. The token is never refreshed or sent anywhere else, and the reply is cached for a minute in `~/.cache/dotfiles/agent-usage.json`. The item hides itself when there is no Claude Code login. For scripts, the exit code says why there is no output: 0 with data, 2 when no Claude Code login is found, 3 when the endpoint could not be reached and nothing is cached.

## Agents know this setup

`agents/skills/dotfiles/` is a skill for Claude Code (symlinked to `~/.claude/skills/dotfiles`) that explains where every config lives, how theming works, what is generated and must not be edited, and which `dotfiles` commands are safe to run. The same directory is also linked to `~/.agents/skills/dotfiles`, `~/.codex/skills/dotfiles` and `~/.gemini/config/skills/dotfiles`, each only when its parent (`~/.agents`, `~/.codex`, `~/.gemini/config`) already exists (`DOTFILES_OPTIONAL_LINKS` in `scripts/symlink-map.sh`), so Codex and Gemini agents read the same guide without the install creating directories for tools you do not use. Ask Claude to "make the accent colour purple" or "add a shortcut for Finder" and it will edit the right source file, re-render, and validate. Contributor conventions for the repo itself are in `AGENTS.md` (loaded by `CLAUDE.md`).

`dotfiles default-agent [claude|oclaude|gemini|copilot|llm]` picks which agent the `a` shell function launches; the choice lives in `~/.local/state/dotfiles/default-agent` and each agent runs with a scoped permission mode (`--permission-mode auto` for Claude Code, `--approval-mode auto_edit` for Gemini), matching `"defaultMode": "auto"` in Claude Code's settings. Those settings are the repo's `.config/claude/settings.json`, symlinked to `~/.claude/settings.json` by `scripts/symlink-map.sh`; the two paths are the same file.

`oclaude` runs Claude Code against Ollama: `ollama launch claude --model <model> -- --permission-mode auto`, so it uses the same permission mode (add `--dangerously-skip-permissions` yourself for a run that needs it) and any other argument is passed through to `claude`. With no flag the model is `glm-5.2:cloud`. `-m <model>` names one directly; a bare `-m` opens a numbered picker that lists the hard-coded cloud models first (`glm-5.3:cloud`, `glm-5.2:cloud`, `kimi-k3:cloud`, `deepseek-v4-pro:cloud`), then the preferred local models `qwen3.8-cc:27b` and `qwen3.8:27b` when `ollama list` has them, then everything else `ollama list` reports; Enter takes the first entry and `q` cancels. `oq` is the quick, non-agent path: `ollama run qwen3.8:27b --think=false`, thinking off for speed, with your arguments appended.

## Which model where

Each tool picks its own model, on purpose: small and fast for one-shot shell use, larger for editor agents.

| Tool | Setting | Model |
|------|---------|-------|
| `llm` (shell, `explain-last`) | `.config/llm/default_model.txt` | `qwen2.5-coder:7b` |
| `oq` (quick chat, no thinking) | `.zshrc` | `qwen3.8:27b` |
| `oclaude` (Claude Code via Ollama) | `.zshrc` (`-m`, or the picker) | `glm-5.2:cloud` by default; any Ollama cloud or installed local model |
| Zed agent panel (`default_model`) | `.config/zed/settings.base.json` | `deepseek-v4-pro` (DeepSeek, cloud; thinking on, effort high) |
| Zed inline assistant (`inline_assistant_model`) | `.config/zed/settings.base.json` | `qwen3-coder:30b` (local); alternatives offered: `qwen2.5-coder:7b-base`, Claude via zed.dev |
| Zed commit messages / thread summaries | `.config/zed/settings.base.json` | `qwen2.5-coder:7b-base` (local) |
| Claude Code | `.config/claude/settings.json` (= `~/.claude/settings.json`) | `claude-fable-5-1[1m]`: Claude Fable 5.1 with the 1M context |
