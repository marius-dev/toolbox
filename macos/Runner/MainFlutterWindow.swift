import Cocoa
import FlutterMacOS
import QuartzCore

private let kWindowCornerRadius: CGFloat = 26.0

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
    
    // Match the window corner radius with the Flutter UI mask so no background is exposed.
    if let contentView = self.contentView {
      contentView.wantsLayer = true
      contentView.layer?.cornerRadius = kWindowCornerRadius
      contentView.layer?.masksToBounds = true
      contentView.layer?.cornerCurve = .continuous
      if let superview = contentView.superview {
        superview.wantsLayer = true
        superview.layer?.cornerRadius = kWindowCornerRadius
        superview.layer?.masksToBounds = true
        superview.layer?.cornerCurve = .continuous
      }
    }
    
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
