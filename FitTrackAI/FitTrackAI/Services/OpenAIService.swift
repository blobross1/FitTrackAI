import Foundation
import UIKit

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidImage
    case invalidResponse
    case httpError(Int, String)
    case decodeError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is not configured. Add your key in Settings."
        case .invalidImage:
            return "Could not prepare the photo for analysis."
        case .invalidResponse:
            return "OpenAI returned an unexpected response."
        case .httpError(let code, let message):
            return "OpenAI error (\(code)): \(message)"
        case .decodeError(let message):
            return "Could not read analysis result: \(message)"
        }
    }
}

struct OpenAIService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func analyzeBodyFat(imageData: Data, weightKg: Double?) async throws -> BodyFatAnalysis {
        guard let apiKey = OpenAIConfig.apiKey else { throw OpenAIError.missingAPIKey }
        guard let jpeg = ImagePreprocessor.jpegForAPI(from: imageData) else {
            throw OpenAIError.invalidImage
        }

        let base64 = jpeg.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"
        let prompt = BodyFatNormalizer.analysisPrompt(weightKg: weightKg)

        let body = ChatCompletionRequest(
            model: LLMConfig.bodyFatModel,
            messages: [
                .init(role: "user", content: [
                    .text(prompt),
                    .image(dataURL)
                ])
            ],
            responseFormat: .jsonSchema(BodyFatJSONSchema.definition)
        )

        var request = URLRequest(url: LLMConfig.apiBaseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }

        if !(200...299).contains(http.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.httpError(http.statusCode, message)
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content,
              let contentData = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }

        do {
            let parsed = try JSONDecoder().decode(BodyFatLLMResponse.self, from: contentData)
            return BodyFatAnalysis(
                bodyFatLow: parsed.bodyFatLow,
                bodyFatHigh: parsed.bodyFatHigh,
                feedback: parsed.feedback
            )
        } catch {
            throw OpenAIError.decodeError(error.localizedDescription)
        }
    }
}

// MARK: - Request / response types

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model, messages
        case responseFormat = "response_format"
    }
}

private struct ChatMessage: Encodable {
    let role: String
    let content: [ContentPart]
}

private enum ContentPart: Encodable {
    case text(String)
    case image(String)

    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .image(let url):
            try container.encode("image_url", forKey: .type)
            try container.encode(ImageURLContainer(url: url), forKey: .imageURL)
        }
    }
}

private struct ImageURLContainer: Encodable {
    let url: String
}

private enum ResponseFormat: Encodable {
    case jsonSchema(JSONSchemaWrapper)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .jsonSchema(let schema):
            try container.encode("json_schema", forKey: .type)
            try container.encode(schema, forKey: .jsonSchema)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

private struct JSONSchemaWrapper: Encodable {
    let name: String
    let strict: Bool
    let schema: JSONSchemaDefinition
}

private struct JSONSchemaDefinition: Encodable {
    let type: String
    let properties: [String: PropertySchema]
    let required: [String]
    let additionalProperties: Bool

    enum CodingKeys: String, CodingKey {
        case type, properties, required
        case additionalProperties = "additionalProperties"
    }
}

private struct PropertySchema: Encodable {
    let type: String
}

private enum BodyFatJSONSchema {
    static let definition = JSONSchemaWrapper(
        name: "body_fat_analysis",
        strict: true,
        schema: JSONSchemaDefinition(
            type: "object",
            properties: [
                "body_fat_low": PropertySchema(type: "number"),
                "body_fat_high": PropertySchema(type: "number"),
                "feedback": PropertySchema(type: "string")
            ],
            required: ["body_fat_low", "body_fat_high", "feedback"],
            additionalProperties: false
        )
    )
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String?
    }
}

private struct BodyFatLLMResponse: Decodable {
    let bodyFatLow: Double
    let bodyFatHigh: Double
    let feedback: String

    enum CodingKeys: String, CodingKey {
        case bodyFatLow = "body_fat_low"
        case bodyFatHigh = "body_fat_high"
        case feedback
    }
}
