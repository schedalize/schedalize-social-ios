//
//  GeneratePostView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct GeneratePostView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var topic = ""
    @State private var selectedPlatform = "instagram"
    @State private var selectedMood = "focused"
    @State private var includeEmojis = true
    @State private var selectedPrompt: Prompt?
    @State private var prompts: [Prompt] = []

    @State private var generatedContent: String?
    @State private var isLoading = false
    @State private var isLoadingPrompts = false
    @State private var errorMessage: String?

    let platforms = ["instagram", "twitter", "tiktok", "linkedin"]
    let moods = ["excited", "tired", "focused", "grateful", "frustrated"]

    var body: some View {
        NavigationView {
            Form {
                // Topic Section
                Section {
                    TextEditor(text: $topic)
                        .frame(height: 100)
                } header: {
                    Text("Topic")
                } footer: {
                    Text("What do you want to post about?")
                }

                // Platform Section
                Section("Platform") {
                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(platforms, id: \.self) { platform in
                            HStack {
                                platformIcon(platform)
                                Text(platform.capitalized)
                            }
                            .tag(platform)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Mood Section
                Section {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(moods, id: \.self) { mood in
                            HStack {
                                Text(moodEmoji(mood))
                                Text(mood.capitalized)
                            }
                            .tag(mood)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Mood")
                } footer: {
                    Text(moodDescription(selectedMood))
                }

                // Prompt Selection
                Section {
                    if isLoadingPrompts {
                        HStack {
                            ProgressView()
                            Text("Loading prompts...")
                                .foregroundColor(.secondary)
                        }
                    } else if prompts.isEmpty {
                        Text("No prompts available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Prompt", selection: $selectedPrompt) {
                            ForEach(prompts) { prompt in
                                VStack(alignment: .leading) {
                                    Text(prompt.name)
                                    if let score = prompt.test_score {
                                        Text("Score: \(Int(score))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .tag(prompt as Prompt?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("AI Prompt")
                } footer: {
                    if let prompt = selectedPrompt {
                        Text(prompt.description ?? "Default prompt for generating human-like content")
                    }
                }

                // Options
                Section("Options") {
                    Toggle(isOn: $includeEmojis) {
                        Label("Include Emojis", systemImage: "face.smiling")
                    }
                }

                // Generate Button
                Section {
                    Button(action: generatePost) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Generating...")
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Label("Generate Post", systemImage: "wand.and.stars")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(topic.isEmpty || isLoading)
                }

                // Generated Content
                if let content = generatedContent {
                    Section {
                        Text(content)
                            .font(.body)
                            .padding(.vertical, 8)

                        Button(action: { UIPasteboard.general.string = content }) {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                        }
                    } header: {
                        HStack {
                            Text("Generated Content")
                            Spacer()
                            Button(action: generatePost) {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .disabled(isLoading)
                        }
                    }
                }

                // Error
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Generate Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                loadPrompts()
            }
        }
    }

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        switch platform {
        case "instagram":
            Image(systemName: "camera")
        case "twitter":
            Image(systemName: "at")
        case "tiktok":
            Image(systemName: "play.rectangle")
        case "linkedin":
            Image(systemName: "briefcase")
        default:
            Image(systemName: "globe")
        }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood {
        case "excited": return "energetic"
        case "tired": return "subdued"
        case "focused": return "direct"
        case "grateful": return "thankful"
        case "frustrated": return "determined"
        default: return ""
        }
    }

    private func moodDescription(_ mood: String) -> String {
        switch mood {
        case "excited": return "Great mood, optimistic, energy is up"
        case "tired": return "End of long week, more subdued, shorter sentences"
        case "focused": return "Work mode, direct, no fluff"
        case "grateful": return "Thankful and reflective, appreciating small wins"
        case "frustrated": return "Slightly frustrated at a problem, channeling it constructively"
        default: return ""
        }
    }

    private func loadPrompts() {
        isLoadingPrompts = true
        Task {
            do {
                let response = try await ApiClient.shared.getPrompts()
                await MainActor.run {
                    prompts = response.prompts
                    selectedPrompt = prompts.first(where: { $0.is_default }) ?? prompts.first
                    isLoadingPrompts = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load prompts"
                    isLoadingPrompts = false
                }
            }
        }
    }

    private func generatePost() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let response = try await ApiClient.shared.generateHumanPost(
                    topic: topic,
                    platform: selectedPlatform,
                    mood: selectedMood,
                    includeEmojis: includeEmojis,
                    promptId: selectedPrompt?.prompt_id
                )

                await MainActor.run {
                    generatedContent = response.content
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    GeneratePostView()
}
