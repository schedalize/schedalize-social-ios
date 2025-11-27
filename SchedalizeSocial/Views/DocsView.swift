//
//  DocsView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-27.
//

import SwiftUI

struct DocsView: View {
    @State private var docs: [Doc] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDoc: Doc?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if docs.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No documents")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(docs) { doc in
                            Button(action: { selectedDoc = doc }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title3)
                                        .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        if let category = doc.category {
                                            Text(category.capitalized)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Docs")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadDocs()
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
            .sheet(item: $selectedDoc) { doc in
                DocDetailView(doc: doc)
            }
        }
        .onAppear {
            if docs.isEmpty {
                Task {
                    await loadDocs()
                }
            }
        }
    }

    private func loadDocs() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await ApiClient.shared.getDocs()
            docs = response.docs
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct DocDetailView: View {
    let doc: Doc
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FormatText(content: doc.content)
                        .padding(20)
                }
            }
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Simple text formatter for our formatted text
struct FormatText: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseContent(), id: \.id) { line in
                lineView(for: line)
            }
        }
    }

    private func parseContent() -> [FormattedLine] {
        let lines = content.components(separatedBy: "\n")
        var formatted: [FormattedLine] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("━━━") {
                // Divider
                formatted.append(FormattedLine(id: index, type: .divider, text: ""))
            } else if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                // Bold heading - strip the **
                let text = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "*"))
                formatted.append(FormattedLine(id: index, type: .heading, text: text))
            } else if trimmed.hasPrefix("• ") || trimmed.hasPrefix("✓ ") {
                // Bullet point - keep as is
                formatted.append(FormattedLine(id: index, type: .bullet, text: trimmed))
            } else if trimmed.isEmpty {
                // Empty line
                formatted.append(FormattedLine(id: index, type: .empty, text: ""))
            } else {
                // Normal text - clean up inline markdown
                let cleanText = cleanMarkdown(trimmed)
                formatted.append(FormattedLine(id: index, type: .normal, text: cleanText))
            }
        }

        return formatted
    }

    private func cleanMarkdown(_ text: String) -> String {
        var cleaned = text

        // Remove inline bold (**text** or __text__)
        cleaned = cleaned.replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "$1", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "__([^_]+)__", with: "$1", options: .regularExpression)

        // Remove inline italic (*text* or _text_) - but be careful with single asterisks
        cleaned = cleaned.replacingOccurrences(of: "\\*([^*]+)\\*", with: "$1", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "_([^_]+)_", with: "$1", options: .regularExpression)

        // Remove code backticks (`text`)
        cleaned = cleaned.replacingOccurrences(of: "`([^`]+)`", with: "$1", options: .regularExpression)

        // Remove links [text](url) - keep just text
        cleaned = cleaned.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)

        return cleaned
    }

    @ViewBuilder
    private func lineView(for line: FormattedLine) -> some View {
        switch line.type {
        case .heading:
            Text(line.text)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                .padding(.top, 8)
                .padding(.bottom, 4)

        case .divider:
            Divider()
                .background(Color.secondary.opacity(0.3))
                .padding(.vertical, 16)

        case .bullet:
            Text(line.text)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
                .padding(.leading, 8)

        case .empty:
            Spacer()
                .frame(height: 8)

        case .normal:
            Text(line.text)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))
        }
    }
}

struct FormattedLine {
    let id: Int
    let type: LineType
    let text: String

    enum LineType {
        case heading
        case divider
        case bullet
        case normal
        case empty
    }
}

#Preview {
    DocsView()
}
