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
    private let _test_score: StringOrDouble?

    var test_score: Double? {
        _test_score?.doubleValue
    }

    var id: String { prompt_id }

    func hash(into hasher: inout Hasher) {
        hasher.combine(prompt_id)
    }

    static func == (lhs: Prompt, rhs: Prompt) -> Bool {
        lhs.prompt_id == rhs.prompt_id
    }

    enum CodingKeys: String, CodingKey {
        case prompt_id, name, description, model, supports_mood, mood_options, is_default
        case _test_score = "test_score"
    }
}

// Helper to decode values that could be String or Double
enum StringOrDouble: Codable {
    case string(String)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(StringOrDouble.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Double"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        }
    }

    var doubleValue: Double? {
        switch self {
        case .string(let str):
            return Double(str)
        case .double(let val):
            return val
        }
    }
}

struct PromptsResponse: Codable {
    let prompts: [Prompt]
}

struct GenerateHumanPostRequest: Codable {
    let topic: String
    let platform: String
    let include_emojis: Bool
}

struct GenerateHumanPostResponse: Codable {
    let success: Bool
    let post_id: String
    let content: String
    let platform: String
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
    let tokens_used: Int?
}

// MARK: - Import Templates Models
struct ImportTemplatesRequest: Codable {
    let templates: [CalendarTemplate]
    let start_date: String?
}

struct CalendarTemplate: Codable {
    let title: String
    let description: String?
    let task_type: String
    let platform: String
    let mood: String
    let template_content: String
}

struct ImportTemplatesResponse: Codable {
    let success: Bool
    let imported_count: Int
    let start_date: String
}

