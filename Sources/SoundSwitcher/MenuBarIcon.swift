import AppKit

/// Draws a distinctive SoundSwitcher menu bar icon: waveform arcs with a central "S"
func makeSoundSwitcherIcon(size: CGFloat = 18) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

        let cx = rect.midX
        let cy = rect.midY
        let color = NSColor.black.cgColor

        ctx.setFillColor(color)
        ctx.setStrokeColor(color)
        ctx.setLineWidth(1.2)
        ctx.setLineCap(.round)

        // Left arc (outer)
        drawArc(ctx: ctx, cx: cx, cy: cy, radius: size * 0.44, startAngle: 145, endAngle: 215, side: .left)
        // Left arc (inner)
        drawArc(ctx: ctx, cx: cx, cy: cy, radius: size * 0.30, startAngle: 148, endAngle: 212, side: .left)

        // Right arc (outer)
        drawArc(ctx: ctx, cx: cx, cy: cy, radius: size * 0.44, startAngle: -35, endAngle: 35, side: .right)
        // Right arc (inner)
        drawArc(ctx: ctx, cx: cx, cy: cy, radius: size * 0.30, startAngle: -32, endAngle: 32, side: .right)

        // Central "S"
        let font = NSFont.systemFont(ofSize: size * 0.38, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
        let str = NSAttributedString(string: "S", attributes: attrs)
        let strSize = str.size()
        str.draw(at: NSPoint(x: cx - strSize.width / 2, y: cy - strSize.height / 2))

        return true
    }
    image.isTemplate = true
    return image
}

private func drawArc(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                     startAngle: CGFloat, endAngle: CGFloat, side: Side) {
    let start = startAngle * .pi / 180
    let end = endAngle * .pi / 180
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
               startAngle: start, endAngle: end,
               clockwise: side == .left)
    ctx.strokePath()
}

private enum Side { case left, right }
