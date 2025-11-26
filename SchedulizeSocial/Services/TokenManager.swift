//
//  TokenManager.swift
//  SchedulizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()

    private let tokenKey = "auth_token"
    private let userKey = "user_data"

    private init() {}

    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }

    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    func getUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }

    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    func hasValidToken() -> Bool {
        return getToken() != nil
    }
}
