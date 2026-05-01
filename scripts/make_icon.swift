import Cocoa

let size = 1024
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()

// White background with slight rounded feel (flat square for icns)
NSColor.white.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

// Draw "S" centered
let font = NSFont(name: "Courier New Bold", size: 620) ?? NSFont.monospacedSystemFont(ofSize: 620, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.black
]
let str = "S" as NSString
let strSize = str.size(withAttributes: attrs)
let x = (CGFloat(size) - strSize.width) / 2
let y = (CGFloat(size) - strSize.height) / 2 + 10
str.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

image.unlockFocus()

// Export as PNG
if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    let url = URL(fileURLWithPath: "icon_1024.png")
    try! png.write(to: url)
    print("Saved icon_1024.png")
}
