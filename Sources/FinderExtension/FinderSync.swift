import Cocoa
import FinderSync

/// Finder Sync extension that adds "New Text File" to Finder's right-click menu.
final class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // Watch the whole filesystem so the menu appears in every folder.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer || menuKind == .contextualMenuForItems else {
            return nil
        }
        let menu = NSMenu(title: "")
        let item = NSMenuItem(title: "New Text File",
                              action: #selector(createTextFile(_:)),
                              keyEquivalent: "")
        item.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)
        menu.addItem(item)
        return menu
    }

    @objc func createTextFile(_ sender: AnyObject?) {
        let controller = FIFinderSyncController.default()
        guard var folder = controller.targetedURL() else { return }

        // Right-clicked a single folder → create inside it; otherwise use the current folder.
        if let selected = controller.selectedItemURLs(), selected.count == 1,
           let values = try? selected[0].resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]),
           values.isDirectory == true, values.isPackage != true {
            folder = selected[0]
        }

        do {
            _ = try Self.createUniqueFile(in: folder)
        } catch {
            NSLog("NewTextFile: failed to create file in %@: %@", folder.path, String(describing: error))
            NSSound.beep()
        }
    }

    /// Creates "untitled.txt", or "untitled 2.txt", "untitled 3.txt"… if taken.
    static func createUniqueFile(in folder: URL) throws -> URL {
        var n = 1
        while true {
            let name = n == 1 ? "untitled.txt" : "untitled \(n).txt"
            let url = folder.appendingPathComponent(name)
            do {
                try Data().write(to: url, options: .withoutOverwriting)
                return url
            } catch CocoaError.fileWriteFileExists {
                n += 1
            }
        }
    }
}
