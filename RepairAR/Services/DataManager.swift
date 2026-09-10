import Foundation

// MARK: - Data Manager
// Orchestrates data loading, caching, and offline support.

final class DataManager {

    // MARK: - Types

    enum DataError: Error, LocalizedError {
        case deviceNotFound
        case guideNotFound
        case loadFailed(String)
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .deviceNotFound:
                return "Device not found."
            case .guideNotFound:
                return "Repair guide not found."
            case .loadFailed(let detail):
                return "Failed to load data: \(detail)"
            case .decodingFailed(let detail):
                return "Failed to parse data: \(detail)"
            }
        }
    }

    // MARK: - Properties

    static let shared = DataManager()

    private let ifixitService = IFixitService.shared
    private let fileCache = NSCache<NSString, NSData>()

    // In-memory device cache
    private var devices: [Device] = []
    private var guides: [String: RepairGuide] = [:]
    private var isLoaded = false

    // MARK: - Initialization

    init() {
        fileCache.countLimit = 50
    }

    // MARK: - Data Loading

    /// Load all bundled sample data.
    func loadSampleData() throws -> [Device] {
        if isLoaded, !devices.isEmpty {
            return devices
        }

        guard let url = Bundle.main.url(forResource: "SampleDevices", withExtension: "json") else {
            throw DataError.loadFailed("SampleDevices.json not found in bundle.")
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        let sampleData = try decoder.decode(SampleData.self, from: data)

        devices = sampleData.devices
        for guide in sampleData.guides {
            guides[guide.id] = guide
        }

        isLoaded = true
        return devices
    }

    // MARK: - Device Access

    /// Get all available devices.
    func getAllDevices() -> [Device] {
        if devices.isEmpty {
            do {
                _ = try loadSampleData()
            } catch {
                print("[DataManager] Failed to load sample data: \(error)")
            }
        }
        return devices
    }

    /// Get a specific device by ID.
    func getDevice(id: String) -> Device? {
        devices.first { $0.id == id }
    }

    /// Search devices by name.
    func searchDevices(query: String) -> [Device] {
        let lowered = query.lowercased()
        return devices.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.manufacturer.lowercased().contains(lowered) ||
            $0.category.lowercased().contains(lowered)
        }
    }

    // MARK: - Guide Access

    /// Get guides for a specific device.
    func getGuides(for deviceID: String) -> [RepairGuide] {
        guides.values.filter { $0.deviceID == deviceID }
    }

    /// Get a specific guide by ID.
    func getGuide(id: String) -> RepairGuide? {
        guides[id]
    }

    // MARK: - iFixit Integration

    /// Search iFixit for additional guides (returns raw search hits).
    /// Use fetchOnlineGuide(guideID:) with IFixitService.guideID(from:) to get full bodies,
    /// or searchAndFetchOnlineGuides(query:) for one-shot full guides.
    func searchOnlineGuides(query: String) async -> Result<IFixitService.SearchResult, IFixitService.APIError> {
        return await ifixitService.searchGuides(query: query)
    }

    /// Search + fetch full guide bodies (max 5).
    func searchAndFetchOnlineGuides(query: String) async -> Result<[IFixitService.IFixitGuide], IFixitService.APIError> {
        return await ifixitService.searchAndFetchGuides(query: query)
    }

    /// Fetch a specific iFixit guide.
    func fetchOnlineGuide(guideID: Int) async -> Result<IFixitService.IFixitGuide, IFixitService.APIError> {
        return await ifixitService.fetchGuide(guideID: guideID)
    }

    /// Convert an iFixit guide to our local model.
    func convertIFixitGuide(_ ifixitGuide: IFixitService.IFixitGuide) -> RepairGuide {
        let steps: [RepairStep] = (ifixitGuide.steps ?? []).enumerated().map { index, step in
            let instruction = step.lines?.compactMap { $0.text_raw }.joined(separator: "\n") ?? step.title ?? ""
            return RepairStep(
                id: "ifixit-\(ifixitGuide.guideid)-step-\(step.stepid)",
                stepNumber: index + 1,
                title: step.title ?? "Step \(index + 1)",
                instruction: instruction,
                imageURL: step.images?.first?.large ?? step.images?.first?.original,
                videoURL: nil,
                componentIDs: [],
                highlightColor: nil,
                toolsNeeded: [],
                warnings: [],
                tips: [],
                duration: nil
            )
        }

        let difficulty: RepairGuide.Difficulty
        switch ifixitGuide.difficulty?.lowercased() {
        case "easy": difficulty = .easy
        case "moderate": difficulty = .moderate
        case "difficult": difficulty = .difficult
        case "expert": difficulty = .expert
        default: difficulty = .moderate
        }

        let timeEstimate: Int
        if let timeStr = ifixitGuide.timeRequired {
            let components = timeStr.components(separatedBy: " ")
            timeEstimate = Int(components.first ?? "30") ?? 30
        } else {
            timeEstimate = 30
        }

        return RepairGuide(
            id: "ifixit-\(ifixitGuide.guideid)",
            title: ifixitGuide.title,
            deviceID: ifixitGuide.category ?? "unknown",
            deviceName: ifixitGuide.subject ?? ifixitGuide.category ?? "Unknown Device",
            difficulty: difficulty,
            timeEstimateMinutes: timeEstimate,
            rating: 0.0,
            ratingCount: 0,
            introduction: ifixitGuide.introduction,
            conclusion: ifixitGuide.conclusion,
            imageURL: ifixitGuide.image?.large ?? ifixitGuide.image?.original,
            steps: steps,
            toolsRequired: [],
            author: nil,
            lastUpdated: nil
        )
    }
}

// MARK: - Sample Data Wrapper

struct SampleData: Codable {
    let devices: [Device]
    let guides: [RepairGuide]
}

// MARK: - Repair Progress Store (UserDefaults, resume + completion)

final class RepairProgressStore {
    static let shared = RepairProgressStore()

    private let defaults = UserDefaults.standard

    private func stepKey(for guideID: String) -> String { "repairar.step.\(guideID)" }
    private func doneKey(for guideID: String) -> String { "repairar.done.\(guideID)" }

    func savedStep(for guideID: String) -> Int? {
        // Integer returns 0 when missing — check existence first
        guard defaults.object(forKey: stepKey(for: guideID)) != nil else { return nil }
        return defaults.integer(forKey: stepKey(for: guideID))
    }

    func save(step: Int, for guideID: String) {
        defaults.set(step, forKey: stepKey(for: guideID))
    }

    func markComplete(guideID: String) {
        defaults.set(true, forKey: doneKey(for: guideID))
    }

    func isComplete(guideID: String) -> Bool {
        defaults.bool(forKey: doneKey(for: guideID))
    }

    func clear(guideID: String) {
        defaults.removeObject(forKey: stepKey(for: guideID))
        defaults.removeObject(forKey: doneKey(for: guideID))
    }
}
