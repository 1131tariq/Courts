//
//  SettingsView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(authViewModel.user?.first_name ?? "") \(authViewModel.user?.last_name ?? "")")
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                }
                .padding()
                
                Form {
                    Section(header: Text("Your Account")) {
                        NavigationLink("Edit Profile", destination: EditProfileView())
                        NavigationLink("Your Activity", destination: ActivityView())
                        NavigationLink("Your Payments", destination: PaymentsView())
                        NavigationLink("Settings", destination: AppSettingsView())
                    }
                    
                    Section(header: Text("Support")) {
                        NavigationLink("Help", destination: HelpView())
                        NavigationLink("How Courts Works", destination: HowCourtsWorksView())
                    }
                    
                    Section(header: Text("Legal Information")) {
                        NavigationLink("Terms of Use", destination: TermsOfUseView())
                        NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                    }
                    
                    Section {
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            Text("Log Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
             // Hides default back button
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss() // Custom back button for HomeView
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Home")
                }
                .foregroundColor(.blue)
            })
        }
    }
}

// MARK: - Placeholder Views
struct EditProfileView: View {
    var body: some View { Text("Edit Profile") }
}

struct ActivityView: View {
    var body: some View { Text("Your Activity") }
}

struct PaymentsView: View {
    var body: some View { Text("Your Payments") }
}

struct AppSettingsView: View {
    var body: some View { Text("App Settings") }
}

struct HelpView: View {
    var body: some View { Text("Help") }
}

struct HowCourtsWorksView: View {
    var body: some View { Text("How Courts Works") }
}

struct TermsOfUseView: View {
    var body: some View { Text("Terms of Use") }
}

struct PrivacyPolicyView: View {
    var body: some View { Text("Privacy Policy") }
}

#Preview {
    SettingsView()
}
