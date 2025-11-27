//
//  PostsView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct PostsView: View {
    @State private var scheduledPosts: [ScheduledPost] = []
    @State private var isLoading = false
    @State private var showAddPost = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var currentMonth = Date()
    @State private var selectedDate: Date?

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private var postsForSelectedDate: [ScheduledPost] {
        guard let selected = selectedDate else { return [] }
        return scheduledPosts.filter { post in
            guard let postDate = Self.isoFormatter.date(from: post.scheduled_for)
                    ?? ISO8601DateFormatter().date(from: post.scheduled_for) else {
                return false
            }
            return Calendar.current.isDate(postDate, inSameDayAs: selected)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Header
                CalendarHeaderView(currentMonth: $currentMonth)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Calendar Grid
                            CalendarGridView(
                                currentMonth: currentMonth,
                                scheduledPosts: scheduledPosts,
                                selectedDate: $selectedDate
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            // Posts for selected date or all upcoming
                            if let selected = selectedDate {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Posts on \(formatDateHeader(selected))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                        .padding(.horizontal, 20)

                                    if postsForSelectedDate.isEmpty {
                                        // Empty state for selected date
                                        VStack(spacing: 12) {
                                            Image(systemName: "calendar.badge.plus")
                                                .font(.system(size: 40))
                                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.5))
                                            Text("No posts scheduled")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                                            Button(action: { showAddPost = true }) {
                                                Label("Schedule a post", systemImage: "plus")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(Color(red: 0.29, green: 0.42, blue: 0.98))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 30)
                                        .padding(.horizontal, 20)
                                    } else {
                                        ForEach(postsForSelectedDate) { post in
                                            PostCard(post: post, onDelete: { deletePost(post.post_id) })
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            } else if !scheduledPosts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Upcoming Posts")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                        .padding(.horizontal, 20)

                                    ForEach(scheduledPosts.prefix(5)) { post in
                                        PostCard(post: post, onDelete: { deletePost(post.post_id) })
                                            .padding(.horizontal, 20)
                                    }
                                }
                            } else {
                                // No posts at all
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.5))

                                    Text("No scheduled posts")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))

                                    Text("Tap a date and + to schedule a post")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(40)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .navigationTitle("Schedule (\(scheduledPosts.count))")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddPost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                    }
                }
            }
            .refreshable {
                await loadPosts()
            }
            .onAppear {
                if scheduledPosts.isEmpty {
                    Task {
                        await loadPosts()
                    }
                }
            }
            .sheet(isPresented: $showAddPost) {
                AddPostView(initialDate: selectedDate ?? Date(), onSave: {
                    Task { await loadPosts() }
                })
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func loadPosts() async {
        isLoading = true
        errorMessage = ""

        do {
            let response = try await ApiClient.shared.getScheduledPosts()
            await MainActor.run {
                scheduledPosts = response.posts
                isLoading = false
                print("[Schedule] Loaded \(response.posts.count) posts")
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .serverError(let message):
                    errorMessage = message
                case .decodingError(let decodingError):
                    errorMessage = "Decoding error: \(decodingError.localizedDescription)"
                    print("[Schedule] Decoding error: \(decodingError)")
                case .unauthorized:
                    errorMessage = "Please log in again"
                default:
                    errorMessage = "Failed to load posts: \(error.localizedDescription)"
                }
                print("[Schedule] Error: \(errorMessage)")
                showError = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
                print("[Schedule] Unexpected error: \(error)")
                showError = true
                isLoading = false
            }
        }
    }

    private func deletePost(_ postId: String) {
        Task {
            do {
                try await ApiClient.shared.deleteScheduledPost(postId: postId)
                await loadPosts()
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete post."
                    showError = true
                }
            }
        }
    }
}

