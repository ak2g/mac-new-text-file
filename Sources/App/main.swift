import Foundation

// Host app: registers and enables the bundled Finder extension, then exits.
// Double-click it again any time the menu item goes missing.
let appex = Bundle.main.builtInPlugInsURL!
    .appendingPathComponent("NewTextFileExtension.appex").path

func run(_ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
    p.arguments = args
    try? p.run()
    p.waitUntilExit()
}

run(["-a", appex])
run(["-e", "use", "-i", "local.newtextfile.app.finder"])
