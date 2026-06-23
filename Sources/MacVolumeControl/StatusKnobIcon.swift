import AppKit

enum StatusKnobIcon {
    static func makeImage(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let outerInset = size * 0.16
            let outerRect = rect.insetBy(dx: outerInset, dy: outerInset)
            let outerPath = NSBezierPath(ovalIn: outerRect)
            outerPath.lineWidth = max(1.4, size * 0.09)
            outerPath.stroke()

            let innerInset = size * 0.34
            let innerRect = rect.insetBy(dx: innerInset, dy: innerInset)
            NSBezierPath(ovalIn: innerRect).fill()

            let center = CGPoint(x: rect.midX, y: rect.midY)
            let indicatorAngle = CGFloat.pi / 4
            let indicatorStart = CGPoint(
                x: center.x + cos(indicatorAngle) * size * 0.10,
                y: center.y + sin(indicatorAngle) * size * 0.10
            )
            let indicatorEnd = CGPoint(
                x: center.x + cos(indicatorAngle) * size * 0.31,
                y: center.y + sin(indicatorAngle) * size * 0.31
            )

            let indicator = NSBezierPath()
            indicator.move(to: indicatorStart)
            indicator.line(to: indicatorEnd)
            indicator.lineWidth = max(1.7, size * 0.11)
            indicator.lineCapStyle = .round
            indicator.stroke()

            let notchRadius = size * 0.05
            let notchCenter = CGPoint(
                x: center.x + cos(indicatorAngle) * size * 0.37,
                y: center.y + sin(indicatorAngle) * size * 0.37
            )
            let notchRect = NSRect(
                x: notchCenter.x - notchRadius,
                y: notchCenter.y - notchRadius,
                width: notchRadius * 2,
                height: notchRadius * 2
            )
            NSBezierPath(ovalIn: notchRect).fill()

            return true
        }

        image.isTemplate = true
        return image
    }
}
