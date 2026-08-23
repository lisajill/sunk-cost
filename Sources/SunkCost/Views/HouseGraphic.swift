import SwiftUI

/// A bespoke, minimal line-drawn house -- the app's real visual signature.
/// There's no image-generation tool or bundled artwork available to this
/// project, so this is built entirely from vector geometry instead: a
/// roofline, a body, one window, and a door, meant to be stroked (not
/// filled) so it reads as clean line art rather than clip art. Scales
/// cleanly to any size via `.frame(width:height:)` since it's a real
/// `Shape`, not a fixed-size image.
///
/// Deliberately one window, not two: two same-size squares side by side
/// above a door reads as a face ("O.O") almost instantly -- a classic
/// minimal-icon pitfall. A single, off-center window with a door on the
/// other side avoids the symmetric two-eyes pattern entirely.
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

        // Door (right of center, reaching the ground).
        path.addRect(CGRect(x: x + w * 0.54, y: y + h * 0.60, width: w * 0.18, height: h * 0.36))

        // Window (left of center, upper body) with a cross mullion.
        let windowRect = CGRect(x: x + w * 0.26, y: y + h * 0.54, width: w * 0.18, height: h * 0.18)
        path.addRect(windowRect)
        path.move(to: CGPoint(x: windowRect.midX, y: windowRect.minY))
        path.addLine(to: CGPoint(x: windowRect.midX, y: windowRect.maxY))
        path.move(to: CGPoint(x: windowRect.minX, y: windowRect.midY))
        path.addLine(to: CGPoint(x: windowRect.maxX, y: windowRect.midY))

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
