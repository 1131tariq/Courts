//
//  ProfileView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let user = authViewModel.user {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text("\(user.first_name ?? "") \(user.last_name ?? "")")
                            .font(.title2)
                            .bold()
                        
                        Button(action: { /* Change location action */ }) {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                Text(user.location ?? "Set your location")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Account Type: \(user.accountType)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                HStack {
                    NavigationLink(destination: MatchesListView()) {
                        VStack {
                            Text("\(user.matches.count)")
                                .font(.title3)
                                .bold()
                            Text("Matches")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                    NavigationLink(destination: FollowersListView()) {
                        VStack {
                            Text("\(user.followers.count)")
                                .font(.title3)
                                .bold()
                            Text("Followers")
                                .font(.subheadline)
                        }
                    }
                    Spacer()
                    NavigationLink(destination: FollowingListView()) {
                        VStack {
                            Text("\(user.following.count)")
                                .font(.title3)
                                .bold()
                            Text("Following")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                
                HStack(spacing: 20) {
                    NavigationLink(destination: EditProfileView()) {
                        Text("Edit Profile")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Button("Go Premium") {
                        // Go premium action
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Player Level: \(user.playerLevel)")
                        .font(.headline)
                    NavigationLink(destination: BookCourtView()) {
                        Text("Find a Match to Improve")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Player Preferences")
                        .font(.headline)
                    
                    NavigationLink(destination: PlayerPreferencesView()) {
                        Text("Best Hand: \(user.bestHand ?? "Not Set")")
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: PlayerPreferencesView()) {
                        Text("Court Position: \(user.courtPosition ?? "Not Set")")
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: PlayerPreferencesView()) {
                        Text("Match Type: \(user.matchType ?? "Not Set")")
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: PlayerPreferencesView()) {
                        Text("Preferred Time: \(user.preferredTime ?? "Not Set")")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            } else {
                Text("Loading profile...")
            }
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
