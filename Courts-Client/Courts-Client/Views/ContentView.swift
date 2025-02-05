//
//  ContentView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, community, profile
    }

    var body: some View {
        NavigationStack {  // Move NavigationStack here
            VStack(spacing: 0) {
                HStack {
                    Text(tabTitle(selectedTab))
                        .font(.title2)
                        .bold()
                    Spacer()
                    HStack(spacing: 16) {
                        NavigationLink(destination: NotificationsView()) {
                            Image(systemName: "bell")
                                .font(.title2)
                        }
                        NavigationLink(destination: SettingsView().navigationBarBackButtonHidden(true)) {
                            Image(systemName: "gear")
                                .font(.title2)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))

                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house") }
                        .tag(Tab.home)

                    CommunityView()
                        .tabItem { Label("Community", systemImage: "person.3") }
                        .tag(Tab.community)

                    ProfileView()
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(Tab.profile)
                }
            }
        }
    }

    func tabTitle(_ tab: Tab) -> String {
        if tab == .home, let user = authViewModel.user {
            return "Hi \(user.first_name ?? "") 👋🏻"
        }
        switch tab {
        case .home: return "Home"
        case .community: return "Community"
        case .profile: return "Profile"
        }
    }
}

#Preview {
    ContentView()
}



#Preview {
    ContentView()
}
