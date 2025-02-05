//
//  HomeView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink(destination: PlayerPreferencesView()) {
                    HomeCard(title: "Edit Your Player Preferences", subtitle: "Best hand, court side, match type...", color: .blue)
                }

                NavigationLink(destination: BookCourtView()) {
                    HomeCard(title: "Book Your Court", subtitle: "Reserve a paddle tennis court now!", color: .green)
                }

                NavigationLink(destination: MatchmakingView()) {
                    HomeCard(title: "Matchmaking", subtitle: "Find and play with other players.", color: .orange)
                }

                NavigationLink(destination: TournamentsView()) {
                    HomeCard(title: "Tournaments", subtitle: "Join and compete in tournaments.", color: .red)
                }

                NavigationLink(destination: ClassesView()) {
                    HomeCard(title: "Classes", subtitle: "Improve your game with professional training.", color: .purple)
                }
            }
            .padding()
        }
        .navigationTitle("Lets Paddle")
    }
}

struct HomeCard: View {
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(color)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}
