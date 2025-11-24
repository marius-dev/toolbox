import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // CRITICAL: Enable transparency
    self.isOpaque = false
    self.backgroundColor = NSColor.clear
    self.hasShadow = true
    
    // Make window level higher
    self.level = .floating
    
    // Enable visual effect view for blur
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
  
  override var canBecomeKey: Bool {
    return true
  }
  
  override var canBecomeMain: Bool {
    return true
  }
}