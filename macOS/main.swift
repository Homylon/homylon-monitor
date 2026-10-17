// The Mac app starts here: no storyboard, the window is built in code (MonitorViewController).

import AppKit

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.regular)
application.run()
