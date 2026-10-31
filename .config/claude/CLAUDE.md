# Global instructions

Auto memory is off, so past notes stay out of context until you look them up. Look them up when they matter.

## Past context

Search first when a task touches an earlier decision, a past bug, or anything already tried. Skip this for self-contained work.

- Notes: `rg -il '<word>' ~/.claude/projects/<slug>/memory/`, then read the matching file. The slug is the working directory with every non-alphanumeric character replaced by `-`, so `/Users/anjan/code/RED` is `-Users-anjan-code-RED`. Notes that span projects are under `-Users-anjan-code`. A folder's `MEMORY.md` is its index and can run to 17K characters, so search it rather than read it whole.
- MemPalace: load `mempalace_search` with ToolSearch. `mempalace_list_wings` names the wings; RED's is `rails_error_dashboard`. It was last mined 2026-10-22, so a miss says nothing about recent work. Check the notes, `git log` and the repo as well.
- Before committing in a repo, run that search for `commit` in its notes. Some repos have rules about what stays out of git.
- Asked to remember something: write one file in that project's memory folder and add one line to its `MEMORY.md`.

## Turned off

- Browser tools exist only in a session started with `claude --chrome`.
- These skills start only when I type them, so ask me to: `/claude-api`, `/code-review`, `/dataviz`, `/init`, `/loop`, `/run`, `/schedule`, `/security-review`, `/simplify`.
- Claude API or Anthropic SDK work: ask me to run `/claude-api` first. Don't state model ids, prices or parameters from recollection.
- Bodhikit is on only in my learning folder. Elsewhere it needs `/plugin`, then `/reload-plugins`.
- The Artifact and Workflow tools are off in settings. Say so if a task needs one.

## Always

- GitHub is the only host. Codeberg was abandoned in August 2026: never clone from it or push to it.
- Related repos sit under plain non-git parent folders.
- Before cloning a repo, check `phased-out-repos.md` in the `-Users-anjan-code` notes.
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
