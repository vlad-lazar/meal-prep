// Renders the 1024×1024 app icon: brand gradient with a salad emoji.
// Usage: swift scripts/make-icon.swift MealPrep/Assets.xcassets/AppIcon.appiconset/icon-1024.png
import AppKit

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let rect = NSRect(x: 0, y: 0, width: size, height: size)
NSGradient(colors: [
    NSColor(red: 1.00, green: 0.54, blue: 0.36, alpha: 1),
    NSColor(red: 1.00, green: 0.37, blue: 0.61, alpha: 1),
    NSColor(red: 0.49, green: 0.36, blue: 1.00, alpha: 1),
])!.draw(in: rect, angle: -45)
let emoji = "🥗" as NSString
let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 560)]
let textSize = emoji.size(withAttributes: attributes)
emoji.draw(at: NSPoint(x: (CGFloat(size) - textSize.width) / 2, y: (CGFloat(size) - textSize.height) / 2),
           withAttributes: attributes)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
