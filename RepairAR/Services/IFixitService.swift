import Foundation

// MARK: - iFixit API Service
// Communicates with the iFixit API v2.0 for device data and repair guides.

final class IFixitService {

    // MARK: - Types

    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case serverError(Int, String?)
        case rateLimited
        case notFound
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Data parsing error: \(error.localizedDescription)"
            case .serverError(let code, let message):
                return "Server error (\(code)): \(message ?? "Unknown")"
            case .rateLimited:
                return "Too many requests. Please wait a moment."
            case .notFound:
                return "The requested resource was not found."
            case .unknown:
                return "An unknown error occurred."
            }
        }
    }

    // iFixit API models
    struct IFixitGuide: Codable {
        let guideid: Int
        let title: String
        let category: String?
        let subject: String?
        let type: String?
        let difficulty: String?
        let timeRequired: String?
        let introduction: String?
        let conclusion: String?
        let image: IFixitImage?
        let steps: [IFixitStep]?

        enum CodingKeys: String, CodingKey {
            case guideid, title, category, subject, type, difficulty
            case timeRequired = "time_required"
            case introduction, conclusion, image, steps
        }
    }

    struct IFixitStep: Codable {
        let stepid: Int
        let title: String?
        let lines: [IFixitLine]?
        let images: [IFixitImage]?
        let orderby: Int?
    }

    struct IFixitLine: Codable {
        let text_raw: String?
        let text_rendered: String?
        let bullet: String?
    }

    struct IFixitImage: Codable {
        let id: Int?
        let original: String?
        let large: String?
        let medium: String?
        let small: String?
        let thumbnail: String?
        let standard: String?
        let mini: String?
    }

    struct IFixitDevice: Codable {
        let deviceid: Int?
        let name: String?
        let title: String?
        let category: String?
        let image: IFixitImage?
        let guideCount: Int?

        enum CodingKeys: String, CodingKey {
            case deviceid, name, title, category, image
            case guideCount = "guide_count"
        }
    }

    struct IFixitCategory: Codable {
        let name: String?
        let title: String?
        let locale: String?
        let image: IFixitImage?
        let displayTitle: String?

        enum CodingKeys: String, CodingKey {
            case name, title, locale, image
            case displayTitle = "display_title"
        }
    }

    struct SearchResult: Codable {
        let results: [SearchResultItem]?
        let total: Int?
    }

    struct SearchResultItem: Codable {
        let type: String?
        let title: String?
        let url: String?
        let image: IFixitImage?
        let objectID: String?

        enum CodingKeys: String, CodingKey {
            case type, title, url, image
            case objectID = "objectID"
        }
    }

    // MARK: - Properties

    static let shared = IFixitService()

    private let baseURL = "https://www.ifixit.com/api/2.0"
    private let session: URLSession
    private let cache = NSCache<NSString, CacheEntry>()
    private let decoder: JSONDecoder

    // Rate limiting
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 0.5

    // MARK: - Cache Entry Wrapper

    final class CacheEntry {
        let data: Data
        let timestamp: Date
        let ttl: TimeInterval

        init(data: Data, ttl: TimeInterval = 3600) {
            self.data = data
            self.timestamp = Date()
            self.ttl = ttl
        }

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }

    // MARK: - Init

    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = session ?? URLSession(configuration: config)

        self.decoder = JSONDecoder()
    }

    // MARK: - Public API

    /// Search iFixit for guides matching a query.
    func searchGuides(query: String) async -> Result<[IFixitGuide], APIError> {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/\(encoded)?limit=20") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url, useCache: true, cacheTTL: 1800)
    }

    /// Fetch a specific guide by ID.
    func fetchGuide(guideID: Int) async -> Result<IFixitGuide, APIError> {
        guard let url = URL(string: "\(baseURL)/guides/\(guideID)") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url, useCache: true, cacheTTL: 3600)
    }

    /// Fetch device information.
    func fetchDevice(deviceName: String) async -> Result<IFixitDevice, APIError> {
        guard let encoded = deviceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/devices/\(encoded)") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url, useCache: true, cacheTTL: 3600)
    }

    /// Browse a category.
    func fetchCategory(categoryName: String) async -> Result<IFixitCategory, APIError> {
        guard let encoded = categoryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/categories/\(encoded)") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url, useCache: true, cacheTTL: 7200)
    }

    /// Fetch guides for a specific device.
    func fetchGuidesForDevice(deviceName: String) async -> Result<[IFixitGuide], APIError> {
        guard let encoded = deviceName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/devices/\(encoded)/guides") else {
            return .failure(.invalidURL)
        }
        return await performRequest(url: url, useCache: true, cacheTTL: 1800)
    }

    // MARK: - Private Helpers

    private func performRequest<T: Decodable>(url: URL, useCache: Bool, cacheTTL: TimeInterval) async -> Result<T, APIError> {
        let cacheKey = NSString(string: url.absoluteString)

        // Check cache
        if useCache, let cached = cache.object(forKey: cacheKey), !cached.isExpired {
            do {
                let result = try decoder.decode(T.self, from: cached.data)
                return .success(result)
            } catch {
                // Cache corrupted, fetch fresh
            }
        }

        // Rate limiting
        await enforceRateLimit()

        do {
            let (data, response) = try await session.data(from: url)
            lastRequestTime = Date()

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknown)
            }

            switch httpResponse.statusCode {
            case 200...299:
                // Cache the response
                if useCache {
                    let entry = CacheEntry(data: data, ttl: cacheTTL)
                    cache.setObject(entry, forKey: cacheKey)
                }

                do {
                    let result = try decoder.decode(T.self, from: data)
                    return .success(result)
                } catch {
                    return .failure(.decodingError(error))
                }

            case 404:
                return .failure(.notFound)
            case 429:
                return .failure(.rateLimited)
            default:
                let message = String(data: data, encoding: .utf8)
                return .failure(.serverError(httpResponse.statusCode, message))
            }
        } catch {
            return .failure(.networkError(error))
        }
    }

    private func enforceRateLimit() async {
        guard let lastRequest = lastRequestTime else { return }
        let elapsed = Date().timeIntervalSince(lastRequest)
        if elapsed < minimumRequestInterval {
            let delay = minimumRequestInterval - elapsed
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    /// Clear all cached data.
    func clearCache() {
        cache.removeAllObjects()
    }
}
