import Foundation

/// Represents a repair guide for a specific device.
struct RepairGuide: Codable, Identifiable {
    let id: String
    let title: String
    let deviceID: String
    let deviceName: String
    let difficulty: Difficulty
    let timeEstimateMinutes: Int
    let rating: Double
    let ratingCount: Int
    let introduction: String?
    let conclusion: String?
    let imageURL: String?
    let steps: [RepairStep]
    let toolsRequired: [String]
    let author: String?
    let lastUpdated: Date?

    var timeEstimateFormatted: String {
        if timeEstimateMinutes < 60 {
            return "\(timeEstimateMinutes) min"
        }
        let hours = timeEstimateMinutes / 60
        let mins = timeEstimateMinutes % 60
        if mins == 0 {
            return "\(hours) hr"
        }
        return "\(hours) hr \(mins) min"
    }

    var totalSteps: Int {
        steps.count
    }

    // MARK: - Difficulty
    enum Difficulty: String, Codable, CaseIterable {
        case easy = "easy"
        case moderate = "moderate"
        case difficult = "difficult"
        case expert = "expert"

        var displayName: String {
            switch self {
            case .easy: return "Easy"
            case .moderate: return "Moderate"
            case .difficult: return "Difficult"
            case .expert: return "Expert"
            }
        }

        var colorHex: String {
            switch self {
            case .easy: return "#4CAF50"
            case .moderate: return "#FF9800"
            case .difficult: return "#F44336"
            case .expert: return "#9C27B0"
            }
        }
    }
}
