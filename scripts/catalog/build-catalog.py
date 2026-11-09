import re, csv, os, datetime, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
META = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'meta')

BF = os.path.join(ROOT, 'Brewfile')
OUT = os.path.join(ROOT, 'docs', 'PACKAGE_CATALOG.md')

def load(p, key=0):
    d = {}
    if os.path.exists(p):
        for r in csv.reader(open(p, encoding='utf-8'), delimiter='\t'):
            if r and len(r) > key: d[r[key]] = r
    return d

fm = load(os.path.join(META,'formula_meta.tsv')); cm = load(os.path.join(META,'cask_meta.tsv'))
tm = load(os.path.join(META,'tap_meta.tsv')); vm = load(os.path.join(META,'vscode_meta.tsv')); mm = load(os.path.join(META,'mas_meta.tsv'))

# Verified from local .app bundles — Apple's lookup API returns nothing for these IDs.
MAS_FALLBACK = {
 '1319778037': ('iStat Menus', 'Bjango'),
 '409203825':  ('Numbers', 'Apple'),
 '6714467650': ('Perplexity', 'Perplexity AI'),
}

GROUP_TITLES = {
 'taps':'Taps','core':'Core CLI','editors':'Editors & Terminals',
 'window-mgmt':'Window Management','terminal-tools':'Terminal Tools','ai':'AI Tooling',
 'databases':'Databases','cloud-deploy':'Cloud & Deploy','media':'Media',
 'communication':'Communication','productivity':'Productivity','work':'Work',
 'languages':'Languages','browsers':'Browsers','utilities':'Utilities',
 'extras':'Extras','fonts':'Fonts','vscode-ext':'VS Code Extensions',
}

# What each tap is actually FOR, and which of OUR packages it supplies.
# Provenance verified against INSTALL_RECEIPT.json / `brew info --json=v2`,
# not guessed. Taps marked REDUNDANT ship nothing we use — their formulae
# have since been absorbed into homebrew/core.
TAP_INFO = {
 'antoniorodr/memo':      "Supplies `memo` (Apple Notes/Reminders CLI)",
 'charmbracelet/tap':     "Charm's tools — supplies `freeze` (code-screenshot generator)",
 'cloudflare/cloudflare': "⚠️ REDUNDANT — `cloudflared` now ships in homebrew/core",
 'felixkratz/formulae':   "Supplies `sketchybar` (menu bar) and `borders` (window highlights)",
 'heroku/brew':           "⚠️ REDUNDANT — `heroku` now ships in homebrew/core",
 'hmbown/deepseek-tui':   "⚠️ Supplies nothing in this Brewfile — safe to drop",
 'jorgerojas26/lazysql':  "⚠️ REDUNDANT — `lazysql` now ships in homebrew/core",
 'nikitabobko/tap':       "Supplies the `aerospace` cask (tiling window manager)",
 'openclaw/tap':          "Supplies `wacli` (WhatsApp CLI) and `goplaces`",
 'render-oss/render':     "⚠️ REDUNDANT — `render` now ships in homebrew/core",
 'steipete/tap':          "Peter Steinberger's macOS CLIs — supplies `bird`, `gifgrep`, `imsg`, `peekaboo`, `remindctl`, `sag`, `songsee`",
 'supabase/tap':          "⚠️ REDUNDANT — `supabase` now ships in homebrew/core",
 'yakitrak/yakitrak':     "Supplies `obsidian-cli` (drive Obsidian from the shell)",
}

