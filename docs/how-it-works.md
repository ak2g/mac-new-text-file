# How it works

This document explains the moving parts, so you can audit, modify or extend the project.

## The pieces

```
/Applications/NewTextFile.app                     ← host app (container)
└── Contents/
    ├── Info.plist                                ← bundle id: local.newtextfile.app
    ├── MacOS/NewTextFile                         ← tiny launcher (Sources/App/main.swift)
    └── PlugIns/
        └── NewTextFileExtension.appex            ← the Finder Sync extension
            └── Contents/
                ├── Info.plist                    ← declares com.apple.FinderSync
                └── MacOS/NewTextFileExtension    ← Sources/FinderExtension/FinderSync.swift
```

macOS only loads app extensions that live inside an app bundle. That's the only reason the host app
exists. When you open it, it runs two `pluginkit` commands to register and enable the extension, then
quits. It has no window and no Dock icon (`LSUIElement`).

## The Finder Sync extension

[`FIFinderSync`](https://developer.apple.com/documentation/findersync/fifindersync) is Apple's API for
apps that want to add badges, toolbar buttons and **context‑menu items** to Finder. (Dropbox and
Google Drive use the same API.)

`Sources/FinderExtension/FinderSync.swift` does three things.

1. **Watch every folder.** A Finder Sync extension only gets called for folders it has registered
   interest in. Setting `directoryURLs` to `/` covers the whole file system:

   ```swift
   FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
   ```

2. **Offer the menu item.** Finder calls `menu(for:)` each time you right‑click. We return a menu
   with one item for two menu kinds:
   - `.contextualMenuForContainer`: right‑click on empty space in a folder
   - `.contextualMenuForItems`: right‑click on a file or folder

   Finder copies the item into its own menu, and when it's chosen Finder calls our action method in the
   extension process.

3. **Create the file.** In the action we work out the destination folder:
   - `targetedURL()` is the folder that was right‑clicked in.
   - If exactly one *folder* was right‑clicked (`selectedItemURLs()`), we create the file inside
     it instead. Packages such as `.app` bundles are excluded.

   Then we write an empty file named `untitled.txt`, counting up (`untitled 2.txt`, …) until we find
   a free name. The write uses `.withoutOverwriting`, which is an atomic "create only if it doesn't
   exist" (`O_EXCL`), so an existing file can never be replaced, even in a race.

   If the folder isn't writable (for example `/System` or a read‑only disk), the extension beeps and
   logs `NewTextFile: failed to create file…` to the system log.

## Sandbox and entitlements

macOS refuses to load an app extension that isn't sandboxed. A sandboxed process can normally only
write inside its own container, which would make this extension useless. So
`Resources/Extension.entitlements` adds a *temporary exception* that grants read/write access to `/`:

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array><string>/</string></array>
```

This doesn't bypass normal Unix permissions or macOS privacy protection (TCC). The extension can
only write where *you* can write, and macOS may still ask for permission for protected folders.

> Exceptions like this aren't allowed in the Mac App Store, which is one reason this project is
> distributed as source you build yourself.

## Building without Xcode

There is no `.xcodeproj`. `scripts/build.sh` does what Xcode would do, in plain shell.

1. **Compile the extension.** App extensions don't have a `main()`; their entry point is
   `NSExtensionMain` in Foundation, so we tell the linker to use that:

   ```bash
   swiftc -module-name NewTextFileExtension -parse-as-library -application-extension \
     -Xlinker -e -Xlinker _NSExtensionMain \
     -framework FinderSync -framework Cocoa \
     Sources/FinderExtension/FinderSync.swift -o …/NewTextFileExtension
   ```

   `NSExtensionPrincipalClass` in `Extension-Info.plist` is `NewTextFileExtension.FinderSync`
   (*module*.*class*), which is why the module name matters.

2. **Compile the host app** from `Sources/App/main.swift`.

3. **Assemble the bundles** by copying in the two `Info.plist` files.

4. **Code‑sign inside‑out:** first the `.appex` with its entitlements, then the app. The script
   uses your *Apple Development* certificate if the keychain has one and falls back to ad‑hoc
   signing (`-`) otherwise. Both work for local use. Override it with:

   ```bash
   SIGN_IDENTITY="Apple Development: …" ./scripts/build.sh
   ```

The target is `$(uname -m)-apple-macos12.0`, so it builds natively for whatever Mac you're on.

## Installing and registering

`scripts/install.sh`:

1. runs `build.sh`
2. disables and unregisters any previous copy, and stops its process
3. copies the app to `/Applications` with `ditto`
4. registers it with LaunchServices (`lsregister -f`) and PlugInKit (`pluginkit -a`)
5. enables the extension (`pluginkit -e use -i local.newtextfile.app.finder`)
6. checks that `pluginkit -m` reports it enabled (`+`)

Finder then launches `NewTextFileExtension` on demand. You can see it with
`pgrep -fl NewTextFileExtension`.

## Customising

| Want to…                                | Change                                                                      |
|-----------------------------------------|-----------------------------------------------------------------------------|
| Use a different file name or extension  | `"untitled.txt"` / `"untitled \(n).txt"` in `createUniqueFile(in:)`          |
| Rename the menu item                    | `title:` of the `NSMenuItem` in `menu(for:)`                                |
| Change the icon                         | `NSImage(systemSymbolName: "doc.text", …)`, which takes any SF Symbol name    |
| Pre‑fill the file with a template       | Replace `Data()` with your template bytes                                   |
| Show the item only on empty space       | Remove `.contextualMenuForItems` from the `guard` in `menu(for:)`           |

After any change, run `./scripts/install.sh` again.
