import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Don't terminate when window closes - keep running in menu bar
    return false
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Hide from dock if LSUIElement is not set
    NSApp.setActivationPolicy(.accessory)
  }
}