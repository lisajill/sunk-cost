// One-off icon generator for The Money Pit.
// Draws a simple house + dollar sign mark at every size macOS needs for an
// .iconset, using Core Graphics directly (no external image tools/assets).
// Usage: swift generate_icon.swift <output-iconset-dir>
import AppKit

func drawIcon(size: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let cg = context.cgContext

    let s = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: s, height: s)

    // Background: rounded square, terracotta (house) -> deep teal (money) gradient.
    let cornerRadius = s * 0.2237 // matches Apple's big-sur-style icon corner ratio
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    cg.addPath(bgPath)
    cg.clip()

    let colors = [
        NSColor(calibratedRed: 0.86, green: 0.47, blue: 0.31, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.38, alpha: 1.0).cgColor,
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    cg.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])

    // House silhouette.
    let houseWidth = s * 0.54
    let houseHeight = s * 0.40
    let houseX = (s - houseWidth) / 2
    let houseY = s * 0.20
    let roofHeight = s * 0.26
    let overhang = s * 0.045

    let bodyPath = CGMutablePath()
    bodyPath.addRect(CGRect(x: houseX, y: houseY, width: houseWidth, height: houseHeight))

    let roofPath = CGMutablePath()
    roofPath.move(to: CGPoint(x: houseX - overhang, y: houseY + houseHeight))
    roofPath.addLine(to: CGPoint(x: houseX + houseWidth / 2, y: houseY + houseHeight + roofHeight))
    roofPath.addLine(to: CGPoint(x: houseX + houseWidth + overhang, y: houseY + houseHeight))
    roofPath.closeSubpath()

    cg.setFillColor(NSColor.white.withAlphaComponent(0.97).cgColor)
    cg.addPath(bodyPath)
    cg.fillPath()
    cg.addPath(roofPath)
    cg.fillPath()

    // Dollar sign centered on the house body.
    let dollarColor = NSColor(calibratedRed: 0.08, green: 0.33, blue: 0.29, alpha: 1.0)
    let font = NSFont.systemFont(ofSize: houseHeight * 0.82, weight: .bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: dollarColor]
    let string = "$" as NSString
    let textSize = string.size(withAttributes: attrs)
    let textRect = NSRect(
        x: houseX + (houseWidth - textSize.width) / 2,
        y: houseY + (houseHeight - textSize.height) / 2 - houseHeight * 0.03,
        width: textSize.width,
        height: textSize.height
    )
    string.draw(in: textRect, withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func savePNG(_ rep: NSBitmapImageRep, to url: URL) {
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to create PNG data for \(url.path)")
    }
    try? pngData.write(to: url)
}

guard CommandLine.arguments.count > 1 else {
    print("Usage: swift generate_icon.swift <output-iconset-dir>")
    exit(1)
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let iconSpecs: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for spec in iconSpecs {
    let rep = drawIcon(size: spec.size)
    savePNG(rep, to: outputDir.appendingPathComponent("\(spec.name).png"))
}

print("Generated \(iconSpecs.count) icon images in \(outputDir.path)")
