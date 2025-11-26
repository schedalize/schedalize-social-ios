//
//  Models.swift
//  SchedulizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import Foundation

// MARK: - Authentication Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let user: User
}

struct User: Codable {
    let user_id: String
    let email: String
    let name: String?
}

// MARK: - Reply Generation Models
struct GenerateReplyRequest: Codable {
    let message: String
    let platform: String
    let sender_info: String?
    let include_emojis: Bool?
}

struct GeneratedReply: Codable, Identifiable {
    var id: String { text }
    let text: String
    let tone: String
}

struct GenerateReplyResponse: Codable {
    let replies: [GeneratedReply]
}

// MARK: - History Models
struct HistoryItem: Codable, Identifiable {
    let reply_id: String
    let original_message: String
    let generated_replies: [GeneratedReply]
    let platform: String
    let detected_intent: String?
    let is_favorite: Bool?
    let favorite_tones: [String]?
    let selected_reply: String?
    let created_at: String

    var id: String { reply_id }
}

struct HistoryResponse: Codable {
    let replies: [HistoryItem]
    let count: Int
}

// MARK: - Scheduled Posts Models
struct ScheduledPost: Codable, Identifiable {
    let post_id: String
    let content: String
    let platform: String
    let scheduled_time: String
    let status: String
    let created_at: String

    var id: String { post_id }
}

struct ScheduledPostsResponse: Codable {
    let posts: [ScheduledPost]
}

struct CreatePostRequest: Codable {
    let content: String
    let platform: String
    let scheduled_time: String
}

// MARK: - Error Response
struct ErrorResponse: Codable {
    let error: String
}
