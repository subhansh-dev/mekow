import Foundation

/// A single step in a repair guide, with instructions, component highlights, and required tools.
struct RepairStep: Codable, Identifiable {
    let id: String
    let stepNumber: Int
    let title: String
    let instruction: String
    let imageURL: String?
    let videoURL: String?
    let componentIDs: [String]
    let highlightColor: String?
    let toolsNeeded: [String]
    let warnings: [String]
    let tips: [String]
    let duration: Int? // estimated seconds for this step

    var durationFormatted: String? {
        guard let duration = duration else { return nil }
        if duration < 60 {
            return "\(duration)s"
        }
        let mins = duration / 60
        let secs = duration % 60
        if secs == 0 {
            return "\(mins)m"
        }
        return "\(mins)m \(secs)s"
    }

    var hasWarnings: Bool {
        !warnings.isEmpty
    }

    var hasTips: Bool {
        !tips.isEmpty
    }
}
