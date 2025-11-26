//
//  PostsView.swift
//  SchedulizeSocial
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
                                let postsForDate = postsForDate(selected)
                                if !postsForDate.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Posts on \(formatDateHeader(selected))")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                            .padding(.horizontal, 20)

                                        ForEach(postsForDate) { post in
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
                            }

                            if scheduledPosts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.5))

                                    Text("No scheduled posts")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))

                                    Text("Schedule posts to publish later")
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
            .navigationTitle("Calendar")
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
            .task {
                await loadPosts()
            }
            .sheet(isPresented: $showAddPost) {
                AddPostView(onSave: {
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

    private func postsForDate(_ date: Date) -> [ScheduledPost] {
        scheduledPosts.filter { post in
            guard let postDate = ISO8601DateFormatter().date(from: post.scheduled_for) else {
                return false
            }
            return Calendar.current.isDate(postDate, inSameDayAs: date)
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
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .serverError(let message):
                    errorMessage = message
                default:
                    errorMessage = "Failed to load posts. Please try again."
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
                    Image(systemName: platformIcon(post.platform))
                        .font(.system(size: 12))
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

    private func platformIcon(_ platform: String) -> String {
        switch platform {
        case "Instagram": return "camera.fill"
        case "TikTok": return "video.fill"
        case "Email": return "envelope.fill"
        default: return "bubble.left.fill"
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
    @State private var content = ""
    @State private var platform = "Instagram"
    @State private var scheduledDate = Date()
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    let platforms = ["Instagram", "TikTok", "Email"]
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(height: 150)
                }

                Section("Platform") {
                    Picker("Platform", selection: $platform) {
                        ForEach(platforms, id: \.self) { platform in
                            Text(platform).tag(platform)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Schedule") {
                    DatePicker("Date & Time", selection: $scheduledDate, in: Date()...)
                }

                Section {
                    Button(action: savePost) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Schedule Post")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .listRowBackground(Color(red: 0.29, green: 0.42, blue: 0.98))
                    .disabled(content.isEmpty || isLoading)
                }
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
                    content: content,
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
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!),
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
            guard let postDate = ISO8601DateFormatter().date(from: post.scheduled_for) else {
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
