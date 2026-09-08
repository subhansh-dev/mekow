import SceneKit
import QuartzCore

// MARK: - Component Overlay Node
// SCNNode subclass that renders highlighted component overlays in AR.
// Different shapes for screws, components, and cables. Animated glow/pulse.

final class ComponentOverlayNode: SCNNode {

    // MARK: - Properties

    private let component: Component
    private var currentState: ComponentState = .notReached
    private var glowAnimation: CABasicAnimation?
    private var pulseAnimation: CABasicAnimation?
    private var geometryNode: SCNNode?

    // Size constants (meters in AR space)
    private let screwRadius: CGFloat = 0.004     // 4mm
    private let componentScale: CGFloat = 0.04   // base component size
    private let lineWidth: CGFloat = 0.001        // 1mm line width

    // MARK: - Init

    init(component: Component, state: ComponentState = .notReached) {
        self.component = component
        super.init()
        self.name = component.id
        self.currentState = state
        setupGeometry()
        applyState(state, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Geometry Setup

    private func setupGeometry() {
        let childNode: SCNNode

        switch component.type {
        case .screw:
            childNode = createScrewNode()
        case .cable, .connector:
            childNode = createCableNode()
        case .component, .board, .battery, .display, .storage, .memory, .fan, .adhesive:
            childNode = createComponentNode()
        }

        addChildNode(childNode)
        geometryNode = childNode
    }

    // MARK: - Screw Node (Circle)

    private func createScrewNode() -> SCNNode {
        let radius = component.size.map { CGFloat($0.width) * componentScale / 2 } ?? screwRadius
        let torus = SCNTorus(ringRadius: radius, pipeRadius: lineWidth)
        let material = createGlowMaterial(color: currentState.glowColor)
        torus.materials = [material]

        let node = SCNNode(geometry: torus)
        node.name = component.id
        return node
    }

    // MARK: - Component Node (Rectangle)

    private func createComponentNode() -> SCNNode {
        let w = component.size.map { CGFloat($0.width) * componentScale } ?? componentScale
        let h = component.size.map { CGFloat($0.height) * componentScale } ?? componentScale * 0.7

        let plane = SCNPlane(width: w, height: h)
        let material = createGlowMaterial(color: currentState.glowColor)
        plane.materials = [material]

        // Create outline effect using a slightly larger transparent plane behind
        let outlinePlane = SCNPlane(width: w + lineWidth * 4, height: h + lineWidth * 4)
        let outlineMaterial = SCNMaterial()
        outlineMaterial.diffuse.contents = currentState.glowColor.withAlphaComponent(0.3)
        outlineMaterial.emission.contents = currentState.glowColor.withAlphaComponent(0.2)
        outlineMaterial.isDoubleSided = true
        outlineMaterial.transparency = 0.5
        outlinePlane.materials = [outlineMaterial]

        let container = SCNNode()
        let mainNode = SCNNode(geometry: plane)
        mainNode.name = component.id
        container.addChildNode(mainNode)

        let outlineNode = SCNNode(geometry: outlinePlane)
        outlineNode.position.z = -0.001
        container.addChildNode(outlineNode)

        return container
    }

    // MARK: - Cable Node (Line Segment)

    private func createCableNode() -> SCNNode {
        let w = component.size.map { CGFloat($0.width) * componentScale } ?? componentScale * 1.5
        let h = lineWidth * 3

        let plane = SCNPlane(width: w, height: h)
        let material = createGlowMaterial(color: currentState.glowColor)
        plane.materials = [material]

        let node = SCNNode(geometry: plane)
        node.name = component.id
        return node
    }

    // MARK: - Material

    private func createGlowMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color.withAlphaComponent(0.4)
        material.emission.contents = color
        material.emission.intensity = 0.8
        material.isDoubleSided = true
        material.transparency = 0.7
        material.blingModel = .physicallyBased
        return material
    }

    // MARK: - State Updates

    func updateState(_ newState: ComponentState, animated: Bool = true) {
        let oldState = currentState
        currentState = newState
        guard oldState != newState else { return }

        if animated {
            animateTransition(from: oldState, to: newState)
        } else {
            applyMaterialColor(newState.glowColor, intensity: newState.glowIntensity)
            applyAnimations(for: newState)
        }
    }

    private func applyState(_ state: ComponentState, animated: Bool) {
        applyMaterialColor(state.glowColor, intensity: state.glowIntensity)
        applyAnimations(for: state)
    }

    private func applyMaterialColor(_ color: UIColor, intensity: CGFloat) {
        enumerateChildNodes { child, _ in
            if let geometry = child.geometry {
                for material in geometry.materials {
                    material.diffuse.contents = color.withAlphaComponent(0.3 + intensity * 0.4)
                    material.emission.contents = color
                    material.emission.intensity = Float(intensity)
                    material.transparency = 0.3 + intensity * 0.7
                }
            }
        }
    }

    // MARK: - Animations

    private func animateTransition(from oldState: ComponentState, to newState: ComponentState) {
        // Color transition
        let colorAnim = CABasicAnimation(keyPath: "opacity")
        colorAnim.fromValue = oldState.glowIntensity
        colorAnim.toValue = newState.glowIntensity
        colorAnim.duration = newState.animationDuration
        colorAnim.fillMode = .forwards
        colorAnim.isRemovedOnCompletion = false

        // Apply material changes with animation
        UIView.animate(withDuration: newState.animationDuration) {
            self.applyMaterialColor(newState.glowColor, intensity: newState.glowIntensity)
        } completion: { _ in
            self.applyAnimations(for: newState)
        }

        // Scale bounce for current focus
        if newState == .currentFocus {
            let scaleUp = SCNAction.scale(to: 1.15, duration: 0.2)
            let scaleDown = SCNAction.scale(to: 1.0, duration: 0.15)
            scaleDown.timingMode = .easeOut
            let sequence = SCNAction.sequence([scaleUp, scaleDown])
            geometryNode?.runAction(sequence)
        }

        // Fade for completed
        if newState == .completed {
            let fade = SCNAction.fadeOpacity(to: 0.15, duration: 0.5)
            geometryNode?.runAction(fade)
        }
    }

    private func applyAnimations(for state: ComponentState) {
        // Remove existing animations
        geometryNode?.removeAllAnimations()
        geometryNode?.removeAllActions()

        switch state {
        case .currentFocus:
            startPulseAnimation()
            startGlowAnimation()
        case .highlight:
            startGlowAnimation()
        case .notReached, .completed:
            break
        }
    }

    private func startPulseAnimation() {
        let scaleUp = SCNAction.scale(to: 1.08, duration: 0.8)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.8)
        scaleDown.timingMode = .easeInEaseOut
        let pulse = SCNAction.repeatForever(SCNAction.sequence([scaleUp, scaleDown]))
        geometryNode?.runAction(pulse, forKey: "pulse")
    }

    private func startGlowAnimation() {
        guard let geometry = geometryNode?.geometry else { return }

        let glowAnim = CABasicAnimation(keyPath: "material.emission.intensity")
        glowAnim.fromValue = 0.5
        glowAnim.toValue = 1.2
        glowAnim.duration = 1.0
        glowAnim.autoreverses = true
        glowAnim.repeatCount = .infinity
        glowAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        for material in geometry.materials {
            material.add(glowAnim, forKey: "glow")
        }
    }

    // MARK: - Cleanup

    override func removeFromParentNode() {
        geometryNode?.removeAllActions()
        geometryNode?.removeAllAnimations()
        super.removeFromParentNode()
    }
}
