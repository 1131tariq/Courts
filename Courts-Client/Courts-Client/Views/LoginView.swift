//
//  LoginView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    
    var body: some View {
        VStack {
            Text(isRegistering ? "Register" : "Login")
                .font(.largeTitle)
                .bold()
                .padding()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if isRegistering {
                    authViewModel.register(email: email, password: password)
                } else {
                    authViewModel.login(email: email, password: password)
                }
            }) {
                Text(isRegistering ? "Register" : "Login")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            
            Button(action: {
                isRegistering.toggle()
            }) {
                Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
