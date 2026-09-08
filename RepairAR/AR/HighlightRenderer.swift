import UIKit
import CoreGraphics

// MARK: - Highlight Renderer
// Core Graphics drawing for highlight effects: arrows, glow, dashed outlines, solid fills.

final class HighlightRenderer {

    // MARK: - Types

    enum HighlightStyle {
        case solid           // Current focus
        case dashed          // "Remove this" indicator
        case glow            // Surrounding glow
        case arrow           // Pointing arrow
    }

    // MARK: - Draw Highlighted Area

    /// Draw a highlight around a rectangular area with the given style.
    static func drawHighlight(
        in context: CGContext,
        rect: CGRect,
        style: HighlightStyle,
        color: UIColor,
        progress: CGFloat = 1.0
    ) {
        context.saveGState()

        switch style {
        case .solid:
            drawSolidHighlight(in: context, rect: rect, color: color, progress: progress)
        case .dashed:
            drawDashedHighlight(in: context, rect: rect, color: color, progress: progress)
        case .glow:
            drawGlowHighlight(in: context, rect: rect, color: color, progress: progress)
        case .arrow:
            drawArrowHighlight(in: context, rect: rect, color: color)
        }

        context.restoreGState()
    }

    // MARK: - Solid Fill

    private static func drawSolidHighlight(
        in context: CGContext,
        rect: CGRect,
        color: UIColor,
        progress: CGFloat
    ) {
        let insetRect = rect.insetBy(dx: 2, dy: 2)

        // Background fill
        context.setFillColor(color.withAlphaComponent(0.2 * progress).cgColor)
        context.fill(insetRect)

        // Border
        context.setStrokeColor(color.withAlphaComponent(0.8 * progress).cgColor)
        context.setLineWidth(2.0)
        context.stroke(insetRect)

        // Rounded corners clip
        let path = UIBezierPath(roundedRect: insetRect, cornerRadius: 4)
        context.addPath(path.cgPath)
        context.clip()

        // Inner gradient
        let gradientColors = [
            color.withAlphaComponent(0.1 * progress).cgColor,
            color.withAlphaComponent(0.3 * progress).cgColor,
            color.withAlphaComponent(0.05 * progress).cgColor
        ]
        let locations: [CGFloat] = [0, 0.5, 1.0]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: gradientColors as CFArray,
            locations: locations
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: insetRect.midX, y: insetRect.minY),
                end: CGPoint(x: insetRect.midX, y: insetRect.maxY),
                options: []
            )
        }
    }

    // MARK: - Dashed Outline

    private static func drawDashedHighlight(
        in context: CGContext,
        rect: CGRect,
        color: UIColor,
        progress: CGFloat
    ) {
        let insetRect = rect.insetBy(dx: 2, dy: 2)
        let path = UIBezierPath(roundedRect: insetRect, cornerRadius: 4)

        context.setStrokeColor(color.withAlphaComponent(0.7 * progress).cgColor)
        context.setLineWidth(1.5)
        context.setLineDash(phase: 0, lengths: [6, 4])
        context.addPath(path.cgPath)
        context.strokePath()

        // Animated dash offset (caller should invoke repeatedly)
        // The phase parameter can be animated externally

        // X mark in center
        let center = CGPoint(x: insetRect.midX, y: insetRect.midY)
        let xSize: CGFloat = 8
        context.setStrokeColor(color.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.5)
        context.setLineDash(phase: 0, lengths: [])
        context.move(to: CGPoint(x: center.x - xSize, y: center.y - xSize))
        context.addLine(to: CGPoint(x: center.x + xSize, y: center.y + xSize))
        context.move(to: CGPoint(x: center.x + xSize, y: center.y - xSize))
        context.addLine(to: CGPoint(x: center.x - xSize, y: center.y + xSize))
        context.strokePath()
    }

    // MARK: - Glow Effect

    private static func drawGlowHighlight(
        in context: CGContext,
        rect: CGRect,
        color: UIColor,
        progress: CGFloat
    ) {
        let expandedRect = rect.insetBy(dx: -8, dy: -8)

        // Multiple layers of glow
        for i in 0..<3 {
            let expand = CGFloat(i) * 4
            let glowRect = expandedRect.insetBy(dx: -expand, dy: -expand)
            let alpha = (0.15 - CGFloat(i) * 0.04) * progress
            let glowPath = UIBezierPath(roundedRect: glowRect, cornerRadius: 8 + expand)

            context.setFillColor(color.withAlphaComponent(alpha).cgColor)
            context.addPath(glowPath.cgPath)
            context.fillPath()
        }

        // Core outline
        let coreRect = rect.insetBy(dx: 1, dy: 1)
        let corePath = UIBezierPath(roundedRect: coreRect, cornerRadius: 4)
        context.setStrokeColor(color.withAlphaComponent(0.9 * progress).cgColor)
        context.setLineWidth(2.0)
        context.addPath(corePath.cgPath)
        context.strokePath()

        // Gradient fill
        let gradientColors = [
            color.withAlphaComponent(0.0).cgColor,
            color.withAlphaComponent(0.15 * progress).cgColor,
            color.withAlphaComponent(0.0).cgColor
        ]
        let locations: [CGFloat] = [0, 0.5, 1.0]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: gradientColors as CFArray,
            locations: locations
        ) {
            context.saveGState()
            context.addPath(corePath.cgPath)
            context.clip()
            context.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: coreRect.midX, y: coreRect.midY),
                startRadius: 0,
                endCenter: CGPoint(x: coreRect.midX, y: coreRect.midY),
                endRadius: max(coreRect.width, coreRect.height) / 2,
                options: []
            )
            context.restoreGState()
        }
    }

    // MARK: - Arrow

    private static func drawArrowHighlight(
        in context: CGContext,
        rect: CGRect,
        color: UIColor
    ) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let arrowLength: CGFloat = 30
        let arrowWidth: CGFloat = 8

        // Arrow shaft
        let shaftStart = CGPoint(x: center.x, y: center.y + arrowLength / 2)
        let shaftEnd = CGPoint(x: center.x, y: center.y - arrowLength / 2)

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.5)
        context.setLineDash(phase: 0, lengths: [])
        context.move(to: shaftStart)
        context.addLine(to: shaftEnd)
        context.strokePath()

        // Arrowhead
        let tip = shaftEnd
        let leftWing = CGPoint(x: tip.x - arrowWidth, y: tip.y + arrowWidth)
        let rightWing = CGPoint(x: tip.x + arrowWidth, y: tip.y + arrowWidth)

        context.setFillColor(color.cgColor)
        context.move(to: tip)
        context.addLine(to: leftWing)
        context.addLine(to: rightWing)
        context.closePath()
        context.fillPath()
    }

    // MARK: - Bezier Curve Arrow

    /// Draw a curved arrow from one point to another.
    static func drawCurvedArrow(
        in context: CGContext,
        from start: CGPoint,
        to end: CGPoint,
        color: UIColor,
        lineWidth: CGFloat = 2.0
    ) {
        context.saveGState()

        let midY = (start.y + end.y) / 2
        let controlPoint1 = CGPoint(x: start.x, y: midY)
        let controlPoint2 = CGPoint(x: end.x, y: midY)

        // Draw bezier curve
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        context.move(to: start)
        context.addCurve(to: end, control1: controlPoint1, control2: controlPoint2)
        context.strokePath()

        // Arrowhead at end
        let angle = atan2(end.y - controlPoint2.y, end.x - controlPoint2.x)
        let arrowLength: CGFloat = 10
        let arrowAngle: CGFloat = .pi / 6

        let wing1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let wing2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        context.setFillColor(color.cgColor)
        context.move(to: end)
        context.addLine(to: wing1)
        context.addLine(to: wing2)
        context.closePath()
        context.fillPath()

        context.restoreGState()
    }

    // MARK: - Animated Dash Phase

    /// Create an array of dash phases for animation.
    static func dashPhases(count: Int = 20, dashLength: CGFloat = 6, gapLength: CGFloat = 4) -> [CGFloat] {
        let totalLength = dashLength + gapLength
        return (0..<count).map { CGFloat($0) * totalLength / CGFloat(count) }
    }
}
