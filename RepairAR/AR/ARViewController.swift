import UIKit
import ARKit
import SceneKit
import SpriteKit
import AVFoundation

// MARK: - AR View Controller
// Main AR scene controller with component overlays and step-by-step guidance.

final class ARViewController: UIViewController {

    // MARK: - Properties

    private var device: Device
    private var guide: RepairGuide
    private var currentStepIndex: Int = 0

    private var arView: ARSCNView!
    private var spriteScene: SKScene!
    private var sceneManager: ARSceneManager!
    private var detectionService: DeviceDetectionService!

    // Overlay tracking
    private var componentNodes: [String: ComponentOverlayNode] = [:]
    private var annotationNodes: [String: AnnotationNode] = [:]
    private var componentStates: [String: ComponentState] = [:]

    // Image-anchor tracking (real AR anchoring, drift-free)
    private var deviceAnchorNode: SCNNode?
    private var hasAnchoredToImage = false

    // UI elements
    private var stepCard: StepCardView!
    private var progressView: ProgressIndicatorView!
    private var previousButton: UIButton!
    private var nextButton: UIButton!
    private var closeButton: UIButton!
    private var componentInfoView: ComponentInfoView?
    private var loadingOverlay: UIView!
    private var loadingLabel: UILabel!
    private var statusLabel: UILabel!

    // Layout constants
    private let cardHeight: CGFloat = 180
    private let buttonSize: CGFloat = 44
    private let padding: CGFloat = 16

    // Annotation throttle (avoid 60Hz main-thread dispatch)
    private var lastAnnotationUpdate: TimeInterval = 0
    private let annotationUpdateInterval: TimeInterval = 1.0 / 20.0 // 20fps max

    // MARK: - Init

    init(device: Device, guide: RepairGuide) {
        self.device = device
        self.guide = guide
        // Resume where user left off (clamped), unless already completed
        if !RepairProgressStore.shared.isComplete(guideID: guide.id),
           let saved = RepairProgressStore.shared.savedStep(for: guide.id),
           saved >= 0, saved < guide.steps.count {
            self.currentStepIndex = saved
        }
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }

