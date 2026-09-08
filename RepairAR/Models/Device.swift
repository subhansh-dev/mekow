import Foundation

/// Represents a physical device that can be repaired (e.g., MacBook Pro 14" 2023).
struct Device: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let manufacturer: String
    let imageURL: String?
    let thumbnailURL: String?
    let year: Int?
    let components: [Component]
    let guideIDs: [String]

    var displayName: String {
        if let year = year {
            return "\(name) (\(year))"
        }
        return name
    }

    var componentCount: Int {
        components.count
    }

    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}

/// Lightweight device summary for list views.
struct DeviceSummary: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let manufacturer: String
    let thumbnailURL: String?
    let guideCount: Int
}