// MARK: - 30-Day Calendar Templates
struct CalendarTemplates {
    static let all: [CalendarTemplate] = [
        // WEEK 1
        CalendarTemplate(title: "Day 1: The DM Booking Problem", description: "Relatable pain point post", task_type: "post", platform: "instagram", mood: "frustrated", template_content: "The chaos of managing bookings through DMs. You know the drill - screenshots of availability, missed messages, double-bookings. There has to be a better way."),
        CalendarTemplate(title: "Day 2: Building in Public Intro", description: "Introduce the journey", task_type: "post", platform: "x", mood: "excited", template_content: "We're building Schedalize - scheduling software for beauty pros who are tired of the DM chaos. Following along as we build this thing from scratch."),
        CalendarTemplate(title: "Day 3: No-Show Frustration", description: "Common pain point", task_type: "post", platform: "tiktok", mood: "frustrated", template_content: "That moment when you've prepped for an appointment and they just... don't show up. No text, no call, nothing. The worst part of running a beauty business."),
        CalendarTemplate(title: "Day 4: Tip - Booking Confirmation", description: "Value post with tip", task_type: "post", platform: "instagram", mood: "focused", template_content: "Quick tip: Always send a booking confirmation with the date, time, and your cancellation policy. Cuts no-shows by almost half."),
        CalendarTemplate(title: "Day 5: Behind the Scenes", description: "Show development progress", task_type: "post", platform: "x", mood: "tired", template_content: "Late night coding session. Working on the booking confirmation flow - making sure it actually feels like a human sent it, not a robot."),
        CalendarTemplate(title: "Day 6: Weekend Engagement", description: "Community question", task_type: "post", platform: "instagram", mood: "grateful", template_content: "Curious - how do you currently handle your bookings? DMs? Paper calendar? An app? Genuinely want to know what works and what doesn't."),
        CalendarTemplate(title: "Day 7: Rest Day Reflection", description: "Lighter Sunday content", task_type: "post", platform: "x", mood: "grateful", template_content: "Sunday reset. This week we shipped the basic booking flow. Next week: reminders. Small steps."),
        // WEEK 2
        CalendarTemplate(title: "Day 8: Reminder Feature", description: "Feature announcement", task_type: "post", platform: "instagram", mood: "excited", template_content: "Automatic appointment reminders are now live. Your clients get a gentle nudge before their appointment - customizable timing, no extra work for you."),
        CalendarTemplate(title: "Day 9: Tip - Reminder Timing", description: "Value post", task_type: "post", platform: "tiktok", mood: "focused", template_content: "Best reminder timing for beauty appointments: 24 hours before AND 2 hours before. The double reminder catches the forgetful ones."),
        CalendarTemplate(title: "Day 10: Client Feedback", description: "Social proof", task_type: "post", platform: "x", mood: "grateful", template_content: "Got our first real feedback from a beta user today. 'Finally, something that doesn't look like it was made in 2010.' That's exactly what we're going for."),
        CalendarTemplate(title: "Day 11: Problem - Double Bookings", description: "Pain point post", task_type: "post", platform: "instagram", mood: "frustrated", template_content: "Double-bookings happen when you're managing multiple platforms. One client books on Instagram while another calls. Now you're apologizing to someone."),
        CalendarTemplate(title: "Day 12: Building Update", description: "Progress share", task_type: "post", platform: "x", mood: "focused", template_content: "Working on calendar sync this week. The goal: one source of truth, no matter where the booking comes from."),
        CalendarTemplate(title: "Day 13: Tip - Client Communication", description: "Value post", task_type: "post", platform: "instagram", mood: "focused", template_content: "Your booking confirmation should include: date, time, service, duration, your address, parking info, and cancellation policy. Leaves nothing to question."),
        CalendarTemplate(title: "Day 14: Week 2 Milestone", description: "Progress celebration", task_type: "post", platform: "x", mood: "grateful", template_content: "Two weeks of building. Reminders working, basic scheduling done. 47 people on the waitlist. Not huge numbers, but it's real."),
        // WEEK 3
        CalendarTemplate(title: "Day 15: Industry Question", description: "Engagement post", task_type: "post", platform: "instagram", mood: "focused", template_content: "Real question for beauty pros: what's the ONE thing you wish your scheduling tool did better? Not looking for a feature list, just the one thing that would change your day."),
        CalendarTemplate(title: "Day 16: Behind the Design", description: "Building in public", task_type: "post", platform: "x", mood: "excited", template_content: "Spent the morning on button colors. Sounds trivial but the details matter. If it doesn't feel premium, it's not premium."),
        CalendarTemplate(title: "Day 17: Tip - Deposits", description: "Value post", task_type: "post", platform: "tiktok", mood: "focused", template_content: "Hot take: requiring deposits for appointments isn't rude, it's professional. It respects your time and filters out the no-shows."),
        CalendarTemplate(title: "Day 18: Problem - Late Nights", description: "Relatable content", task_type: "post", platform: "instagram", mood: "tired", template_content: "Answering booking requests at 11pm because you're afraid of losing clients. The hustle is real, but there has to be a boundary somewhere."),
        CalendarTemplate(title: "Day 19: Feature Preview", description: "Tease upcoming feature", task_type: "post", platform: "x", mood: "excited", template_content: "Working on something new: a booking page you can actually be proud to share. Clean, professional, reflects your brand. Coming soon."),
        CalendarTemplate(title: "Day 20: Weekend Tip", description: "Quick value", task_type: "post", platform: "instagram", mood: "focused", template_content: "Weekend reminder: block off personal time in your calendar FIRST. Then open the remaining slots for bookings. Your time matters too."),
        CalendarTemplate(title: "Day 21: Week 3 Reflection", description: "Progress share", task_type: "post", platform: "x", mood: "grateful", template_content: "Week 3 done. Booking page is taking shape. 62 people on waitlist now. Every signup is motivation to keep going."),
        // WEEK 4
        CalendarTemplate(title: "Day 22: Booking Page Launch", description: "Feature launch", task_type: "post", platform: "instagram", mood: "excited", template_content: "Your booking page is live. One clean link. People pick a time, you get the confirmation, everyone moves on with their day. No back-and-forth needed."),
        CalendarTemplate(title: "Day 23: User Story", description: "Social proof", task_type: "post", platform: "x", mood: "grateful", template_content: "First beta user just told us they saved 3 hours this week not answering availability questions. 3 hours. That's the point."),
        CalendarTemplate(title: "Day 24: Tip - Booking Links", description: "Value post", task_type: "post", platform: "tiktok", mood: "focused", template_content: "Put your booking link in your bio, your stories, your posts. Make it stupid easy for people to book. The harder it is, the fewer bookings you get."),
        CalendarTemplate(title: "Day 25: Problem - Tech Overwhelm", description: "Relatable content", task_type: "post", platform: "instagram", mood: "tired", template_content: "You're a hairstylist, not a tech person. You shouldn't need to watch tutorials just to accept a booking. This is why we keep things simple."),
        CalendarTemplate(title: "Day 26: Milestone Celebration", description: "Growth share", task_type: "post", platform: "x", mood: "excited", template_content: "100 people on the waitlist. A month ago this was just an idea. Thanks to everyone who's following along and giving feedback."),
        CalendarTemplate(title: "Day 27: Community Spotlight", description: "Engagement", task_type: "post", platform: "instagram", mood: "grateful", template_content: "Shoutout to everyone who's been DMing suggestions and feedback. You're literally shaping what this becomes. Keep them coming."),
        CalendarTemplate(title: "Day 28: Looking Ahead", description: "Vision post", task_type: "post", platform: "x", mood: "focused", template_content: "Next on the list: payment integration. Because collecting deposits shouldn't require a separate app and a spreadsheet."),
        // DAYS 29-30
        CalendarTemplate(title: "Day 29: Month Review", description: "Reflection post", task_type: "post", platform: "instagram", mood: "grateful", template_content: "One month of building Schedalize. Reminders, booking pages, calendar sync. 100+ waitlist signups. Still a long way to go, but the foundation is solid."),
        CalendarTemplate(title: "Day 30: What's Next", description: "Forward-looking", task_type: "post", platform: "x", mood: "excited", template_content: "Month one: done. Month two: payments, more integrations, and hopefully our first paying customers. Let's see where this goes.")
    ]
}

