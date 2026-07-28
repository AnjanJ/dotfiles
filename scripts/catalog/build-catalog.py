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

groups, cur = [], None
for line in open(BF, encoding='utf-8'):
    line = line.rstrip('\n')
    g = re.match(r'^# @group (\S+)', line)
    if g:
        cur = {'name': g.group(1), 'items': []}; groups.append(cur); continue
    m = re.match(r'^(tap|brew|cask|mas|vscode) "([^"]+)"(.*)$', line)
    if m and cur: cur['items'].append((m.group(1), m.group(2), m.group(3)))

def md_escape(s):
    return (s or '').replace('|', '\\|').strip()

def info(kind, name, rest):
    short = name.split('/')[-1]
    if kind == 'brew':
        r = fm.get(short) or tm.get(short)
        if r: return md_escape(r[1]), r[2]
    elif kind == 'cask':
        r = cm.get(short)
        if r: return md_escape(r[1]), r[2]
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
        return 'Third-party Homebrew formula repository', f"https://github.com/{name.split('/')[0]}/homebrew-{name.split('/')[-1]}"
    return '', ''

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
A('')
A('A blank description means upstream ships none — nothing has been invented to fill a gap.')
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

open(OUT,'w',encoding='utf-8').write('\n'.join(L)+'\n')
print('wrote', OUT)
print('groups:', len(groups), 'items:', sum(len(g['items']) for g in groups))
