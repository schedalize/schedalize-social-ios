//
//  CalendarView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct CalendarView: View {
    @State private var tasks: [CalendarTask] = []
    @State private var todayTasks: [CalendarTask] = []
    @State private var isLoading = false
    @State private var isPushing = false
    @State private var errorMessage: String?
    @State private var showPushConfirmation = false
    @State private var pushResult: PushTasksResponse?
    @State private var selectedTask: CalendarTask?
    @State private var generatedContent: String?
    @State private var isGenerating = false

    var body: some View {
        NavigationView {
            List {
                // Today's Tasks Section
                if !todayTasks.isEmpty {
                    Section {
                        ForEach(todayTasks) { task in
                            TaskRow(task: task, onGenerate: { generateContent(for: task) }, onComplete: { completeTask(task) })
                        }
                    } header: {
                        HStack {
                            Text("Today's Tasks")
                            Spacer()
                            Text("\(todayTasks.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }

                // Upcoming Tasks Section
                if !tasks.filter({ !isToday($0.scheduled_date) }).isEmpty {
                    Section {
                        ForEach(tasks.filter { !isToday($0.scheduled_date) }) { task in
                            TaskRow(task: task, onGenerate: { generateContent(for: task) }, onComplete: { completeTask(task) })
                        }
                    } header: {
                        Text("Upcoming")
                    }
                }

                // Empty State
                if tasks.isEmpty && todayTasks.isEmpty && !isLoading {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No tasks scheduled")
                                .font(.headline)
                            Text("Import your 30-day calendar to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showPushConfirmation = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle")
                            Text("Push")
                        }
                    }
                    .disabled(isPushing || todayTasks.isEmpty)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: loadTasks) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .refreshable {
                await loadTasksAsync()
            }
            .alert("Push Tasks", isPresented: $showPushConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Push Forward", role: .destructive) {
                    pushTasks()
                }
            } message: {
                Text("This will push all incomplete tasks (including today's) forward by 1 day. This action cannot be undone.")
            }
            .alert("Tasks Pushed", isPresented: .init(
                get: { pushResult != nil },
                set: { if !$0 { pushResult = nil } }
            )) {
                Button("OK") { pushResult = nil }
            } message: {
                if let result = pushResult {
                    Text(result.message)
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task, generatedContent: generatedContent, isGenerating: isGenerating, onGenerate: {
                    generateContent(for: task)
                }, onComplete: {
                    completeTask(task)
                    selectedTask = nil
                })
            }
        }
        .onAppear {
            loadTasks()
        }
    }

    private func isToday(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private func loadTasks() {
        Task {
            await loadTasksAsync()
        }
    }

    private func loadTasksAsync() async {
        isLoading = true
        errorMessage = nil

        do {
            async let todayResponse = ApiClient.shared.getTodayTasks()
            async let allResponse = ApiClient.shared.getCalendarTasks()

            let (today, all) = try await (todayResponse, allResponse)
            todayTasks = today.tasks
            tasks = all.tasks
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func pushTasks() {
        isPushing = true
        Task {
            do {
                let result = try await ApiClient.shared.pushTasks()
                pushResult = result
                await loadTasksAsync()
            } catch {
                errorMessage = error.localizedDescription
            }
            isPushing = false
        }
    }

    private func generateContent(for task: CalendarTask) {
        isGenerating = true
        selectedTask = task
        generatedContent = nil

        Task {
            do {
                let result = try await ApiClient.shared.generateTaskContent(taskId: task.task_id)
                generatedContent = result.content
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    private func completeTask(_ task: CalendarTask) {
        Task {
            do {
                _ = try await ApiClient.shared.completeTask(taskId: task.task_id, generatedContent: generatedContent)
                await loadTasksAsync()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct TaskRow: View {
    let task: CalendarTask
    let onGenerate: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)

                    HStack(spacing: 8) {
                        if let platform = task.platform {
                            Label(platform.capitalized, systemImage: platformIcon(platform))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let dayNum = task.day_number {
                            Text("Day \(dayNum)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }

                        if let mood = task.mood {
                            Text(moodEmoji(mood))
                                .font(.caption)
                        }
                    }
                }

                Spacer()

                Text(formatDate(task.scheduled_date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let template = task.template_content, !template.isEmpty {
                Text(template)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                Button(action: onGenerate) {
                    Label("Generate", systemImage: "wand.and.stars")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(action: onComplete) {
                    Label("Complete", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private func platformIcon(_ platform: String) -> String {
        switch platform.lowercased() {
        case "instagram": return "camera"
        case "twitter": return "at"
        case "tiktok": return "play.rectangle"
        case "linkedin": return "briefcase"
        default: return "globe"
        }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood.lowercased() {
        case "excited": return "energetic"
        case "tired": return "subdued"
        case "focused": return "direct"
        case "grateful": return "thankful"
        case "frustrated": return "determined"
        default: return mood
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }

        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return displayFormatter.string(from: date)
        }
    }
}

struct TaskDetailSheet: View {
    let task: CalendarTask
    let generatedContent: String?
    let isGenerating: Bool
    let onGenerate: () -> Void
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Task Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let platform = task.platform {
                            Label(platform.capitalized, systemImage: "globe")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Template
                    if let template = task.template_content, !template.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Template")
                                .font(.headline)
                            Text(template)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Generated Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Generated Content")
                                .font(.headline)
                            Spacer()
                            Button(action: onGenerate) {
                                if isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Label("Generate", systemImage: "wand.and.stars")
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(isGenerating)
                        }

                        if let content = generatedContent ?? task.generated_content {
                            Text(content)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)

                            Button(action: {
                                UIPasteboard.general.string = content
                            }) {
                                Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        } else if !isGenerating {
                            Text("No content generated yet")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        onComplete()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}
