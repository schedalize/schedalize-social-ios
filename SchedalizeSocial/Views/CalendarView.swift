//
//  CalendarView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct CalendarView: View {
    @State private var incompleteTasks: [CalendarTask] = []
    @State private var completedTasks: [CalendarTask] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTask: CalendarTask?
    @State private var isImporting = false
    @State private var showImportSuccess = false
    @State private var importedCount = 0
    @State private var showCompleted = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with action buttons
                if !completedTasks.isEmpty {
                    HStack {
                        Spacer()

                        Button(action: { showCompleted.toggle() }) {
                            HStack(spacing: 4) {
                                Image(systemName: showCompleted ? "eye.slash" : "eye")
                                Text(showCompleted ? "Hide" : "Show")
                                Text("(\(completedTasks.count))")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }

                List {
                // Incomplete Tasks Section
                if !incompleteTasks.isEmpty {
                    Section {
                        ForEach(incompleteTasks) { task in
                            TaskRow(task: task, onTap: { selectedTask = task }, showDate: false)
                        }
                    } header: {
                        HStack {
                            Text("Tasks to Complete")
                            Spacer()
                            Text("\(incompleteTasks.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }

                // Completed Tasks Section
                if showCompleted && !completedTasks.isEmpty {
                    Section {
                        ForEach(completedTasks) { task in
                            CompletedTaskRow(task: task)
                        }
                    } header: {
                        HStack {
                            Text("Completed")
                            Spacer()
                            Text("\(completedTasks.count)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }

                // Empty State
                if incompleteTasks.isEmpty && completedTasks.isEmpty && !isLoading {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No tasks yet")
                                .font(.headline)
                            Text("Import the 30-day calendar to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)

                            Button(action: importCalendar) {
                                HStack(spacing: 8) {
                                    if isImporting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                        Text("Importing...")
                                    } else {
                                        Image(systemName: "calendar.badge.plus")
                                        Text("Import Calendar")
                                    }
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.29, green: 0.42, blue: 0.98))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isImporting)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            }
            .navigationBarHidden(true)
            .refreshable {
                await loadTasksAsync()
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(
                    task: task,
                    onComplete: { generatedContent in
                        completeTask(task, generatedContent: generatedContent)
                    }
                )
            }
            .alert("Calendar Imported", isPresented: $showImportSuccess) {
                Button("OK") { }
            } message: {
                Text("Successfully imported \(importedCount) tasks.")
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            loadTasks()
        }
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
            // Load all tasks, sorted by day_number
            let allTasksResponse = try await ApiClient.shared.getCalendarTasks(
                startDate: nil,
                endDate: nil,
                includeCompleted: true
            )

            // Separate into incomplete and completed
            let allTasks = allTasksResponse.tasks.sorted { ($0.day_number ?? 0) < ($1.day_number ?? 0) }
            incompleteTasks = allTasks.filter { !$0.is_completed }
            completedTasks = allTasks.filter { $0.is_completed }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func importCalendar() {
        isImporting = true
        Task {
            do {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let startDate = formatter.string(from: Date())

                let result = try await ApiClient.shared.importCalendarTemplates(startDate: startDate)
                importedCount = result.imported_count
                showImportSuccess = true
                await loadTasksAsync()
            } catch {
                errorMessage = error.localizedDescription
            }
            isImporting = false
        }
    }

    private func completeTask(_ task: CalendarTask, generatedContent: String?) {
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
    let onTap: () -> Void
    let showDate: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Platform icon
                if let platform = task.platform {
                    Image(systemName: platformIcon(platform))
                        .font(.title3)
                        .foregroundColor(platformColor(platform))
                        .frame(width: 32)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    // Tags row
                    HStack(spacing: 6) {
                        if let dayNum = task.day_number {
                            Text("Day \(dayNum)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }

                        if let platform = task.platform {
                            Text(platform.capitalized)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func platformIcon(_ platform: String) -> String {
        switch platform.lowercased() {
        case "instagram": return "camera.fill"
        case "twitter": return "at"
        case "tiktok": return "play.rectangle.fill"
        case "linkedin": return "briefcase.fill"
        default: return "globe"
        }
    }

    private func platformColor(_ platform: String) -> Color {
        switch platform.lowercased() {
        case "instagram": return .pink
        case "twitter": return .blue
        case "tiktok": return .primary
        case "linkedin": return .blue
        default: return .secondary
        }
    }
}

struct CompletedTaskRow: View {
    let task: CalendarTask

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .strikethrough()
                    .lineLimit(2)

                // Tags and completion date
                HStack(spacing: 6) {
                    if let dayNum = task.day_number {
                        Text("Day \(dayNum)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }

                    if let completedAt = task.completed_at {
                        Text("Completed \(formatCompletionDate(completedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatCompletionDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        var date = isoFormatter.date(from: dateString)

        if date == nil {
            let isoFormatter2 = ISO8601DateFormatter()
            isoFormatter2.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = isoFormatter2.date(from: dateString)
        }

        guard let parsedDate = date else { return "recently" }

        if Calendar.current.isDateInToday(parsedDate) {
            return "today"
        } else if Calendar.current.isDateInYesterday(parsedDate) {
            return "yesterday"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            return displayFormatter.string(from: parsedDate)
        }
    }
}

struct TaskDetailSheet: View {
    let task: CalendarTask
    let onComplete: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var useEmojis: Bool = true
    @State private var generatedContent: String?
    @State private var isGenerating = false
    @State private var showCopied = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            if let platform = task.platform {
                                Label(platform.capitalized, systemImage: platformIcon(platform))
                                    .font(.subheadline)
                                    .foregroundColor(platformColor(platform))
                            }
                            if let dayNum = task.day_number {
                                Text("Day \(dayNum)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }

                    Divider()

                    // Template
                    if let template = task.template_content, !template.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Topic")
                                .font(.headline)
                            Text(template)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }

                    // Emoji Toggle
                    HStack {
                        Text("Include Emojis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                        Spacer()
                        Toggle("", isOn: $useEmojis)
                            .labelsHidden()
                            .tint(Color(red: 0.6, green: 0.2, blue: 0.8))
                    }

                    // Generate Button
                    Button(action: generateContent) {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                                Text("Generating...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generate")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.6, green: 0.2, blue: 0.8), Color(red: 0.8, green: 0.3, blue: 0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isGenerating)

                    // Generated Content
                    if let content = generatedContent ?? task.generated_content {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Generated Content")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = content
                                    showCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopied = false
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        Text(showCopied ? "Copied!" : "Copy")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(showCopied ? .green : Color(red: 0.29, green: 0.42, blue: 0.98))
                                }
                            }

                            Text(content)
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.29, green: 0.42, blue: 0.98).opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        onComplete(generatedContent)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(generatedContent == nil && task.generated_content == nil)
                }
            }
        }
    }

    private func generateContent() {
        isGenerating = true
        Task {
            do {
                let result = try await ApiClient.shared.generateTaskContent(
                    taskId: task.task_id,
                    includeEmojis: useEmojis
                )
                generatedContent = result.content
            } catch {
                // Handle error silently for now
            }
            isGenerating = false
        }
    }

    private func platformIcon(_ platform: String) -> String {
        switch platform.lowercased() {
        case "instagram": return "camera.fill"
        case "twitter": return "at"
        case "tiktok": return "play.rectangle.fill"
        case "linkedin": return "briefcase.fill"
        default: return "globe"
        }
    }

    private func platformColor(_ platform: String) -> Color {
        switch platform.lowercased() {
        case "instagram": return .pink
        case "twitter": return .blue
        case "tiktok": return .primary
        case "linkedin": return .blue
        default: return .secondary
        }
    }
}

#Preview {
    CalendarView()
}