struct PostCard: View {
    let post: ScheduledPost
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    platformIcon(post.platform)
                    Text(post.platform)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.29, green: 0.42, blue: 0.98).opacity(0.1))
                .cornerRadius(6)

                Text(post.status.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor(post.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor(post.status).opacity(0.1))
                    .cornerRadius(6)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }

            // Content
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                .lineLimit(3)

            // Scheduled Time
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                Text("Scheduled: \(formatDate(post.scheduled_for))")
                    .font(.system(size: 12))
            }
            .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        switch platform {
        case "Instagram":
            InstagramIconView(color: Color(red: 0.29, green: 0.42, blue: 0.98), size: 12)
        case "TikTok":
            TikTokIconView(color: Color(red: 0.29, green: 0.42, blue: 0.98), size: 12)
        case "Email":
            Image(systemName: "envelope.fill")
                .font(.system(size: 12))
        default:
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 12))
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return Color.orange
        case "published": return Color.green
        case "failed": return Color.red
        default: return Color.gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

struct AddPostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var topic = ""
    @State private var generatedContent = ""
    @State private var platform = "Instagram"
    @State private var scheduledDate: Date
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var prompts: [Prompt] = []
    @State private var selectedPrompt: Prompt?
    @State private var selectedMood = "focused"
    @State private var selectedLength = "normal"
    @State private var useEmojis = true
    @State private var showCopied = false

    let platforms = ["Instagram", "TikTok", "Email"]
    let moods = ["excited", "tired", "focused", "grateful", "frustrated"]
    let lengths = ["brief", "normal", "long"]
    let initialDate: Date
    let onSave: () -> Void

    init(initialDate: Date = Date(), onSave: @escaping () -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        // Set the initial scheduled date at 12:00 PM (noon)
        let calendar = Calendar.current
        var dateToUse = initialDate

        // If date is in the past, use today
        if calendar.startOfDay(for: initialDate) < calendar.startOfDay(for: Date()) {
            dateToUse = Date()
        }

        // Set time to 12:00 PM
        var components = calendar.dateComponents([.year, .month, .day], from: dateToUse)
        components.hour = 12
        components.minute = 0
        components.second = 0
        let noonDate = calendar.date(from: components) ?? dateToUse

        // If noon has already passed today, use tomorrow at noon
        let finalDate: Date
        if noonDate <= Date() {
            finalDate = calendar.date(byAdding: .day, value: 1, to: noonDate) ?? noonDate
        } else {
            finalDate = noonDate
        }

        _scheduledDate = State(initialValue: finalDate)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Topic Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topic")
                            .font(.headline)
                        TextEditor(text: $topic)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        Text("Describe what you want to post about")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Platform Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.headline)
                        Picker("Platform", selection: $platform) {
                            ForEach(platforms, id: \.self) { p in
                                Text(p).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Generation Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Generation Settings")
                            .font(.headline)

                        // Mood Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mood")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(moods, id: \.self) { mood in
                                        Button(action: { selectedMood = mood }) {
                                            Text(mood.capitalized)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedMood == mood ? Color.purple : Color(.systemGray5))
                                                .foregroundColor(selectedMood == mood ? .white : .primary)
                                                .cornerRadius(16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Prompt Style Picker
                        if !prompts.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Prompt Style")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(prompts) { prompt in
                                            Button(action: { selectedPrompt = prompt }) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(prompt.name)
                                                        .font(.caption)
                                                        .fontWeight(.medium)
                                                    if let score = prompt.test_score {
                                                        Text(String(format: "%.0f%%", score))
                                                            .font(.caption2)
                                                            .foregroundColor(selectedPrompt?.prompt_id == prompt.prompt_id ? .white.opacity(0.8) : .secondary)
                                                    }
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedPrompt?.prompt_id == prompt.prompt_id ? Color.blue : Color(.systemGray5))
                                                .foregroundColor(selectedPrompt?.prompt_id == prompt.prompt_id ? .white : .primary)
                                                .cornerRadius(12)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }

                        // Length Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Length")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack(spacing: 8) {
                                ForEach(lengths, id: \.self) { length in
                                    Button(action: { selectedLength = length }) {
                                        Text(length.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedLength == length ? Color.orange : Color(.systemGray5))
                                            .foregroundColor(selectedLength == length ? .white : .primary)
                                            .cornerRadius(16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Emoji Toggle
                        Toggle(isOn: $useEmojis) {
                            HStack {
                                Text("Include Emojis")
                                    .font(.subheadline)
                                Text("😊")
                            }
                        }
                        .tint(.purple)
                    }

                    // Generate Button
                    Button(action: generateContent) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                                Text("Generating...")
                            } else {
                                Image(systemName: "wand.and.stars")
                                Text("Generate Content")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(topic.isEmpty ? Color.purple.opacity(0.5) : Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(topic.isEmpty || isGenerating)

                    // Generated Content
                    if !generatedContent.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Generated Content")
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = generatedContent
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopied = false
                                    }
                                }) {
                                    Label(showCopied ? "Copied!" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }

                            Text(generatedContent)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }

                        Divider()

                        // Schedule Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Schedule")
                                .font(.headline)
                            DatePicker("Date & Time", selection: $scheduledDate, in: Date()...)
                                .padding(.vertical, 4)
                        }

                        // Schedule Button
                        Button(action: savePost) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                    Text("Scheduling...")
                                } else {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Schedule Post")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.29, green: 0.42, blue: 0.98))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding()
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadPrompts()
            }
        }
    }

    private func loadPrompts() async {
        do {
            let response = try await ApiClient.shared.getPrompts()
            await MainActor.run {
                prompts = response.prompts
                selectedPrompt = prompts.first(where: { $0.is_default }) ?? prompts.first
            }
        } catch {
            // Silently fail - prompts are optional
        }
    }

    private func generateContent() {
        isGenerating = true
        Task {
            do {
                let result = try await ApiClient.shared.generateHumanPost(
                    topic: topic,
                    platform: platform.lowercased(),
                    mood: selectedMood,
                    includeEmojis: useEmojis,
                    promptId: selectedPrompt?.prompt_id
                )
                await MainActor.run {
                    generatedContent = result.content
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate content"
                    showError = true
                    isGenerating = false
                }
            }
        }
    }

    private func savePost() {
        isLoading = true
        errorMessage = ""

        let formatter = ISO8601DateFormatter()
        let scheduledFor = formatter.string(from: scheduledDate)

        Task {
            do {
                try await ApiClient.shared.createScheduledPost(
                    content: generatedContent,
                    platform: platform.lowercased(),
                    scheduledFor: scheduledFor
                )

                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch let error as APIError {
                await MainActor.run {
                    switch error {
                    case .serverError(let message):
                        errorMessage = message
                    default:
                        errorMessage = "Failed to schedule post. Please try again."
                    }
                    showError = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An unexpected error occurred."
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Calendar Components

struct CalendarHeaderView: View {
    @Binding var currentMonth: Date

    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                    .font(.system(size: 20, weight: .semibold))
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                    .font(.system(size: 20, weight: .semibold))
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

struct CalendarGridView: View {
    let currentMonth: Date
    let scheduledPosts: [ScheduledPost]
    @Binding var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            // Week day headers
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: isDateSelected(date),
                            isToday: Calendar.current.isDateInToday(date),
                            hasPost: hasPostOnDate(date),
                            onTap: { selectedDate = date }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }

    private func isDateSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(date, inSameDayAs: selected)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = Calendar.current.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        var date = monthFirstWeek.start

        while days.count < 42 { // 6 weeks
            if Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month) {
                days.append(date)
            } else {
                days.append(nil)
            }
            date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return days
    }

    private func hasPostOnDate(_ date: Date) -> Bool {
        scheduledPosts.contains { post in
            guard let postDate = Self.isoFormatter.date(from: post.scheduled_for)
                    ?? ISO8601DateFormatter().date(from: post.scheduled_for) else {
                return false
            }
            return Calendar.current.isDate(postDate, inSameDayAs: date)
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasPost: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(foregroundColor)

                if hasPost {
                    Circle()
                        .fill(Color(red: 0.29, green: 0.42, blue: 0.98))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color(red: 0.29, green: 0.42, blue: 0.98) : Color.clear, lineWidth: 2)
            )
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(red: 0.29, green: 0.42, blue: 0.98)
        } else {
            return Color(red: 0.96, green: 0.97, blue: 0.98)
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return Color(red: 0.29, green: 0.42, blue: 0.98)
        } else {
            return Color(red: 0.13, green: 0.16, blue: 0.24)
        }
    }
}

#Preview {
    PostsView()
}
