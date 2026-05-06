import Foundation

final class SearchOrchestrator {
    private let extractor: SearchExtractor

    init(extractor: SearchExtractor) {
        self.extractor = extractor
    }

    func search(_ query: String) async -> [SearchResultOrError] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        return await withTaskGroup(of: [SearchResultOrError].self) { group in
            for platform in PlatformID.allCases {
                group.addTask { [extractor] in
                    do {
                        return try await extractor.extract(platform: platform, query: trimmedQuery)
                    } catch is CancellationError {
                        return []
                    } catch {
                        return [.error(platform: platform, message: error.localizedDescription)]
                    }
                }
            }

            var output: [SearchResultOrError] = []
            for await result in group {
                output.append(contentsOf: result)
            }

            return output.sortedForDisplay()
        }
    }
}

private extension Array where Element == SearchResultOrError {
    func sortedForDisplay() -> [SearchResultOrError] {
        sorted { lhs, rhs in
            guard lhs.platform == rhs.platform else {
                return lhs.platform.displayOrder < rhs.platform.displayOrder
            }

            switch (lhs, rhs) {
            case (.result, .error):
                return true
            case (.error, .result):
                return false
            default:
                return false
            }
        }
    }
}

private extension PlatformID {
    var displayOrder: Int {
        switch self {
        case .youtube:
            return 0
        case .spotify:
            return 1
        case .netease:
            return 2
        }
    }
}
