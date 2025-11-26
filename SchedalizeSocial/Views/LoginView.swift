//
//  LoginView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isSignupMode = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.96, green: 0.97, blue: 0.98)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Logo/Title Section
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))

                        Text("Schedalize Social")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.13, green: 0.16, blue: 0.24))

                        Text(isSignupMode ? "Create your account" : "Welcome back")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                    }
                    .padding(.top, 60)

                    // Form Section
                    VStack(spacing: 16) {
                        if isSignupMode {
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.words)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 24)

                    // Action Button
                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text(isSignupMode ? "Sign Up" : "Log In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(Color(red: 0.29, green: 0.42, blue: 0.98))
                    .cornerRadius(12)
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 24)

                    // Toggle Mode Button
                    Button(action: { isSignupMode.toggle() }) {
                        HStack(spacing: 4) {
                            Text(isSignupMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(Color(red: 0.42, green: 0.47, blue: 0.55))
                            Text(isSignupMode ? "Log In" : "Sign Up")
                                .foregroundColor(Color(red: 0.29, green: 0.42, blue: 0.98))
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                    .disabled(isLoading)

                    Spacer()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isFormValid: Bool {
        if isSignupMode {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    private func handleAuth() {
        isLoading = true
        errorMessage = ""

        Task {
            do {
                let response: AuthResponse
                if isSignupMode {
                    response = try await ApiClient.shared.signup(email: email, password: password, fullName: fullName)
                } else {
                    response = try await ApiClient.shared.login(email: email, password: password)
                }

                await MainActor.run {
                    TokenManager.shared.saveToken(response.access_token)
                    TokenManager.shared.saveUser(response.user)
                    isLoggedIn = true
                }
            } catch let error as APIError {
                await MainActor.run {
                    switch error {
                    case .serverError(let message):
                        errorMessage = message
                    case .networkError:
                        errorMessage = "Network error. Please check your connection."
                    case .unauthorized:
                        errorMessage = "Invalid credentials."
                    default:
                        errorMessage = "An error occurred. Please try again."
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
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.89, green: 0.90, blue: 0.92), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
