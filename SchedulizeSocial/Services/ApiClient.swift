//
//  ApiClient.swift
//  SchedulizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized
}

class ApiClient {
    static let shared = ApiClient()

    private let baseURL = "https://social-reply-api-production.up.railway.app"

    private init() {}

    // MARK: - Authentication
    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        return try await post(endpoint: "/api/v1/auth/login", body: request)
    }

    func signup(email: String, password: String, fullName: String) async throws -> AuthResponse {
        let request = SignupRequest(email: email, password: password, name: fullName)
        return try await post(endpoint: "/api/v1/auth/signup", body: request)
    }

    // MARK: - Reply Generation
    func generateReplies(message: String, platform: String, includeEmojis: Bool = true) async throws -> GenerateReplyResponse {
        let request = GenerateReplyRequest(message: message, platform: platform, sender_info: nil, include_emojis: includeEmojis)
        return try await post(endpoint: "/api/v1/replies/generate", body: request, requiresAuth: true)
    }

    // MARK: - History
    func getHistory() async throws -> HistoryResponse {
        return try await get(endpoint: "/api/v1/replies/history", requiresAuth: true)
    }

    // MARK: - Scheduled Posts
    func getScheduledPosts() async throws -> ScheduledPostsResponse {
        return try await get(endpoint: "/api/v1/posts/scheduled", requiresAuth: true)
    }

    func createScheduledPost(content: String, platform: String, scheduledFor: String) async throws {
        let request = CreatePostRequest(content: content, platform: platform, scheduled_for: scheduledFor, topic: nil, hashtags: nil, tone: nil)
        let _: SchedulePostResponse = try await post(endpoint: "/api/v1/posts/schedule", body: request, requiresAuth: true)
    }

    func deleteScheduledPost(postId: String) async throws {
        try await delete(endpoint: "/api/v1/posts/scheduled/\(postId)", requiresAuth: true)
    }

    // MARK: - Generic Network Methods
    private func get<T: Decodable>(endpoint: String, requiresAuth: Bool = false) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return try await performRequest(request)
    }

    private func post<T: Encodable, U: Decodable>(endpoint: String, body: T, requiresAuth: Bool = false) async throws -> U {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        return try await performRequest(request)
    }

    private func delete(endpoint: String, requiresAuth: Bool = false) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }

            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.serverError("HTTP \(httpResponse.statusCode)")
            }

            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// Empty response for endpoints that don't return data
struct EmptyResponse: Codable {}
