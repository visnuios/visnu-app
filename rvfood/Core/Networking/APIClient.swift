import Foundation

struct APIEnvelope<DataModel: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: DataModel?
}

enum APIError: Error, Equatable {
    case invalidURL
    case network(String)
    case server(statusCode: Int, message: String?)
    case unauthorized
    case decoding(String)
    case notFound
    case outOfStock
    case businessRule(String)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Something went wrong. Please try again."
        case .network(let reason):
            return "No internet connection. \(reason)"
        case .server(_, let message):
            return message ?? "Server error. Please try again later."
        case .unauthorized:
            return "Please login to continue."
        case .decoding:
            return "Received an unexpected response from the server."
        case .notFound:
            return "Not found."
        case .outOfStock:
            return "This item is out of stock."
        case .businessRule(let message):
            return message
        }
    }
}

protocol APIClientProtocol {
    func get<ResponseModel: Decodable>(_ path: String, query: [String: String]) async throws -> ResponseModel
    func post<Body: Encodable, ResponseModel: Decodable>(_ path: String, body: Body?) async throws -> ResponseModel
    func put<Body: Encodable, ResponseModel: Decodable>(_ path: String, body: Body?) async throws -> ResponseModel
    func delete<ResponseModel: Decodable>(_ path: String) async throws -> ResponseModel
}

final class URLSessionAPIClient: APIClientProtocol {

    static let shared = URLSessionAPIClient(baseURL: URL(string: "https://api.example.com")!)

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<ResponseModel: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> ResponseModel {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    func post<Body: Encodable, ResponseModel: Decodable>(_ path: String, body: Body?) async throws -> ResponseModel {
        try await sendWithBody(path, body: body, method: "POST")
    }

    func put<Body: Encodable, ResponseModel: Decodable>(_ path: String, body: Body?) async throws -> ResponseModel {
        try await sendWithBody(path, body: body, method: "PUT")
    }

    func delete<ResponseModel: Decodable>(_ path: String) async throws -> ResponseModel {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        return try await perform(request)
    }

    private func sendWithBody<Body: Encodable, ResponseModel: Decodable>(
        _ path: String,
        body: Body?,
        method: String
    ) async throws -> ResponseModel {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try? JSONEncoder().encode(body)
        }
        return try await perform(request)
    }

    private func perform<ResponseModel: Decodable>(_ request: URLRequest) async throws -> ResponseModel {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.network("Invalid response")
            }
            switch http.statusCode {
            case 200..<300:
                let envelope = try? JSONDecoder().decode(APIEnvelope<ResponseModel>.self, from: data)
                if let envelope {
                    if !envelope.success {
                        throw APIError.businessRule(envelope.message ?? "Request failed")
                    }
                    guard let payload = envelope.data else {
                        throw APIError.decoding("Missing data")
                    }
                    return payload
                }
                return try JSONDecoder().decode(ResponseModel.self, from: data)
            case 401:
                throw APIError.unauthorized
            case 404:
                throw APIError.notFound
            default:
                let envelope = try? JSONDecoder().decode(APIEnvelope<EmptyPayload>.self, from: data)
                throw APIError.server(statusCode: http.statusCode, message: envelope?.message)
            }
        } catch let error as APIError {
            throw error
        } catch is URLError {
            throw APIError.network("Check your connection and try again.")
        } catch is DecodingError {
            throw APIError.decoding("Unexpected payload")
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }
}

private struct EmptyPayload: Decodable {}
