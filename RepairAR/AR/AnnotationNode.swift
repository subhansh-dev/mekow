import SpriteKit
import UIKit

// MARK: - Annotation Node
// SpriteKit overlay node for 2D labels and arrows that track 3D component positions.

final class AnnotationNode: SKNode {

    // MARK: - Properties

    private let textLabel: SKLabelNode
    private let detailLabel: SKLabelNode
    private let backgroundNode: SKShapeNode
    private let arrowNode: SKShapeNode
    private let dotNode: SKShapeNode

    private let textColor: UIColor
    private let maxWidth: CGFloat = 160

    // MARK: - Init

    init(text: String, detail: String? = nil, color: UIColor = UIColor(hex: "#00D4FF")) {
        self.textColor = color
        self.textLabel = SKLabelNode(fontNamed: "SFProDisplay-Bold")
        self.detailLabel = SKLabelNode(fontNamed: "SFProDisplay-Regular")
        self.backgroundNode = SKShapeNode()
        self.arrowNode = SKShapeNode()
        self.dotNode = SKShapeNode()

        super.init()

        setupNodes(text: text, detail: detail, color: color)
        setupAnimations()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupNodes(text: String, detail: String?, color: UIColor) {
        // Text label
        textLabel.text = text
        textLabel.fontSize = 13
        textLabel.fontColor = .white
        textLabel.numberOfLines = 1
        textLabel.horizontalAlignmentMode = .center
        textLabel.verticalAlignmentMode = .center

        // Detail label
        if let detail = detail {
            detailLabel.text = detail
            detailLabel.fontSize = 10
            detailLabel.fontColor = UIColor.white.withAlphaComponent(0.7)
            detailLabel.numberOfLines = 2
            detailLabel.horizontalAlignmentMode = .center
            detailLabel.verticalAlignmentMode = .center
        }

        // Calculate sizes
        let textWidth = min(textLabel.frame.width + 20, maxWidth)
        let hasDetail = detail != nil
        let bgHeight: CGFloat = hasDetail ? 44 : 26

        // Background pill
        let bgRect = CGRect(x: -textWidth / 2, y: -bgHeight / 2, width: textWidth, height: bgHeight)
        let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: bgHeight / 2)
        backgroundNode.path = bgPath.cgPath
        backgroundNode.fillColor = UIColor.black.withAlphaComponent(0.75)
        backgroundNode.strokeColor = color.withAlphaComponent(0.6)
        backgroundNode.lineWidth = 1.0
        backgroundNode.glowWidth = 2.0

        // Dot at anchor point
        let dotPath = UIBezierPath(ovalIn: CGRect(x: -4, y: -4, width: 8, height: 8))
        dotNode.path = dotPath.cgPath
        dotNode.fillColor = color
        dotNode.strokeColor = .clear
        dotNode.glowWidth = 4.0

        // Arrow connecting dot to label
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: 0, y: 8))
        arrowPath.addLine(to: CGPoint(x: 0, y: -bgHeight / 2 - 4))
        arrowNode.path = arrowPath.cgPath
        arrowNode.strokeColor = color.withAlphaComponent(0.6)
        arrowNode.lineWidth = 1.5

        // Add nodes
        addChildNode(dotNode)
        addChildNode(arrowNode)
        addChildNode(backgroundNode)

        textLabel.position = CGPoint(x: 0, y: hasDetail ? 6 : 0)
        addChildNode(textLabel)

        if hasDetail {
            detailLabel.position = CGPoint(x: 0, y: -10)
            addChildNode(detailLabel)
        }

        // Offset everything above the dot
        backgroundNode.position.y = bgHeight / 2 + 14
        textLabel.position.y += bgHeight / 2 + 14
        detailLabel.position.y += bgHeight / 2 + 14
        arrowNode.position.y = 0
    }

    // MARK: - Animations

    private func setupAnimations() {
        // Fade in
        alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        run(fadeIn)

        // Gentle float
        let moveUp = SKAction.moveBy(x: 0, y: 3, duration: 1.0)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SKAction.moveBy(x: 0, y: -3, duration: 1.0)
        moveDown.timingMode = .easeInEaseOut
        let float = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
        run(float, withKey: "float")

        // Pulse the dot
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.6)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.6)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        dotNode.run(pulse, withKey: "pulse")
    }

    // MARK: - Update

    func updateText(_ text: String) {
        textLabel.text = text
    }

    func updateDetail(_ detail: String?) {
        detailLabel.text = detail
        detailLabel.isHidden = detail == nil
    }

    // MARK: - Cleanup

    func animateOut(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scale = SKAction.scale(to: 0.8, duration: 0.2)
        let group = SKAction.group([fadeOut, scale])
        run(group) {
            self.removeFromParent()
            completion()
        }
    }
}