# Homebrew ships no `desc` for font casks, so they would render blank.
# The useful fact is which ones this setup actually REFERENCES, verified by
# grepping the configs. File names only: line numbers went stale before.
FONT_INFO = {
 'font-fira-code':                "**IN USE** — the default family `dotfiles font` renders into Ghostty, WezTerm, Zed and VS Code (`bin/dotfiles-font`)",
 'font-fira-code-nerd-font':      "**IN USE** — sketchybar icons and labels (`.config/sketchybar/sketchybarrc`)",
 'font-jetbrains-mono':           "**IN USE** — Zed's terminal font (`.config/zed/settings.base.json`)",
 'font-jetbrains-mono-nerd-font': "Optional family for `dotfiles font set`; no config uses it by default",
 'font-symbols-only-nerd-font':   "**IN USE** — WezTerm's icon fallback (`.config/wezterm/wezterm.lua`); required for glyphs",
 'font-ibm-plex-mono':            "E-ink reading font (sturdy stems, open apertures, per the Brewfile); not referenced by any config here",
 'font-bitter':                   "E-ink reading font (per the Brewfile); not referenced by any config here",
 'font-literata':                 "Ebook reading font (per the Brewfile); not referenced by any config here",
}
FONT_DEFAULT = "Font cask; not referenced by any config here"

groups, cur = [], None
for line in open(BF, encoding='utf-8'):
    line = line.rstrip('\n')
    g = re.match(r'^# @group (\S+)', line)
    if g:
        cur = {'name': g.group(1), 'items': []}; groups.append(cur); continue
    m = re.match(r'^(tap|brew|cask|mas|vscode) "([^"]+)"(.*)$', line)
    if m and cur: cur['items'].append((m.group(1), m.group(2), m.group(3)))

# --fetch: add metadata for packages that have none, from the same sources
# the existing rows came from (`brew info --json=v2`, each VS Code
# extension's local package.json). Rows are appended with CRLF endings like
# the rest of the files. Anything it cannot find stays blank, and --check
# names it.
def fetch_missing():
    import glob, json, subprocess
    def brew_json(args):
        try:
            out = subprocess.run(['brew', 'info', '--json=v2'] + args, capture_output=True, text=True, timeout=120).stdout
            return json.loads(out) if out.strip() else {}
        except (OSError, ValueError, subprocess.SubprocessError):
            return {}
    def append(fname, row):
        with open(os.path.join(META, fname), 'a', encoding='utf-8', newline='') as f:
            f.write('\t'.join(row) + '\r\n')
    added = []
    for g in groups:
        for kind, name, rest in g['items']:
            short = name.split('/')[-1]
            if kind == 'brew' and short not in fm and short not in tm:
                d = (brew_json(['--formula', name]).get('formulae') or [{}])[0]
                if d.get('desc') or d.get('homepage'):
                    row = [short, d.get('desc') or '', d.get('homepage') or '']
                    append('tap_meta.tsv' if '/' in name else 'formula_meta.tsv', row)
                    (tm if '/' in name else fm)[short] = row; added.append(name)
            elif kind == 'cask' and short not in cm:
                d = (brew_json(['--cask', name]).get('casks') or [{}])[0]
                if d.get('desc') or d.get('homepage'):
                    row = [short, d.get('desc') or '', d.get('homepage') or '']
                    append('cask_meta.tsv', row); cm[short] = row; added.append(name)
            elif kind == 'vscode' and name.lower() not in vm:
                found = sorted(glob.glob(os.path.expanduser(f'~/.vscode/extensions/{name.lower()}-*/package.json')))
                if found:
                    try:
                        m = json.load(open(found[-1], encoding='utf-8'))
                    except (OSError, ValueError):
                        continue
                    row = [name.lower(), m.get('displayName') or '', m.get('description') or '']
                    append('vscode_meta.tsv', row); vm[name.lower()] = row; added.append(name)
    for a in added:
        print('metadata added:', a)

def md_escape(s):
    return (s or '').replace('|', '\\|').strip()

