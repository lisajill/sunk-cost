import SwiftUI

/// A bespoke, minimal line-drawn house -- the app's real visual signature.
/// There's no image-generation tool or bundled artwork available to this
/// project, so this is built entirely from vector geometry instead: a
/// roofline, a body, a door, and two windows, meant to be stroked (not
/// filled) so it reads as clean line art rather than clip art. Scales
/// cleanly to any size via `.frame(width:height:)` since it's a real
/// `Shape`, not a fixed-size image.
struct HouseGraphic: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let x = rect.minX
        let y = rect.minY

        // Roofline.
        path.move(to: CGPoint(x: x + w * 0.06, y: y + h * 0.46))
        path.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.04))
        path.addLine(to: CGPoint(x: x + w * 0.94, y: y + h * 0.46))

        // Body.
        path.addRect(CGRect(x: x + w * 0.16, y: y + h * 0.44, width: w * 0.68, height: h * 0.52))

        // Door.
        path.addRect(CGRect(x: x + w * 0.44, y: y + h * 0.70, width: w * 0.14, height: h * 0.26))

        // Windows.
        path.addRect(CGRect(x: x + w * 0.24, y: y + h * 0.54, width: w * 0.14, height: h * 0.14))
        path.addRect(CGRect(x: x + w * 0.62, y: y + h * 0.54, width: w * 0.14, height: h * 0.14))

        return path
    }
}

/// Strokes `HouseGraphic` in the given color at the given size -- the
/// standard way this motif is used throughout the app.
struct HouseAccent: View {
    let color: Color
    var size: CGFloat = 96
    var lineWidth: CGFloat = 3

    var body: some View {
        HouseGraphic()
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}
