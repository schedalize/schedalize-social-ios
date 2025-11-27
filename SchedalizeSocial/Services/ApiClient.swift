//
//  ApiClient.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unauthorized:
            return "Unauthorized - please log in again"
        }
    }
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

    // MARK: - Post Generation
    func generateHumanPost(topic: String, platform: String, includeEmojis: Bool = true) async throws -> GenerateHumanPostResponse {
        let request = GenerateHumanPostRequest(topic: topic, platform: platform, include_emojis: includeEmojis)
        return try await post(endpoint: "/api/v1/posts/generate-human", body: request, requiresAuth: true)
    }

    // MARK: - Calendar Tasks
    func getTodayTasks() async throws -> TodayTasksResponse {
        return try await get(endpoint: "/api/v1/calendar/tasks/today", requiresAuth: true)
    }

    func getCalendarTasks(startDate: String? = nil, endDate: String? = nil, includeCompleted: Bool = false) async throws -> CalendarTasksResponse {
        var endpoint = "/api/v1/calendar/tasks?"
        if let start = startDate { endpoint += "start_date=\(start)&" }
        if let end = endDate { endpoint += "end_date=\(end)&" }
        endpoint += "include_completed=\(includeCompleted)"
        return try await get(endpoint: endpoint, requiresAuth: true)
    }

    func pushTasks(fromDate: String? = nil) async throws -> PushTasksResponse {
        struct PushRequest: Codable {
            let from_date: String?
        }
        let request = PushRequest(from_date: fromDate)
        return try await post(endpoint: "/api/v1/calendar/push", body: request, requiresAuth: true)
    }

    func completeTask(taskId: String, generatedContent: String? = nil) async throws -> CalendarTask {
        struct CompleteRequest: Codable {
            let generated_content: String?
        }
        struct CompleteResponse: Codable {
            let success: Bool
            let task: CalendarTask
        }
        let request = CompleteRequest(generated_content: generatedContent)
        let response: CompleteResponse = try await post(endpoint: "/api/v1/calendar/tasks/\(taskId)/complete", body: request, requiresAuth: true)
        return response.task
    }

    func generateTaskContent(taskId: String, includeEmojis: Bool? = nil) async throws -> GenerateTaskContentResponse {
        struct GenerateRequest: Codable {
            let include_emojis: Bool?
        }
        let request = GenerateRequest(include_emojis: includeEmojis)
        return try await post(endpoint: "/api/v1/calendar/tasks/\(taskId)/generate", body: request, requiresAuth: true)
    }

    func importCalendarTemplates(startDate: String? = nil) async throws -> ImportTemplatesResponse {
        let request = ImportTemplatesRequest(templates: CalendarTemplates.all, start_date: startDate)
        return try await post(endpoint: "/api/v1/calendar/import-templates", body: request, requiresAuth: true)
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

    // MARK: - Docs
    func getDocs(category: String? = nil) async throws -> DocsResponse {
        var endpoint = "/api/v1/docs"
        if let category = category {
            endpoint += "?category=\(category)"
        }
        return try await get(endpoint: endpoint, requiresAuth: true)
    }

    func getDoc(docId: String) async throws -> DocResponse {
        return try await get(endpoint: "/api/v1/docs/\(docId)", requiresAuth: true)
    }
}

// Empty response for endpoints that don't return data
struct EmptyResponse: Codable {}