// MARK: - Unified History Model
enum HistoryItemType: String, CaseIterable {
    case reply = "reply"
    case task = "task"
    case scheduled = "scheduled"

    var label: String {
        switch self {
        case .reply: return "Replies"
        case .task: return "Tasks"
        case .scheduled: return "Scheduled"
        }
    }

    var icon: String {
        switch self {
        case .reply: return "bubble.left.and.bubble.right"
        case .task: return "checklist"
        case .scheduled: return "calendar"
        }
    }

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .reply: return (0.29, 0.42, 0.98)     // Blue
        case .task: return (0.6, 0.2, 0.8)         // Purple
        case .scheduled: return (0.0, 0.7, 0.4)   // Green
        }
    }
}

struct UnifiedHistoryItem: Identifiable {
    let id: String
    let type: HistoryItemType
    let content: String
    let platform: String
    let createdAt: Date
    let postedAt: Date?
    let postedPlatform: String?

    // For replies
    let originalMessage: String?
    let generatedReplies: [GeneratedReply]?

    // For tasks
    let taskTitle: String?
    let dayNumber: Int?
    let mood: String?

    // For scheduled
    let scheduledFor: Date?
    let status: String?

    static func from(reply: HistoryItem) -> UnifiedHistoryItem {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: reply.created_at) ?? ISO8601DateFormatter().date(from: reply.created_at) ?? Date()

        return UnifiedHistoryItem(
            id: reply.reply_id,
            type: .reply,
            content: reply.generated_replies.first?.text ?? "",
            platform: reply.platform,
            createdAt: date,
            postedAt: nil,
            postedPlatform: nil,
            originalMessage: reply.original_message,
            generatedReplies: reply.generated_replies,
            taskTitle: nil,
            dayNumber: nil,
            mood: nil,
            scheduledFor: nil,
            status: nil
        )
    }

    static func from(task: CalendarTask) -> UnifiedHistoryItem {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = task.created_at ?? task.scheduled_date
        let date = formatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr) ?? Date()

        return UnifiedHistoryItem(
            id: task.task_id,
            type: .task,
            content: task.generated_content ?? task.template_content ?? "",
            platform: task.platform ?? "instagram",
            createdAt: date,
            postedAt: nil,
            postedPlatform: nil,
            originalMessage: nil,
            generatedReplies: nil,
            taskTitle: task.title,
            dayNumber: task.day_number,
            mood: task.mood,
            scheduledFor: nil,
            status: nil
        )
    }

    static func from(scheduled: ScheduledPost) -> UnifiedHistoryItem {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: scheduled.created_at) ?? ISO8601DateFormatter().date(from: scheduled.created_at) ?? Date()
        let scheduledDate = formatter.date(from: scheduled.scheduled_for) ?? ISO8601DateFormatter().date(from: scheduled.scheduled_for)

        return UnifiedHistoryItem(
            id: scheduled.post_id,
            type: .scheduled,
            content: scheduled.content,
            platform: scheduled.platform,
            createdAt: date,
            postedAt: nil,
            postedPlatform: nil,
            originalMessage: nil,
            generatedReplies: nil,
            taskTitle: nil,
            dayNumber: nil,
            mood: scheduled.tone,
            scheduledFor: scheduledDate,
            status: scheduled.status
        )
    }
}

// MARK: - Docs
struct Doc: Codable, Identifiable {
    let doc_id: String
    let user_id: String?
    let title: String
    let category: String?
    let content: String
    let created_at: String
    let updated_at: String

    var id: String { doc_id }
}

struct DocsResponse: Codable {
    let docs: [Doc]
    let count: Int
}

struct DocResponse: Codable {
    let doc: Doc
}

// MARK: - Error Response
struct ErrorResponse: Codable {
    let error: String
}
