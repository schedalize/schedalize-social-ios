//
//  HistoryView.swift
//  SchedulizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct HistoryView: View {
    @State private var historyItems: [HistoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else if historyItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.5))

                        Text("No history yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))

                        Text("Your generated replies will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55).opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(historyItems) { item in
                                HistoryItemCard(item: item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadHistory()
            }
            .task {
                await loadHistory()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = ""

        do {
            let response = try await ApiClient.shared.getHistory()
            await MainActor.run {
                historyItems = response.replies
                isLoading = false
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .serverError(let message):
                    errorMessage = message
                default:
                    errorMessage = "Failed to load history. Please try again."
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

struct HistoryItemCard: View {
    let item: HistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with platform
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: platformIcon(item.platform))
                        .font(.system(size: 12))
                    Text(item.platform.capitalized)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0.29, green: 0.42, blue: 0.98).opacity(0.1))
                .cornerRadius(6)

                Spacer()

                Text(formatDate(item.created_at))
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
            }

            // Original Message
            VStack(alignment: .leading, spacing: 6) {
                Text("Original Message")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))

                Text(item.original_message)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                    .lineLimit(3)
            }

            Divider()

            // Generated Replies
            VStack(alignment: .leading, spacing: 8) {
                Text("Generated Replies")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))

                ForEach(item.generated_replies) { reply in
                    HStack(alignment: .top, spacing: 8) {
                        Text(reply.tone.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.29, green: 0.42, blue: 0.98).opacity(0.1))
                            .cornerRadius(4)

                        Text(reply.text)
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                            .lineLimit(2)

                        Spacer()

                        Button(action: { copyToClipboard(reply.text) }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                        }
                    }
                }
            }
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

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

#Preview {
    HistoryView()
}