def info(kind, name, rest):
    short = name.split('/')[-1]
    if kind == 'brew':
        r = fm.get(short) or tm.get(short)
        if r: return md_escape(r[1]), r[2]
    elif kind == 'cask':
        r = cm.get(short)
        desc, url = (md_escape(r[1]), r[2]) if r else ('', '')
        if short.startswith('font-') and not desc:
            desc = FONT_INFO.get(short, FONT_DEFAULT)
        return desc, url
    elif kind == 'vscode':
        r = vm.get(name.lower())
        if r:
            return md_escape(r[2] or r[1]), f"https://marketplace.visualstudio.com/items?itemName={name}"
    elif kind == 'mas':
        mid = re.search(r'id:\s*(\d+)', rest)
        mid = mid.group(1) if mid else ''
        r = mm.get(mid)
        if r and not r[1].startswith(('NOT_FOUND','ERR')):
            return md_escape(f"{r[1]} — by {r[2]}"), r[3]
        if mid in MAS_FALLBACK:
            nm, sel = MAS_FALLBACK[mid]
            return md_escape(f"{nm} — by {sel}"), f"https://apps.apple.com/app/id{mid}"
        return '', f"https://apps.apple.com/app/id{mid}" if mid else ''
    elif kind == 'tap':
        return (TAP_INFO.get(name, 'Third-party formula repository'),
                f"https://github.com/{name.split('/')[0]}/homebrew-{name.split('/')[-1]}")
    return '', ''

if '--fetch' in sys.argv[1:]:
    fetch_missing()

now = datetime.date.today().isoformat()
L = []
A = L.append
A('# Package Catalog')
A('')
A(f'> Every package `install.sh` installs, grouped exactly as in the [Brewfile](../Brewfile).')
A('')
A('**Descriptions and links are machine-generated from authoritative sources, not written by hand:**')
A('')
A('| Type | Source |')
A('|---|---|')
A('| Formulae / casks | `brew info --json=v2` (Homebrew\'s own `desc` + `homepage`) |')
A('| VS Code extensions | each extension\'s local `package.json` manifest |')
A('| App Store apps | Apple iTunes Lookup API (`trackName`, `sellerName`, `trackViewUrl`) |')
A('| Taps | Which packages in *this* Brewfile each tap supplies, resolved from install receipts |')
A('| Fonts | Whether the font is referenced by a config here, with the file:line that names it |')
A('')
A('Homebrew ships no description for taps or font casks, so those two columns state something')
A('more useful instead: what the tap actually gives you, and whether a font is really in use.')
A('Taps flagged **REDUNDANT** supply nothing you use — their formulae moved into homebrew/core.')
A('')
A(f'Regenerate after editing the Brewfile: `python3 scripts/catalog/build-catalog.py` · last built {now}')
A('')
A('## Contents')
A('')
for g in groups:
    t = GROUP_TITLES.get(g['name'], g['name'])
    A(f"- [{t}](#{t.lower().replace(' & ','--').replace(' ','-')}) — {len(g['items'])}")
A('')

for g in groups:
    t = GROUP_TITLES.get(g['name'], g['name'])
    A(f"## {t}")
    A('')
    A(f"`@group {g['name']}` · {len(g['items'])} entries")
    A('')
    if g['name'] in ('taps','core'):
        A('> Always installed — cannot be deselected.')
        A('')
    A('| Package | What it is | Learn more |')
    A('|---|---|---|')
    for kind, name, rest in g['items']:
        desc, url = info(kind, name, rest)
        link = f"[docs]({url})" if url else ''
        A(f"| `{name}` | {desc} | {link} |")
    A('')

text = '\n'.join(L)+'\n'

# --check: fail when the committed catalog no longer matches the Brewfile
# and metadata (ignoring the build date), or when a row has no description
# or link. tests/docs-test.sh runs it, so the catalog cannot go stale again.
if '--check' in sys.argv[1:]:
    def undated(t):
        return re.sub(r'last built \d{4}-\d{2}-\d{2}', 'last built DATE', t)
    problems = []
    current = open(OUT, encoding='utf-8').read() if os.path.exists(OUT) else ''
    if undated(current) != undated(text):
        problems.append('docs/PACKAGE_CATALOG.md is out of date: run python3 scripts/catalog/build-catalog.py')
    for g in groups:
        for kind, name, rest in g['items']:
            desc, url = info(kind, name, rest)
            if not desc or not url:
                problems.append(f'{kind} "{name}" has no {"description" if not desc else "link"}: add it to scripts/catalog/meta/')
    for p in problems:
        print(p, file=sys.stderr)
    sys.exit(1 if problems else 0)

open(OUT,'w',encoding='utf-8').write(text)
print('wrote', OUT)
print('groups:', len(groups), 'items:', sum(len(g['items']) for g in groups))
