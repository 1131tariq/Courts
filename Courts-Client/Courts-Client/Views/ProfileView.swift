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
        VStack {
            if let user = authViewModel.user {
                Text("\(user.first_name ?? "") \(user.last_name ?? "")")
                    .font(.title)
                    .bold()
                    .padding()
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                Button("Logout") {
                    authViewModel.logout()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
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
