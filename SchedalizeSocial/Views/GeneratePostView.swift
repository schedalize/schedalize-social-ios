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
    @State private var includeEmojis = true

    @State private var generatedContent: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    let platforms = ["instagram", "x", "tiktok", "linkedin"]

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
        }
    }

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        switch platform {
        case "instagram":
            Image(systemName: "camera")
        case "x", "twitter":
            Image(systemName: "at")
        case "tiktok":
            Image(systemName: "play.rectangle")
        case "linkedin":
            Image(systemName: "briefcase")
        default:
            Image(systemName: "globe")
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
                    includeEmojis: includeEmojis
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
