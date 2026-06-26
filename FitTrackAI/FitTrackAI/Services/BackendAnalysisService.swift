import Foundation
import UIKit

enum BackendError: LocalizedError {
    case notConfigured
    case invalidImage
    case invalidResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Analysis service is not configured. \(AppConfig.configurationDebugSummary)"
        case .invalidImage:
            return "Could not prepare the photo for analysis."
        case .invalidResponse:
            return "Unexpected response from server."
        case .httpError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

struct BackendAnalysisService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func analyzeBodyFat(imageData: Data, weightKg: Double?) async throws -> BodyFatAnalysis {
        guard let url = AppConfig.backendAnalyzeURL,
              let secret = AppConfig.backendSecret else {
            throw BackendError.notConfigured
        }

        guard let jpeg = ImagePreprocessor.jpegForAPI(from: imageData) else {
            throw BackendError.invalidImage
        }

        var body: [String: Any] = ["imageBase64": jpeg.base64EncodedString()]
        if let weightKg { body["weightKg"] = weightKg }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BackendError.invalidResponse }

        if !(200...299).contains(http.statusCode) {
            let message = parseErrorMessage(data) ?? "Unknown error"
            throw BackendError.httpError(http.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(BackendAnalysisResponse.self, from: data)
        return BodyFatAnalysis(
            bodyFatLow: decoded.bodyFatLow,
            bodyFatHigh: decoded.bodyFatHigh,
            feedback: decoded.feedback
        )
    }

    private func parseErrorMessage(_ data: Data) -> String? {
        struct Err: Decodable { let error: String? }
        return (try? JSONDecoder().decode(Err.self, from: data))?.error
    }
}

private struct BackendAnalysisResponse: Decodable {
    let bodyFatLow: Double
    let bodyFatHigh: Double
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case bodyFatLow = "body_fat_low"
        case bodyFatHigh = "body_fat_high"
        case feedback
    }
}

enum ImagePreprocessor {
    static func jpegForAPI(from data: Data, maxDimension: CGFloat = 1280, quality: CGFloat = 0.82) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return jpegForAPI(from: image, maxDimension: maxDimension, quality: quality)
    }

    static func jpegForAPI(from image: UIImage, maxDimension: CGFloat = 1280, quality: CGFloat = 0.82) -> Data? {
        let oriented = image.normalizedUpOrientation()
        let resized = resize(image: oriented, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }

    private static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension UIImage {
    /// Photos from the library often have EXIF orientation; OpenAI needs pixels upright.
    func normalizedUpOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
