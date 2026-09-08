import SceneKit

// MARK: - SCNVector3 Helpers

extension SCNVector3 {

    /// Zero vector.
    static let zero = SCNVector3(0, 0, 0)

    /// Up direction (Y+).
    static let up = SCNVector3(0, 1, 0)

    /// Forward direction (Z-).
    static let forward = SCNVector3(0, 0, -1)

    // MARK: - Arithmetic

    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    static func / (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        SCNVector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    // MARK: - Magnitude

    var length: Float {
        sqrtf(x * x + y * y + z * z)
    }

    var lengthSquared: Float {
        x * x + y * y + z * z
    }

    // MARK: - Normalization

    var normalized: SCNVector3 {
        let len = length
        guard len > 0 else { return .zero }
        return self / len
    }

    // MARK: - Distance

    func distance(to other: SCNVector3) -> Float {
        (self - other).length
    }

    // MARK: - Dot Product

    func dot(_ other: SCNVector3) -> Float {
        x * other.x + y * other.y + z * other.z
    }

    // MARK: - Cross Product

    func cross(_ other: SCNVector3) -> SCNVector3 {
        SCNVector3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }

    // MARK: - Linear Interpolation

    func lerp(to target: SCNVector3, t: Float) -> SCNVector3 {
        let clampedT = min(max(t, 0), 1)
        return SCNVector3(
            x + (target.x - x) * clampedT,
            y + (target.y - y) * clampedT,
            z + (target.z - z) * clampedT
        )
    }

    // MARK: - Conversion

    /// Convert from CGPoint (2D) with optional Z.
    init(from point: CGPoint, z: Float = 0) {
        self.init(Float(point.x), Float(point.y), z)
    }

    /// Convert to CGPoint (drops Z).
    var cgPoint: CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

// MARK: - SCNQuaternion Helpers

extension SCNQuaternion {

    /// Create a quaternion from Euler angles (radians).
    static func fromEuler(x: Float, y: Float, z: Float) -> SCNQuaternion {
        let cx = cosf(x / 2)
        let sx = sinf(x / 2)
        let cy = cosf(y / 2)
        let sy = sinf(y / 2)
        let cz = cosf(z / 2)
        let sz = sinf(z / 2)

        return SCNQuaternion(
            sx * cy * cz - cx * sy * sz,
            cx * sy * cz + sx * cy * sz,
            cx * cy * sz - sx * sy * cz,
            cx * cy * cz + sx * sy * sz
        )
    }
}