    /// Jump to a specific step (e.g. from StepDetail continuity). Clamped.
    func setInitialStep(_ index: Int) {
        guard !guide.steps.isEmpty else { return }
        currentStepIndex = max(0, min(index, guide.steps.count - 1))
        // Persist immediately so relaunch resumes here too
        RepairProgressStore.shared.save(step: currentStepIndex, for: guide.id)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupSpriteOverlay()
        setupUI()
        setupGestures()
        initializeScene()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkCameraPermissionAndStart()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    // MARK: - AR Setup

    private func setupARView() {
        arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.delegate = self
        arView.session.delegate = self
        arView.antialiasingMode = .multisampling4X
        arView.autoenablesDefaultLighting = true
        arView.rendersContinuously = true
        view.addSubview(arView)

        sceneManager = ARSceneManager(scene: arView.scene)
        detectionService = DeviceDetectionService()
    }

    private func setupSpriteOverlay() {
        spriteScene = SKScene(size: view.bounds.size)
        spriteScene.backgroundColor = .clear
        spriteScene.scaleMode = .resizeFill

        // Wire overlay so SKNodes actually render on top of AR
        arView.overlaySKScene = spriteScene
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Keep overlay coords in sync with view size (rotation / layout)
        guard spriteScene != nil else { return }
        if spriteScene.size != view.bounds.size {
            spriteScene.size = view.bounds.size
        }
    }

    private func checkCameraPermissionAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startARSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startARSession()
                    } else {
                        self?.showCameraDenied()
                    }
                }
            }
        case .denied, .restricted:
            showCameraDenied()
        @unknown default:
            startARSession()
        }
    }

    private func showCameraDenied() {
        loadingOverlay.isHidden = true
        let alert = UIAlertController(
            title: "Camera needed",
            message: "RepairAR needs camera access for AR. Enable it in Settings > Privacy > Camera.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in
            self?.closeTapped()
        })
        present(alert, animated: true)
    }

    private func startARSession() {
        // Single source of truth for config (ARSceneManager)
        let referenceImages = detectionService.createReferenceSet()
        let configuration = sceneManager.createConfiguration(with: referenceImages)

        // Reset anchor glue on fresh session (old image nodes are invalid after reset)
        deviceAnchorNode = nil
        sceneManager.anchorNode = nil
        hasAnchoredToImage = false

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        // Progress indicator
        progressView = ProgressIndicatorView(totalSteps: guide.totalSteps)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        // Status label (detection state)
        statusLabel = UILabel()
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        statusLabel.layer.cornerRadius = 12
        statusLabel.clipsToBounds = true
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.alpha = 0
        view.addSubview(statusLabel)

        // Step card
        stepCard = StepCardView()
        stepCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepCard)

        // Navigation buttons
        previousButton = createNavButton(systemName: "chevron.left", action: #selector(previousStep))
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previousButton)

        nextButton = createNavButton(systemName: "chevron.right", action: #selector(nextStep))
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextButton)

        // Loading overlay
        setupLoadingOverlay()

        // Constraints
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            progressView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            progressView.heightAnchor.constraint(equalToConstant: 20),

            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
            statusLabel.heightAnchor.constraint(equalToConstant: 28),

            stepCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            stepCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            stepCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),
            stepCard.heightAnchor.constraint(equalToConstant: cardHeight),

            previousButton.centerYAnchor.constraint(equalTo: stepCard.centerYAnchor),
            previousButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            previousButton.widthAnchor.constraint(equalToConstant: buttonSize),
            previousButton.heightAnchor.constraint(equalToConstant: buttonSize),

            nextButton.centerYAnchor.constraint(equalTo: stepCard.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            nextButton.widthAnchor.constraint(equalToConstant: buttonSize),
            nextButton.heightAnchor.constraint(equalToConstant: buttonSize),
        ])
    }

    private func setupLoadingOverlay() {
        loadingOverlay = UIView()
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.isHidden = true
        view.addSubview(loadingOverlay)

        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = UIColor(hex: "#00D4FF")
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        loadingOverlay.addSubview(spinner)

        loadingLabel = UILabel()
        loadingLabel.text = "Detecting device..."
        loadingLabel.textColor = .white
        loadingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor, constant: -20),

            loadingLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            loadingLabel.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
        ])
    }

    private func createNavButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = buttonSize / 2
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Gestures

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)

        let hitResults = arView.hitTest(location, options: [
            .searchMode: SCNHitTestSearchMode.all.rawValue,
            .ignoreHiddenNodes: true
        ])

        // Walk up parent chain — container nodes have no name, child geometry does
        if let result = hitResults.first {
            var node: SCNNode? = result.node
            while let n = node {
                if let name = n.name,
                   let component = device.components.first(where: { $0.id == name }) {
                    showComponentInfo(component)
                    return
                }
                node = n.parent
            }
        }
        dismissComponentInfo()
    }

    // MARK: - Scene Initialization

    private func initializeScene() {
        // Set initial component states
        for component in device.components {
            componentStates[component.id] = .notReached
        }

        // Show detection state
        showStatus("Selecting device...")

        // Simulate device detection and start
        detectionService.onStateChange { [weak self] state in
            DispatchQueue.main.async {
                self?.handleDetectionState(state)
            }
        }

        loadingOverlay.isHidden = false
        detectionService.simulateDetection(of: device)
    }

    private func handleDetectionState(_ state: DeviceDetectionService.DetectionState) {
        switch state {
        case .searching:
            showStatus("Detecting device...")
        case .detected:
            loadingOverlay.isHidden = true
            placeComponentOverlays()
            updateStepUI()
            if currentStepIndex > 0 {
                showStatus("Resumed at step \(currentStepIndex + 1)/\(guide.totalSteps)")
            } else {
                showStatus("Device detected!")
            }

            // Fade out status after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                UIView.animate(withDuration: 0.3) {
                    self?.statusLabel.alpha = 0
                }
            }

        case .lost:
            showStatus("Device lost — refocus camera")
        case .error(let error):
            loadingOverlay.isHidden = true
            showStatus(error.localizedDescription)
        case .idle:
            break
        }
    }

    // MARK: - Component Overlay Placement

    private func placeComponentOverlays() {
        // Remove existing overlays
        componentNodes.values.forEach { $0.removeFromParentNode() }
        componentNodes.removeAll()

        // Place an overlay node for each component
        for component in device.components {
            let state = componentStates[component.id] ?? .notReached
            let node = ComponentOverlayNode(component: component, state: state)
            sceneManager.placeNode(node, at: component.position)
            componentNodes[component.id] = node
        }

        // Update states for current step
        updateComponentStates()
    }

    private func updateComponentStates() {
        guard currentStepIndex < guide.steps.count else { return }
        let currentStep = guide.steps[currentStepIndex]

        // Reset all first so going backwards clears stale completed states
        for key in componentStates.keys {
            componentStates[key] = .notReached
        }

        // Mark completed steps' components
        for i in 0..<currentStepIndex {
            let step = guide.steps[i]
            for componentID in step.componentIDs {
                componentStates[componentID] = .completed
            }
        }

        // Mark current step's components as focus (overrides completed for shared IDs)
        for componentID in currentStep.componentIDs {
            componentStates[componentID] = .currentFocus
        }

        // Update overlay nodes
        for (componentID, node) in componentNodes {
            let state = componentStates[componentID] ?? .notReached
            node.updateState(state)
        }

        // Update annotations
        updateAnnotations(for: currentStep)
    }

    // MARK: - Annotations

    private func updateAnnotations(for step: RepairStep) {
        // Fade out old annotations instead of instant remove (uses animateOut)
        let old = Array(annotationNodes.values)
        annotationNodes.removeAll()
        for node in old {
            node.animateOut {}
        }

        // Add annotations for highlighted components
        for componentID in step.componentIDs {
            guard let component = device.components.first(where: { $0.id == componentID }),
                  let node = componentNodes[componentID] else { continue }

            let annotation = AnnotationNode(
                text: component.name,
                detail: step.title,
                color: UIColor(hex: "#00D4FF")
            )

            // Project 3D world position to 2D overlay (SKScene coords, origin bottom-left)
            let worldPos = node.presentation.worldPosition
            let screenPos = arView.projectPoint(worldPos)
            // Behind camera (z > 1) — skip so we don't place off-screen labels
            guard screenPos.z < 1.0 else { continue }
            annotation.position = CGPoint(
                x: CGFloat(screenPos.x),
                y: spriteScene.size.height - CGFloat(screenPos.y)
            )
            spriteScene.addChild(annotation)
            annotationNodes[componentID] = annotation
        }
    }

    // MARK: - Step Navigation

    @objc private func nextStep() {
        guard currentStepIndex < guide.steps.count - 1 else {
            showCompletionHaptic()
            progressView.markComplete()
            RepairProgressStore.shared.markComplete(guideID: guide.id)
            showStatus("Guide complete!")
            showCompletionAlert()
            return
        }

        currentStepIndex += 1
        updateStepUI()
        updateComponentStates()
        stepCompletionHaptic()
    }

    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: "Repair complete",
            message: guide.conclusion ?? "Nice work. Reassemble in reverse order and test before closing up.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Review steps", style: .cancel))
        alert.addAction(UIAlertAction(title: "Restart", style: .default) { [weak self] _ in
            guard let self = self else { return }
            RepairProgressStore.shared.clear(guideID: self.guide.id)
            self.currentStepIndex = 0
            self.updateStepUI()
            self.updateComponentStates()
        })
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.closeTapped()
        })
        present(alert, animated: true)
    }

    @objc private func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        updateStepUI()
        updateComponentStates()
    }

    private func updateStepUI() {
        guard currentStepIndex < guide.steps.count else { return }
        let step = guide.steps[currentStepIndex]

        stepCard.configure(
            stepNumber: step.stepNumber,
            title: step.title,
            instruction: step.instruction,
            warnings: step.warnings,
            tips: step.tips
        )

        progressView.setCurrentStep(currentStepIndex)
        // Persist for resume
        RepairProgressStore.shared.save(step: currentStepIndex, for: guide.id)

        // Update nav button states
        previousButton.alpha = currentStepIndex > 0 ? 1.0 : 0.3
        nextButton.alpha = currentStepIndex < guide.steps.count - 1 ? 1.0 : 0.3

        // Animate card update
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Component Info

    private func showComponentInfo(_ component: Component) {
        dismissComponentInfo()

        let infoView = ComponentInfoView(component: component)
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.onDismiss = { [weak self] in
            self?.dismissComponentInfo()
        }
        view.addSubview(infoView)

        NSLayoutConstraint.activate([
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            infoView.bottomAnchor.constraint(equalTo: stepCard.topAnchor, constant: -12),
        ])

        infoView.transform = CGAffineTransform(translationX: 0, y: 20)
        infoView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            infoView.transform = .identity
            infoView.alpha = 1
        }

        // Temporarily highlight the component
        if let node = componentNodes[component.id] {
            node.updateState(.highlight)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                let state = self.componentStates[component.id] ?? .notReached
                node.updateState(state)
            }
        }

        componentInfoView = infoView
    }

    private func dismissComponentInfo() {
        guard let infoView = componentInfoView else { return }
        UIView.animate(withDuration: 0.2, animations: {
            infoView.alpha = 0
            infoView.transform = CGAffineTransform(translationX: 0, y: 20)
        }) { _ in
            infoView.removeFromSuperview()
        }
        componentInfoView = nil
    }

    // MARK: - Status & Haptics

    private func showStatus(_ message: String) {
        statusLabel.text = "  \(message)  "
        UIView.animate(withDuration: 0.3) {
            self.statusLabel.alpha = 1
        }
    }

    private func stepCompletionHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func showCompletionHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        arView.session.pause()
        dismiss(animated: true)
    }
}

