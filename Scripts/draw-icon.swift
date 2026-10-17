import AppKit
import Foundation
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    let scale = CGFloat(size) / 1024
    let transform = NSAffineTransform(); transform.scale(by: scale); transform.concat()
    let rect = NSRect(x: 45, y: 45, width: 934, height: 934)
    let background = NSBezierPath(roundedRect: rect, xRadius: 208, yRadius: 208)
    NSGradient(starting: NSColor(srgbRed: 0.19, green: 0.22, blue: 0.28, alpha: 1), ending: NSColor(srgbRed: 0.10, green: 0.12, blue: 0.17, alpha: 1))!.draw(in: background, angle: -50)
    NSColor.white.withAlphaComponent(0.18).setStroke(); background.lineWidth = 2; background.stroke()
    let colors: [NSColor] = [NSColor(srgbRed: 0.91, green: 0.60, blue: 0.65, alpha: 1), NSColor(srgbRed: 0.88, green: 0.76, blue: 0.51, alpha: 1), NSColor(srgbRed: 0.66, green: 0.80, blue: 0.56, alpha: 1), NSColor(srgbRed: 0.53, green: 0.77, blue: 0.85, alpha: 1), NSColor(srgbRed: 0.76, green: 0.64, blue: 0.89, alpha: 1), NSColor(srgbRed: 0.51, green: 0.80, blue: 0.70, alpha: 1)]
    for row in 0..<2 {
        for col in 0..<3 {
            let color = colors[row * 3 + col]
            let key = NSBezierPath(roundedRect: NSRect(x: 189 + col * 222, y: 262 + row * 222, width: 202, height: 202), xRadius: 36, yRadius: 36)
            color.withAlphaComponent(0.16).setFill(); key.fill(); color.withAlphaComponent(0.65).setStroke(); key.lineWidth = 3; key.stroke()
        }
    }
    let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 135, weight: .light), .foregroundColor: colors[3]]
    ("M" as NSString).draw(at: NSPoint(x: 228, y: 507), withAttributes: attrs)
    ("K" as NSString).draw(at: NSPoint(x: 678, y: 285), withAttributes: [.font: NSFont.systemFont(ofSize: 135, weight: .light), .foregroundColor: colors[5]])
    let bar = NSBezierPath(roundedRect: NSRect(x: 300, y: 180, width: 424, height: 17), xRadius: 8, yRadius: 8)
    NSColor.white.withAlphaComponent(0.45).setFill(); bar.fill()
    image.unlockFocus()
    let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
    let data = bitmap.representation(using: .png, properties: [:])!
    if size <= 512 { try data.write(to: output.appendingPathComponent("icon_\(size)x\(size).png")) }
    if size >= 32 { let half = size / 2; try data.write(to: output.appendingPathComponent("icon_\(half)x\(half)@2x.png")) }
}
