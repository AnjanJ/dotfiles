# Sample hooks

One `<event>.d/<name>.sample` per event, copied (never overwritten) into `~/.config/dotfiles/hooks/` by `install.sh`, `dotfiles doctor` and `dotfiles hook --seed`. A sample does nothing until you drop the `.sample` suffix; `dotfiles hook install <event> <file>` adds a script of your own. `bin/dotfiles-hook --help` lists the events and their arguments.
