//
//  Models.swift
//  SchedalizeSocial
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
    let scheduled_for: String
    let status: String
    let topic: String?
    let hashtags: [String]?
    let tone: String?
    let created_at: String

    var id: String { post_id }
}

struct ScheduledPostsResponse: Codable {
    let posts: [ScheduledPost]
    let count: Int
}

struct CreatePostRequest: Codable {
    let content: String
    let platform: String
    let scheduled_for: String
    let topic: String?
    let hashtags: [String]?
    let tone: String?
}

struct SchedulePostResponse: Codable {
    let success: Bool
    let post_id: String
    let scheduled_for: String
}

// MARK: - Quality Evaluation Models
struct QualityEvaluateRequest: Codable {
    let content: String
    let platform: String
    let post_type: String?
    let context: String?
}

struct QualityScore: Codable {
    let score: Double
    let feedback: String
}

struct QualityScores: Codable {
    let human_likeness: QualityScore
    let attitude: QualityScore
    let engagement: QualityScore
    let platform_fit: QualityScore
    let brand_alignment: QualityScore
}

struct QualityEvaluationResponse: Codable {
    let evaluation_id: String?
    let scores: QualityScores
    let overall_score: Double
    let pass: Bool
    let summary: String
    let improvements: [String]?
    let strengths: [String]?
    let evaluated_at: String?
    let platform: String?
    let post_type: String?
    let content_length: Int?
    let tokens_used: Int?
}

struct QuickCheckRequest: Codable {
    let content: String
    let platform: String
}

struct QuickCheckResponse: Codable {
    let pass: Bool
    let score: Double
    let issues: [String]
    let ready_to_post: Bool
    let platform: String?
    let content_length: Int?
}

struct QualityHistoryResponse: Codable {
    let evaluations: [QualityEvaluationHistoryItem]
    let stats: QualityStats
}

struct QualityEvaluationHistoryItem: Codable, Identifiable {
    let evaluation_id: String
    let content: String
    let platform: String
    let post_type: String?
    let scores: QualityScores
    let overall_score: Double
    let passed: Bool
    let improvements: [String]?
    let created_at: String

    var id: String { evaluation_id }
}

struct QualityStats: Codable {
    let total: Int
    let average_score: Double
    let passed: Int
    let failed: Int
    let pass_rate: Int
}

// MARK: - Prompts Models
struct Prompt: Codable, Identifiable, Hashable {
    let prompt_id: String
    let name: String
    let description: String?
    let model: String
    let supports_mood: Bool
    let mood_options: [String]?
    let is_default: Bool
    let test_score: Double?

    var id: String { prompt_id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(prompt_id)
    }

    static func == (lhs: Prompt, rhs: Prompt) -> Bool {
        lhs.prompt_id == rhs.prompt_id
    }
}

struct PromptsResponse: Codable {
    let prompts: [Prompt]
}

struct GenerateHumanPostRequest: Codable {
    let topic: String
    let platform: String
    let mood: String
    let include_emojis: Bool
    let prompt_id: String?
}

struct GenerateHumanPostResponse: Codable {
    let success: Bool
    let post_id: String
    let content: String
    let platform: String
    let mood: String
    let prompt_name: String?
    let model: String?
    let tokens_used: Int?
}

// MARK: - Calendar Models
struct CalendarTask: Codable, Identifiable {
    let task_id: String
    let title: String
    let description: String?
    let task_type: String
    let platform: String?
    let template_content: String?
    let prompt_id: String?
    let mood: String?
    let scheduled_date: String
    let original_date: String
    let day_number: Int?
    let is_completed: Bool
    let completed_at: String?
    let generated_content: String?
    let created_at: String?

    var id: String { task_id }
}

struct CalendarTasksResponse: Codable {
    let tasks: [CalendarTask]
    let count: Int
}

struct TodayTasksResponse: Codable {
    let tasks: [CalendarTask]
    let count: Int
    let date: String
}

struct PushTasksResponse: Codable {
    let success: Bool
    let pushed_count: Int
    let tasks: [PushedTask]
    let message: String
}

struct PushedTask: Codable {
    let task_id: String
    let title: String
    let scheduled_date: String
    let original_date: String
}

struct GenerateTaskContentResponse: Codable {
    let success: Bool
    let task_id: String
    let content: String
    let mood: String
    let prompt_name: String?
    let tokens_used: Int?
}

// MARK: - Error Response
struct ErrorResponse: Codable {
    let error: String
}
