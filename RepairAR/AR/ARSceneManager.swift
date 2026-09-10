import SceneKit
import ARKit

// MARK: - AR Scene Manager
// Manages SceneKit scene setup, node placement, and 3D coordinate mapping.

final class ARSceneManager {

    // MARK: - Properties

    private let scene: SCNScene
    private var placedNodes: [String: SCNNode] = [:]

    /// When set, new nodes attach under the detected image anchor instead of world root.
    /// This keeps overlays glued to the real device and prevents drift on tracking reset.
    var anchorNode: SCNNode?

    // Physical device dimensions (meters) — used to map normalized coords to AR space
    private let deviceWidth: Float = 0.32   // ~32cm laptop width
    private let deviceHeight: Float = 0.22  // ~22cm laptop depth
    private let deviceElevation: Float = 0  // on surface

    // MARK: - Init

    init(scene: SCNScene) {
        self.scene = scene
        configureScene()
    }

    // MARK: - Scene Configuration

    private func configureScene() {
        scene.background.contents = UIColor.clear

        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 500
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Add directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.color = UIColor.white
        directionalLight.light?.castsShadow = true
        directionalLight.position = SCNVector3(0, 1, 0.5)
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, 0, 0)
        scene.rootNode.addChildNode(directionalLight)
    }

    // MARK: - Node Placement

    /// Place a node at a normalized component position.
    /// Positions are mapped from 0-1 normalized coords to physical AR space.
    func placeNode(_ node: SCNNode, at position: ComponentPosition) {
        // Map normalized (0,1) coords to physical space centered at origin
        let x = Float(position.x - 0.5) * deviceWidth
        let z = Float(position.y - 0.5) * deviceHeight
        let y = deviceElevation + Float(position.zOffset ?? 0.005)

        node.position = SCNVector3(x, y, z)
        node.eulerAngles.x = -.pi / 2  // Lay flat on surface

        // Prefer image anchor parent when available (drift-free), else world root
        let parent = anchorNode ?? scene.rootNode
        parent.addChildNode(node)
        placedNodes[node.name ?? UUID().uuidString] = node
    }

    /// Reparent all placed nodes under a new parent, preserving local layout.
    /// Call when an ARImageAnchor is detected after initial world-origin placement.
    func reparentAll(to parent: SCNNode) {
        anchorNode = parent
        for node in placedNodes.values {
            // Keep local position (device-relative), just change parent to anchor
            let localPos = node.position
            let localRot = node.eulerAngles
            node.removeFromParentNode()
            node.position = localPos
            node.eulerAngles = localRot
            parent.addChildNode(node)
        }
    }

    /// Remove a previously placed node.
    func removeNode(withIdentifier identifier: String) {
        placedNodes[identifier]?.removeFromParentNode()
        placedNodes.removeValue(forKey: identifier)
    }

    /// Remove all placed component nodes.
    func clearAllNodes() {
        placedNodes.values.forEach { $0.removeFromParentNode() }
        placedNodes.removeAll()
    }

    /// Get the world position of a placed node.
    func worldPosition(for identifier: String) -> SCNVector3? {
        placedNodes[identifier]?.worldPosition
    }

    /// Get screen position for a world point.
    func screenPosition(for worldPosition: SCNVector3, in view: ARSCNView) -> CGPoint {
        let projected = view.projectPoint(worldPosition)
        return CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y))
    }

    // MARK: - AR Configuration

    /// Create a world tracking configuration with optional image detection.
    func createConfiguration(with referenceImages: Set<ARReferenceImage> = []) -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.isLightEstimationEnabled = true

        if !referenceImages.isEmpty {
            config.detectionImages = referenceImages
            config.maximumNumberOfTrackedImages = 1
        }

        return config
    }

    // MARK: - Device Surface Simulation

    /// Create a transparent plane representing the detected device surface.
    func createDeviceSurface(width: Float? = nil, height: Float? = nil) -> SCNNode {
        let w = CGFloat(width ?? deviceWidth)
        let h = CGFloat(height ?? deviceHeight)
        let plane = SCNPlane(width: w, height: h)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.05)
        material.isDoubleSided = true
        plane.materials = [material]

        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, deviceElevation, 0)
        return node
    }
}
