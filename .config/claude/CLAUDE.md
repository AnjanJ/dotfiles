# Global instructions

Auto memory is off and there are no memory files. Past notes and conversations live in MemPalace, so look them up when they matter.

## Past context

Search first when a task touches an earlier decision, a past bug, or anything already tried. Skip this for self-contained work.

- Rules and decisions: load `mempalace_search` with ToolSearch and use a short topic query with the project's `wing` and `room: "general"`, where the old notes live. Leave `room` off to search conversations. `mempalace_list_wings` names the wings; RED's is `rails_error_dashboard`.
- Exact word or error string: `sqlite3 -readonly ~/.mempalace/palace/chroma.sqlite3 "select string_value from embedding_metadata where key='chroma:document' and string_value like '%<word>%' limit 5"`. Semantic search misses details deep inside a note.
- MemPalace was last mined 2026-11-01 and nothing is scheduled, so a miss says nothing about recent work. Check `git log` and the repo as well.
- Before committing in a repo, search that wing's `general` room for `commit rules`. Some repos have rules about what stays out of git.
- Asked to remember something: `mempalace_add_drawer` in the project's wing, room `general`.

## Turned off

- Browser tools exist only in a session started with `claude --chrome`.
- These skills start only when I type them, so ask me to: `/claude-api`, `/code-review`, `/dataviz`, `/init`, `/loop`, `/run`, `/schedule`, `/security-review`, `/simplify`.
- Claude API or Anthropic SDK work: ask me to run `/claude-api` first. Don't state model ids, prices or parameters from recollection.
- Bodhikit is on only in my learning folder. Elsewhere it needs `/plugin`, then `/reload-plugins`.
- Shipkit is on only in projects whose `.claude/settings.local.json` enables it. Elsewhere it needs `claude-ship`.
- The Artifact and Workflow tools are off in settings. Say so if a task needs one.

## Always

- GitHub is the only host. Codeberg was abandoned in August 2026: never clone from it or push to it.
- Related repos sit under plain non-git parent folders.
- Before cloning a repo, search MemPalace for `phased-out repos` in wing `code`.
- Never uninstall or disable bodhikit, shipkit, shipkit-workflows or mempalace unless I ask.
- SSH keys come from the 1Password agent.
- Never run `osascript` against an application. It waits on a macOS permission dialog and hangs the session. `display notification` is fine.
- Grep before repeating a universal claim such as "only X does Y", even when an agent said it.
- Open a resource's page and confirm title, author and year before adding it to a list. Anything you can't open is marked "not verified".

## Replies

- Asking me to decide: one numbered paragraph per item, saying what it is, what you checked, your recommendation and what "yes" does. End with "reply 'yes to all', or tell me which to skip".
- Reviewing my answers: a verdict per item first (correct, incorrect, partly correct), then why, then anything further.
- Each reply stands alone: restate the question or code it discusses instead of pointing to an earlier message. When teaching, share complete files.

## Projects

- RED: never close an issue, the reporter does. Commits and PRs say `Refs #N`, never Closes, Fixes or Resolves. Never merge the release PR without a yes. `ROADMAP.md` status goes stale, so check the real state.
- bodhikit: plan first, then one commit per issue after `dev/check.sh` passes. No push.
- dotfiles: one atomic commit per item on a branch, then a fast-forward merge. The repo is public, so keep private project names and personal details out of it.
