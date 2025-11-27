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
    @State private var isImporting = false
    @State private var showImportSuccess = false
    @State private var importedCount = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with action buttons
                HStack {
                    Button(action: {
                        if tasks.isEmpty && todayTasks.isEmpty {
                            importCalendar()
                        } else {
                            loadTasks()
                        }
                    }) {
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: tasks.isEmpty && todayTasks.isEmpty ? "calendar.badge.plus" : "arrow.clockwise")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                        }
                    }
                    .disabled(isLoading || isImporting)

                    Spacer()

                    Button(action: { showPushConfirmation = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle")
                            Text("Push")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(todayTasks.isEmpty ? .gray : Color(red: 0.29, green: 0.42, blue: 0.98))
                    }
                    .disabled(isPushing || todayTasks.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)

                List {
                // Today's Tasks Section
                if !todayTasks.isEmpty {
                    Section {
                        ForEach(todayTasks) { task in
                            TaskRow(task: task, onTap: { selectedTask = task })
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
                            TaskRow(task: task, onTap: { selectedTask = task })
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
                            Text("Tap the + button to import 30-day calendar")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                Text("Successfully imported \(importedCount) tasks for the next 30 days.")
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

    private func isToday(_ dateString: String) -> Bool {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?
        date = isoFormatter.date(from: dateString)

        if date == nil {
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            date = simpleFormatter.date(from: dateString)
        }

        if date == nil {
            let isoFormatter2 = ISO8601DateFormatter()
            date = isoFormatter2.date(from: dateString)
        }

        guard let parsedDate = date else { return false }
        return Calendar.current.isDateInToday(parsedDate)
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
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let now = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
            let startDateStr = formatter.string(from: now)
            let endDateStr = formatter.string(from: endDate)

            async let todayResponse = ApiClient.shared.getTodayTasks()
            async let allResponse = ApiClient.shared.getCalendarTasks(startDate: startDateStr, endDate: endDateStr)

            let (todayResult, allResult) = try await (todayResponse, allResponse)
            todayTasks = todayResult.tasks
            tasks = allResult.tasks
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
                    // Title row
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        Text(formatDate(task.scheduled_date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

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

    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var date: Date?
        date = isoFormatter.date(from: dateString)

        if date == nil {
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            date = simpleFormatter.date(from: dateString)
        }

        if date == nil {
            let isoFormatter2 = ISO8601DateFormatter()
            date = isoFormatter2.date(from: dateString)
        }

        guard let parsedDate = date else { return dateString }

        if Calendar.current.isDateInToday(parsedDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(parsedDate) {
            return "Tomorrow"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
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
