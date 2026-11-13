# Contributing

Thanks for helping out! This project is intentionally small. The goal is one reliable,
easy‑to‑audit menu item, so please keep changes focused.

## Development loop

```bash
./scripts/build.sh      # compile + sign into build/ (doesn't touch /Applications)
./scripts/install.sh    # build + install + enable, to try it in Finder
```

There are no automated UI tests for Finder menus, so please check your change by hand before
opening a pull request:

1. `./scripts/install.sh` finishes with `Done.`
2. Right‑click on empty space in a folder → **New Text File** creates `untitled.txt`.
3. Doing it again creates `untitled 2.txt` (nothing is overwritten).
4. Right‑click on a folder → the file is created inside that folder.
5. `./scripts/uninstall.sh` removes the menu item.

Test in a scratch folder, not in your real documents.

## Guidelines

- Keep the extension free of network access, telemetry and background work.
- Don't widen entitlements beyond what's needed, and explain any entitlement change in the PR.
- Update `README.md` / `docs/` when behaviour changes, and add an entry to `CHANGELOG.md`.
- CI (`.github/workflows/build.yml`) must stay green.

## Reporting bugs

Please include your macOS version (`sw_vers`), the output of
`pluginkit -m -v -i local.newtextfile.app.finder`, and what you right‑clicked on.
