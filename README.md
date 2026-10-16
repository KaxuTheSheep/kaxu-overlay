# k1axu-overlay

Random stuff for Kaxu (why am I talking in third person?)

## Layout

```
├── gui-wm
│   └── dwl
│       ├── dwl-0.8.ebuild
│       ├── dwl-0.9.ebuild
│       ├── files
│       │   ├── autostart-0.8.patch
│       │   ├── cfact-0.9.patch
│       │   ├── movestack-0.8.patch
│       │   └── movestack-0.9.patch
│       ├── Manifest
│       └── metadata.xml
├── metadata
│   ├── layout.conf
│   └── md5-cache
│       └── gui-wm
│           ├── dwl-0.8
│           └── dwl-0.9
├── profiles
│   └── repo_name
└── README.md
```
## DWL
Gentoo ebuilds for [dwl](https://codeberg.org/dwl/dwl) with optional patches, one USE flag per patch. Kept partly as a starting point for anyone who wants dwl on Gentoo and doesn't know where to begin or people just happen to want what i like; the tree has no 0.8 ebuild, so 0.8 lives here.


### USE flags

| Version | Flags                      |
|---------|----------------------------|
| 0.8     | `X autostart bar movestack`|       
| 0.9     | `X cfact movestack`        | 
0.9 needs wlroots slot `0.20`; 0.8 needs `0.19`.

### How patches are picked up

Each ebuild reads `${FILESDIR}/<flag>-${PV}.patch` for every enabled flag, so the filename must be exactly `<name>-<version>.patch`. Patches are applied in a fixed order (cfact, then movestack), which is the order they were tested in.

### savedconfig and the guard

The ebuilds use `savedconfig`: `config.h` comes from `/etc/portage/savedconfig/gui-wm/dwl-<version>`. A saved `config.h` hides the keybinds a patch adds to `config.def.h`, so `src_prepare` checks it before building:

- flag on, symbol missing from `config.h`: the build dies and says which symbol is needed
- flag off, symbol present: the build dies as well

| Flag      | Symbol it looks for |
|-----------|---------------------|
| movestack | `movestack`         |
| cfact     | `setcfact`          |

If the build dies here, your saved copy is probably stale. Re-run the config sync first.

Keybinds used (0.9):

```
{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_j,  movestack,  {.i = +1} },
{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_k,  movestack,  {.i = -1} },
{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_H,  setcfact,   {.f = -0.25f} },
{ MODKEY|WLR_MODIFIER_SHIFT, XKB_KEY_L,  setcfact,   {.f = +0.25f} },
```

exact config lives in https://github.com/KaxuTheSheep/dotfiles.

### Porting a patch to a new dwl release

Source lives in `~/src/dwl`, patches in `~/src/dwl-patches/patches/`. Use the release **tag**, not a branch name: branches can move, tags can't.

1. Start with a clean tree: `git status --short` should print nothing. Uncommitted changes follow you across `git checkout -b`, which mixes patches together.
2. One branch per patch, from the tag: `git checkout -b <name> v<version>`.
3. Apply the closest existing patch: `git apply --reject <patch>`. Name the file explicitly; a `*.patch` glob stacks several versions at once and fails confusingly.
4. Fix the rejects by hand, then `rm -f *.rej *.orig` and run `make`.
5. Commit only the source files: `git add dwl.c config.def.h && git commit`.
6. Export from the tag: `git diff v<version> <name> > <name>-<version>.patch`. Check it is sensible: `wc -l`, and `grep -c '^+++'` for the number of files.
7. Prove it applies to pristine source or gg: `git checkout --detach v<version>` then `git apply --check <patch> && echo OK`.
8. Prove the patches stack in the ebuild's order or else gg: apply the first, then `git apply --check` the second.
9. Sync, enable the USE flag, add the keybinds to your saved config, and emerge.
