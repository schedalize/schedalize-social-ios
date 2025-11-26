//
//  MainView.swift
//  SchedulizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var selectedTab = 0
    @State private var message = ""
    @State private var selectedPlatform = "Instagram"
    @State private var generatedReplies: [GeneratedReply] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    let platforms = ["Instagram", "TikTok", "Email"]

    var body: some View {
        TabView(selection: $selectedTab) {
            // Reply Generation Tab
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Generate Reply")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))

                            Text("Create AI-powered responses")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Message Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))

                            TextEditor(text: $message)
                                .frame(height: 120)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.89, green: 0.90, blue: 0.92), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)

                        // Platform Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Platform")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))

                            HStack(spacing: 12) {
                                ForEach(platforms, id: \.self) { platform in
                                    Button(action: { selectedPlatform = platform }) {
                                        HStack(spacing: 8) {
                                            platformIcon(platform)
                                            Text(platform)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(selectedPlatform == platform ?
                                                   Color(red: 0.29, green: 0.42, blue: 0.98) : Color.white)
                                        .foregroundColor(selectedPlatform == platform ? .white : Color(red: 0.13, green: 0.16, blue: 0.24))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedPlatform == platform ? Color.clear : Color(red: 0.89, green: 0.90, blue: 0.92), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Generate Button
                        Button(action: generateReplies) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text("Generate Replies")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(Color(red: 0.29, green: 0.42, blue: 0.98))
                        .cornerRadius(12)
                        .disabled(isLoading || message.isEmpty)
                        .opacity(message.isEmpty ? 0.6 : 1.0)
                        .padding(.horizontal, 20)

                        // Generated Replies
                        if !generatedReplies.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Generated Replies")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                    .padding(.horizontal, 20)

                                ForEach(generatedReplies) { reply in
                                    ReplyCard(reply: reply)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .navigationBarItems(trailing: logoutButton)
            }
            .tabItem {
                Label("Replies", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .tag(0)

            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            // Posts Tab
            PostsView()
                .tabItem {
                    Label("Posts", systemImage: "calendar")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.29, green: 0.42, blue: 0.98))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var logoutButton: some View {
        Button(action: logout) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
        }
    }

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        switch platform {
        case "Instagram":
            InstagramIconView(color: selectedPlatform == platform ? .white : Color(red: 0.13, green: 0.16, blue: 0.24), size: 16)
        case "TikTok":
            TikTokIconView(color: selectedPlatform == platform ? .white : Color(red: 0.13, green: 0.16, blue: 0.24), size: 16)
        case "Email":
            Image(systemName: "envelope.fill")
                .font(.system(size: 16))
        default:
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 16))
        }
    }

    private func generateReplies() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                let response = try await ApiClient.shared.generateReplies(
                    message: message,
                    platform: selectedPlatform.lowercased(),
                    includeEmojis: true
                )

                await MainActor.run {
                    generatedReplies = response.replies
                    isLoading = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    switch error {
                    case .unauthorized:
                        logout()
                    case .serverError(let message):
                        errorMessage = message
                        showError = true
                    default:
                        errorMessage = "Failed to generate replies. Please try again."
                        showError = true
                    }
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

    private func logout() {
        TokenManager.shared.clearToken()
        isLoggedIn = false
    }
}

struct ReplyCard: View {
    let reply: GeneratedReply

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(reply.tone.capitalized)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.29, green: 0.42, blue: 0.98).opacity(0.1))
                    .cornerRadius(6)

                Spacer()

                Button(action: { copyToClipboard(reply.text) }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                }
            }

            Text(reply.text)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

#Preview {
    MainView(isLoggedIn: .constant(true))
}
