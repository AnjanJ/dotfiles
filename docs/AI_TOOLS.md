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
