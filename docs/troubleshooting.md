# Troubleshooting

## The "New Text File" item doesn't appear

1. **Check that the extension is registered and enabled:**

   ```bash
   pluginkit -m -i local.newtextfile.app.finder
   ```

   | Output starts with | Meaning                    | Fix                                                |
   |--------------------|----------------------------|----------------------------------------------------|
   | `+`                | Enabled                    | Go to step 2                                       |
   | `-`                | Installed but disabled     | `pluginkit -e use -i local.newtextfile.app.finder` |
   | *(no matches)*     | Not registered             | Run `./scripts/install.sh` again                   |

   You can also enable it in System Settings:
   - **macOS 15+:** General → Login Items & Extensions → Extensions
   - **macOS 13–14:** Privacy & Security → Extensions → Added Extensions
   - **macOS 12:** System Preferences → Extensions → Added Extensions

2. **Check that Finder has started it:**

   ```bash
   pgrep -fl NewTextFileExtension
   ```

   If nothing is printed, restart Finder so it reloads its extensions:

   ```bash
   killall Finder
   ```

3. **Old copies.** If you ever built the app somewhere else (for example an older checkout),
   macOS may be loading that copy. Remove everything and reinstall:

   ```bash
   ./scripts/uninstall.sh
   pluginkit -m -v -i local.newtextfile.app.finder   # should print nothing
   ./scripts/install.sh
   ```

## The item appears, but clicking it does nothing (or beeps)

The folder isn't writable, for example a system folder, a read‑only disk image, or a network share
without write permission. The extension never asks for administrator rights.

To see the exact error:

```bash
/usr/bin/log show --last 5m --predicate 'eventMessage CONTAINS "NewTextFile:"'
```

If macOS shows a dialog asking whether **NewTextFile** may access files in a folder (Desktop, Documents,
Downloads, removable volumes, …), click **Allow**.

## `swiftc: command not found` / build errors

Install Apple's Command Line Tools (free, no Xcode needed):

```bash
xcode-select --install
```

If you have several Xcode versions, make sure one is selected:

```bash
xcode-select -p
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Signing errors

The build uses your *Apple Development* certificate if one exists, otherwise ad‑hoc signing. If your
certificate is expired or broken, force ad‑hoc signing:

```bash
SIGN_IDENTITY=- ./scripts/install.sh
```

## The item disappeared after a macOS update

Re‑run the installer, or open `/Applications/NewTextFile.app` once. Both re‑register and re‑enable
the extension.

```bash
./scripts/install.sh
```

## Still stuck?

[Open an issue](https://github.com/ak2g/mac-new-text-file/issues) and include:

- your macOS version (`sw_vers`)
- the output of `pluginkit -m -v -i local.newtextfile.app.finder`
- the output of `./scripts/install.sh`
