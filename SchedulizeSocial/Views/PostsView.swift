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

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if scheduledPosts.isEmpty {
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

                        Button(action: { showAddPost = true }) {
                            Text("Add Post")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.29, green: 0.42, blue: 0.98))
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(scheduledPosts) { post in
                                PostCard(post: post, onDelete: { deletePost(post.post_id) })
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Scheduled Posts")
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
                Text("Scheduled: \(formatDate(post.scheduled_time))")
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
        let scheduledTime = formatter.string(from: scheduledDate)

        Task {
            do {
                try await ApiClient.shared.createScheduledPost(
                    content: content,
                    platform: platform,
                    scheduledTime: scheduledTime
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

#Preview {
    PostsView()
}
