//
//  MainView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab = 0
    @State private var message = ""
    @State private var selectedPlatform = "Instagram"
    @State private var generatedReplies: [GeneratedReply] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var includeEmojis = true

    let platforms = ["Instagram", "TikTok", "Email"]

    // Quick Templates - same as Android app
    let quickTemplates: [(label: String, prompt: String)] = [
        // Positive/Neutral scenarios
        ("Thank You", "Customer says: Thanks for the info!\nGenerate a warm follow-up reply"),
        ("Great Question", "Customer asks: What services do you offer?\nGenerate an informative reply"),
        ("Happy to Help", "Customer says: I need help with my booking\nGenerate a helpful reply"),
        ("Book Now", "Customer says: I want to book an appointment\nGenerate a reply with booking instructions"),
        ("Pricing", "Customer asks: How much do your services cost?\nGenerate a reply about pricing"),
        ("Availability", "Customer asks: When are you available?\nGenerate a reply about availability"),
        // Negative/Difficult scenarios
        ("Complaint", "Customer says: I'm really frustrated with the service I received. This was not what I expected!\nGenerate a professional, empathetic reply that acknowledges their concern"),
        ("Refund", "Customer says: I want my money back. The service was not satisfactory.\nGenerate a calm, professional reply addressing their refund request"),
        ("Unhappy", "Customer says: I'm very disappointed. This is unacceptable.\nGenerate an empathetic reply that shows you care and want to make it right"),
        ("Delay", "Customer says: Why is this taking so long? I've been waiting forever!\nGenerate an apologetic reply explaining the delay professionally"),
        ("Cancel", "Customer says: I need to cancel my appointment/order.\nGenerate a polite reply handling the cancellation gracefully"),
        ("Negative Review", "Customer left a negative review: Poor experience, would not recommend.\nGenerate a professional public response that addresses concerns and invites them to discuss further")
    ]

    @State private var templatesExpanded = false

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

                        // Quick Templates Section
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: { withAnimation { templatesExpanded.toggle() } }) {
                                HStack {
                                    Text("Quick Templates")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                    Spacer()
                                    Image(systemName: templatesExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                                }
                            }

                            if templatesExpanded {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(quickTemplates, id: \.label) { template in
                                            Button(action: {
                                                message = template.prompt
                                                withAnimation { templatesExpanded = false }
                                            }) {
                                                Text(template.label)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(Color(red: 0.29, green: 0.42, blue: 0.98).opacity(0.1))
                                                    .cornerRadius(16)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Message Input
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Message")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                                Spacer()
                                if !message.isEmpty {
                                    Button(action: { message = "" }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                            Text("Clear")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                                    }
                                }
                            }

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

                        // Include Emoji Toggle
                        HStack {
                            Image(systemName: "face.smiling")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                            Text("Include Emojis")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                            Spacer()
                            Toggle("", isOn: $includeEmojis)
                                .labelsHidden()
                                .tint(Color(red: 0.29, green: 0.42, blue: 0.98))
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
                    includeEmojis: includeEmojis
                )

                await MainActor.run {
                    generatedReplies = response.replies
                    isLoading = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    switch error {
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
    MainView()
}
