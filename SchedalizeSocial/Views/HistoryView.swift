//
//  HistoryView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

// Singleton to persist history data across tab switches
class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published var allItems: [UnifiedHistoryItem] = []
    @Published var isLoading = false
    @Published var hasLoaded = false
    @Published var selectedFilters: Set<HistoryItemType> = Set(HistoryItemType.allCases)

    private init() {}

    var filteredItems: [UnifiedHistoryItem] {
        allItems
            .filter { selectedFilters.contains($0.type) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var repliesCount: Int { allItems.filter { $0.type == .reply }.count }
    var tasksCount: Int { allItems.filter { $0.type == .task }.count }
    var scheduledCount: Int { allItems.filter { $0.type == .scheduled }.count }

    func toggleFilter(_ type: HistoryItemType) {
        if selectedFilters.contains(type) {
            if selectedFilters.count > 1 {
                selectedFilters.remove(type)
            }
        } else {
            selectedFilters.insert(type)
        }
    }

    @MainActor
    func loadAllHistory() async {
        guard !isLoading else { return }
        isLoading = true

        async let repliesTask = loadReplies()
        async let tasksTask = loadTasks()
        async let scheduledTask = loadScheduled()

        let (replies, tasks, scheduled) = await (repliesTask, tasksTask, scheduledTask)

        var items: [UnifiedHistoryItem] = []
        items.append(contentsOf: replies)
        items.append(contentsOf: tasks)
        items.append(contentsOf: scheduled)

        allItems = items
        isLoading = false
        hasLoaded = true
        print("[History] Loaded \(items.count) total items")
    }

    private func loadReplies() async -> [UnifiedHistoryItem] {
        do {
            let response = try await ApiClient.shared.getHistory()
            return response.replies.map { UnifiedHistoryItem.from(reply: $0) }
        } catch {
            print("[History] Failed to load replies: \(error)")
            return []
        }
    }

    private func loadTasks() async -> [UnifiedHistoryItem] {
        do {
            let response = try await ApiClient.shared.getCalendarTasks(includeCompleted: true)
            let completedTasks = response.tasks.filter { $0.is_completed && $0.generated_content != nil }
            return completedTasks.map { UnifiedHistoryItem.from(task: $0) }
        } catch {
            print("[History] Failed to load tasks: \(error)")
            return []
        }
    }

    private func loadScheduled() async -> [UnifiedHistoryItem] {
        do {
            let response = try await ApiClient.shared.getScheduledPosts()
            return response.posts.map { UnifiedHistoryItem.from(scheduled: $0) }
        } catch {
            print("[History] Failed to load scheduled posts: \(error)")
            return []
        }
    }
}

struct HistoryView: View {
    @ObservedObject private var store = HistoryStore.shared
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterTag(
                                type: .reply,
                                count: store.repliesCount,
                                isSelected: store.selectedFilters.contains(.reply),
                                onTap: { store.toggleFilter(.reply) }
                            )
                            FilterTag(
                                type: .task,
                                count: store.tasksCount,
                                isSelected: store.selectedFilters.contains(.task),
                                onTap: { store.toggleFilter(.task) }
                            )
                            FilterTag(
                                type: .scheduled,
                                count: store.scheduledCount,
                                isSelected: store.selectedFilters.contains(.scheduled),
                                onTap: { store.toggleFilter(.scheduled) }
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white)

                    if store.isLoading && !store.hasLoaded {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if store.filteredItems.isEmpty && store.hasLoaded {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "clock")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.5))

                            Text("No history yet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))

                            Text("Your generated content will appear here")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        Spacer()
                    } else if !store.filteredItems.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(store.filteredItems) { item in
                                    UnifiedHistoryCard(item: item)
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await store.loadAllHistory()
            }
            .onAppear {
                if !store.hasLoaded {
                    Task {
                        await store.loadAllHistory()
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
}

struct FilterTag: View {
    let type: HistoryItemType
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 12))
                Text(type.label)
                    .font(.system(size: 13, weight: .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : Color(red: type.color.red, green: type.color.green, blue: type.color.blue))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color(red: type.color.red, green: type.color.green, blue: type.color.blue)
                    : Color(red: type.color.red, green: type.color.green, blue: type.color.blue).opacity(0.1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct UnifiedHistoryCard: View {
    let item: UnifiedHistoryItem
    @State private var showCopied = false
    @State private var selectedPostedPlatform: String? = nil

    private let platforms = ["instagram", "tiktok", "x", "email"]

    private var isPosted: Bool {
        selectedPostedPlatform != nil || item.postedAt != nil
    }

    private var displayPostedPlatform: String? {
        selectedPostedPlatform ?? item.postedPlatform
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type tag and platform
            HStack {
                // Type Tag
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon)
                        .font(.system(size: 10))
                    Text(item.type.label.dropLast()) // Remove 's' for singular
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(red: item.type.color.red, green: item.type.color.green, blue: item.type.color.blue))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: item.type.color.red, green: item.type.color.green, blue: item.type.color.blue).opacity(0.1))
                .cornerRadius(6)

                // Platform
                HStack(spacing: 4) {
                    platformIcon(item.platform)
                    Text(item.platform.capitalized)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.1))
                .cornerRadius(6)

                Spacer()

                // Date
                Text(formatDate(item.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
            }

            // Task title if available
            if let title = item.taskTitle {
                HStack(spacing: 6) {
                    if let day = item.dayNumber {
                        Text("Day \(day)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                }
            }

            // Original message for replies
            if let originalMessage = item.originalMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                    Text(originalMessage)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                        .lineLimit(2)
                }
                .padding(10)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(8)
            }

            // Content
            Text(item.content)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                .lineLimit(4)

            // Scheduled info
            if let scheduledFor = item.scheduledFor {
                HStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 11))
                    Text("Scheduled: \(formatDateTime(scheduledFor))")
                        .font(.system(size: 11))
                    if let status = item.status {
                        Text("• \(status.capitalized)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(status == "pending" ? .orange : .green)
                    }
                }
                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
            }

            // Posted badge
            if isPosted, let platform = displayPostedPlatform {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                    Text("Posted on \(platform.capitalized)")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }

            Divider()

            // Actions
            HStack {
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = item.content
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopied = false
                    }
                }) {
                    Label(showCopied ? "Copied!" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(showCopied ? .green : .gray)

                Spacer()

                // Mark as Posted menu
                Menu {
                    Section("Mark as Posted") {
                        ForEach(platforms, id: \.self) { platform in
                            Button(action: {
                                selectedPostedPlatform = platform
                            }) {
                                HStack {
                                    Text(platform.capitalized)
                                    Spacer()
                                    if selectedPostedPlatform == platform {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        selectedPostedPlatform = nil
                    }) {
                        Label("Not Posted", systemImage: "xmark.circle")
                    }
                } label: {
                    Label(
                        isPosted ? "Posted" : "Mark Posted",
                        systemImage: isPosted ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(isPosted ? .green : Color(red: 0.42, green: 0.47, blue: 0.55))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        switch platform.lowercased() {
        case "instagram":
            InstagramIconView(color: Color(red: 0.42, green: 0.47, blue: 0.55), size: 11)
        case "tiktok":
            TikTokIconView(color: Color(red: 0.42, green: 0.47, blue: 0.55), size: 11)
        case "email":
            Image(systemName: "envelope.fill")
                .font(.system(size: 11))
        case "x", "twitter":
            Image(systemName: "at")
                .font(.system(size: 11))
        default:
            Image(systemName: "globe")
                .font(.system(size: 11))
        }
    }

    private func platformIconName(_ platform: String) -> String {
        switch platform.lowercased() {
        case "instagram": return "camera"
        case "tiktok": return "play.rectangle"
        case "email": return "envelope"
        case "x", "twitter": return "at"
        default: return "globe"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
            return "Today \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "h:mm a"
            return "Yesterday \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
}
