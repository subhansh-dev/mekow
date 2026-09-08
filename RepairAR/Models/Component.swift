import Foundation
import SceneKit

// MARK: - Component Type
enum ComponentType: String, Codable, CaseIterable {
    case screw = "screw"
    case component = "component"
    case cable = "cable"
    case connector = "connector"
    case adhesive = "adhesive"
    case battery = "battery"
    case display = "display"
    case storage = "storage"
    case memory = "memory"
    case fan = "fan"
    case board = "board"
}

// MARK: - Component Position in AR
struct ComponentPosition: Codable {
    let x: Double
    let y: Double
    let width: Double?
    let height: Double?
    let zOffset: Double?

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }

    var vector3: SCNVector3 {
        SCNVector3(Float(x), Float(y), Float(zOffset ?? 0))
    }
}

// MARK: - Component
struct Component: Codable, Identifiable {
    let id: String
    let name: String
    let type: ComponentType
    let description: String
    let position: ComponentPosition
    let toolsRequired: [String]
    let removalSteps: [String]
    let size: ComponentSize?
    let color: String?

    struct ComponentSize: Codable {
        let width: Double
        let height: Double
    }
}

// MARK: - Component State for AR Overlay
enum ComponentState {
    case notReached     // subtle outline
    case currentFocus   // bright cyan glow, pulsing
    case completed      // dimmed/transparent
    case highlight      // temporary highlight on tap
}

extension ComponentState {
    var glowColor: UIColor {
        switch self {
        case .notReached:
            return UIColor.white.withAlphaComponent(0.2)
        case .currentFocus:
            return UIColor(hex: "#00D4FF")
        case .completed:
            return UIColor.white.withAlphaComponent(0.08)
        case .highlight:
            return UIColor(hex: "#FFD700")
        }
    }

    var glowIntensity: CGFloat {
        switch self {
        case .notReached:
            return 0.2
        case .currentFocus:
            return 1.0
        case .completed:
            return 0.05
        case .highlight:
            return 0.8
        }
    }

    var animationDuration: TimeInterval {
        switch self {
        case .notReached:
            return 0.0
        case .currentFocus:
            return 1.5
        case .completed:
            return 0.5
        case .highlight:
            return 0.3
        }
    }
}

// MARK: - Tool Model
struct Tool: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
}
