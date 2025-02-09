//
//  EditProfileView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 04/02/2025.
//

import SwiftUI

struct EditProfileView: View {
    @StateObject private var viewModel: EditProfileViewModel
    
    init(authViewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(authViewModel: authViewModel))
    }

    var body: some View {
        VStack {
            // 🔹 Custom Navigation Bar
            HStack {
                Button(action: {
                    // Go back action
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                Text("Edit Profile")
                    .font(.headline)
                
                Spacer()
                Button(action: viewModel.saveChanges) {
                    Text("Save")
                        .foregroundColor(viewModel.hasChanges ? .blue : .gray)
                }
                .disabled(!viewModel.hasChanges) // 🔹 Disable until changes are made
            }
            .padding()
            
            // 🔹 Profile Picture Section
            VStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
                
                Button("Change Profile Picture") {
                    // Handle profile picture change
                }
                .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
            
            // 🔹 Personal Information
            Text("Personal Information")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.top, 10)
            
            Form {
                TextField("First Name", text: $viewModel.firstName, onEditingChanged: { _ in viewModel.checkForChanges() })
                TextField("Last Name", text: $viewModel.lastName, onEditingChanged: { _ in viewModel.checkForChanges() })
                TextField("Email", text: $viewModel.email, onEditingChanged: { _ in viewModel.checkForChanges() })
                    .keyboardType(.emailAddress)
                TextField("Phone Number", text: $viewModel.phone, onEditingChanged: { _ in viewModel.checkForChanges() })
                    .keyboardType(.phonePad)
                TextField("Date of Birth", text: $viewModel.dateOfBirth, onEditingChanged: { _ in viewModel.checkForChanges() })
                TextField("Gender", text: $viewModel.gender, onEditingChanged: { _ in viewModel.checkForChanges() })
                TextField("Location", text: $viewModel.location, onEditingChanged: { _ in viewModel.checkForChanges() })
            }
            
            // 🔹 Player Preferences Section
            Text("Player Preferences")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.top, 10)
            
            Button(action: {
                // Navigate to PlayerPreferencesView
            }) {
                Text("Edit Player Preferences")
                    .foregroundColor(.blue)
            }
            .padding(.bottom, 20)
            
            // 🔹 Password Section
            Text("Password")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
                .padding(.top, 10)
            
            SecureField("Enter new password", text: $viewModel.newPassword, onCommit: {
                viewModel.checkForChanges()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)

            Spacer()
        }
    }
}