// MARK: - ARSCNViewDelegate

extension ARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else { return nil }
        let physicalSize = imageAnchor.referenceImage.physicalSize
        let plane = SCNPlane(width: physicalSize.width, height: physicalSize.height)
        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2
        node.opacity = 0
        return node
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARImageAnchor else { return }
        // Real device anchor found — glue overlays to it so they don't drift
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.deviceAnchorNode = node
            // Future placements go straight under anchor
            self.sceneManager.anchorNode = node
            // Move existing world-origin overlays under anchor (keep local layout)
            if !self.componentNodes.isEmpty && !self.hasAnchoredToImage {
                self.hasAnchoredToImage = true
                self.sceneManager.reparentAll(to: node)
                // Grounding surface for visual stability
                let surface = self.sceneManager.createDeviceSurface()
                node.addChildNode(surface)
                self.showStatus("Anchored to device")
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Throttle to 20fps + skip when nothing to track (was 60Hz main dispatch)
        guard time - lastAnnotationUpdate >= annotationUpdateInterval else { return }
        guard !annotationNodes.isEmpty else { return }
        lastAnnotationUpdate = time
        DispatchQueue.main.async { [weak self] in
            self?.updateAnnotationScreenPositions()
        }
    }

    private func updateAnnotationScreenPositions() {
        guard arView != nil, spriteScene != nil else { return }
        for (componentID, annotation) in annotationNodes {
            guard let overlayNode = componentNodes[componentID] else { continue }
            let worldPos = overlayNode.presentation.worldPosition
            let screenPos = arView.projectPoint(worldPos)

            // Hide labels for points behind camera
            if screenPos.z > 1.0 {
                annotation.alpha = 0
                continue
            }
            annotation.alpha = 1
            annotation.position = CGPoint(
                x: CGFloat(screenPos.x),
                y: spriteScene.size.height - CGFloat(screenPos.y)
            )
        }
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showStatus("AR Error: \(error.localizedDescription)")
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.showStatus("AR session interrupted")
        }
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.startARSession()
        }
    }
}
