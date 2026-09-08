import Foundation
import ARKit

// MARK: - Device Detection Service
// Handles AR-based device detection using image tracking.

final class DeviceDetectionService: NSObject {

    // MARK: - Types

    enum DetectionState {
        case idle
        case searching
        case detected(Device)
        case lost
        case error(Error)
    }

    enum DetectionError: Error, LocalizedError {
        case imageTrackingNotSupported
        case noReferenceImages
        case detectionFailed

        var errorDescription: String? {
            switch self {
            case .imageTrackingNotSupported:
                return "Image tracking is not supported on this device."
            case .noReferenceImages:
                return "No reference images available for detection."
            case .detectionFailed:
                return "Could not identify the device. Try adjusting the camera angle."
            }
        }
    }

    // MARK: - Properties

    private var detectionState: DetectionState = .idle
    private var stateCallbacks: [(DetectionState) -> Void] = []
    private var knownDeviceImages: [String: UIImage] = [:]
    private var detectionTimer: Timer?
    private let detectionTimeout: TimeInterval = 30.0

    var currentState: DetectionState {
        detectionState
    }

    // MARK: - State Management

    func onStateChange(_ callback: @escaping (DetectionState) -> Void) {
        stateCallbacks.append(callback)
    }

    private func updateState(_ newState: DetectionState) {
        detectionState = newState
        DispatchQueue.main.async { [weak self] in
            self?.stateCallbacks.forEach { $0(newState) }
        }
    }

    // MARK: - Detection

    /// Start searching for a device in the AR scene.
    func startDetection(for device: Device) {
        updateState(.searching)

        // Set up detection timeout
        detectionTimer?.invalidate()
        detectionTimer = Timer.scheduledTimer(withTimeInterval: detectionTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if case .searching = self.detectionState {
                self.updateState(.error(DetectionError.detectionFailed))
            }
        }

        // For demo purposes, simulate detection after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self, case .searching = self.detectionState else { return }
            self.detectionTimer?.invalidate()
            self.updateState(.detected(device))
        }
    }

    /// Register a reference image for AR image tracking.
    func registerReferenceImage(_ image: UIImage, for deviceID: String) {
        knownDeviceImages[deviceID] = image
    }

    /// Create an AR reference image set from registered images.
    func createReferenceSet() -> Set<ARReferenceImage> {
        var references: Set<ARReferenceImage> = []
        for (deviceID, image) in knownDeviceImages {
            guard let cgImage = image.cgImage else { continue }
            let reference = ARReferenceImage(cgImage, orientation: .up, physicalWidth: 0.3)
            reference.name = deviceID
            references.insert(reference)
        }
        return references
    }

    /// Process AR frame results for image detection.
    func processDetectedImages(_ anchors: [ARImageAnchor]) -> Device? {
        guard let bestMatch = anchors.max(by: { $0.confidence < $1.confidence }),
              let deviceID = bestMatch.referenceImage.name else {
            return nil
        }

        // In a real app, look up the device by ID from DataManager
        // For now, return nil and let the simulated detection handle it
        return nil
    }

    /// Stop detection and clean up.
    func stopDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
        updateState(.idle)
    }

    /// Manually trigger device detection (for demo/testing).
    func simulateDetection(of device: Device) {
        updateState(.searching)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.updateState(.detected(device))
        }
    }
}

// MARK: - ARSession Delegate (optional integration)

extension DeviceDetectionService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let imageAnchors = anchors.compactMap { $0 as? ARImageAnchor }
        if !imageAnchors.isEmpty {
            _ = processDetectedImages(imageAnchors)
        }
    }
}
