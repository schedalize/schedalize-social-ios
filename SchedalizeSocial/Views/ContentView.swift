//
//  ContentView.swift
//  SchedalizeSocial
//
//  Created by Schedalize on 2025-11-26.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainView()
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            checkLoginStatus()
        }
    }

    private func checkLoginStatus() {
        isLoggedIn = TokenManager.shared.hasValidToken()
    }
}

#Preview {
    ContentView()
}
