//
//  EditProfileViewModel.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 07/02/2025.
//

import Foundation
import SwiftUI
import Combine

class EditProfileViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var dateOfBirth: String = ""
    @Published var gender: String = ""
    @Published var location: String = ""
    @Published var newPassword: String = ""

    @Published var hasChanges: Bool = false
    
    private var authViewModel: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        loadUserData()
    }
    // 🔹 Load User Data from AuthViewModel
    func loadUserData() {
        if let user = authViewModel.user {
            firstName = user.first_name ?? ""
            lastName = user.last_name ?? ""
            email = user.email ?? ""
            phone = user.phone ?? ""          // Safely unwrap
            dateOfBirth = user.date_of_birth ?? "" // Safely unwrap
            gender = user.gender ?? ""        // Safely unwrap
            location = user.location ?? ""
        }
    }

    // 🔹 Detect Changes in Form Fields
    func checkForChanges() {
        if let user = authViewModel.user {
            hasChanges = (firstName != user.first_name ||
                          lastName != user.last_name ||
                          email != user.email ||
                          phone != (user.phone ?? "") ||         // Safely unwrap
                          dateOfBirth != (user.date_of_birth ?? "") || // Safely unwrap
                          gender != (user.gender ?? "") ||       // Safely unwrap
                          location != user.location ||
                          !newPassword.isEmpty)
        }
    }

    // 🔹 Save Changes to Backend
    func saveChanges() {
        guard hasChanges else { return }
        
        var updatedData: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "phone": phone,
            "date_of_birth": dateOfBirth,
            "gender": gender,
            "location": location
        ]
        
        if !newPassword.isEmpty {
            updatedData["password"] = newPassword
        }
        
        authViewModel.updateProfile(data: updatedData) {
            print("✅ Profile updated successfully!")
            DispatchQueue.main.async {
                self.hasChanges = false
            }
        }
    }
}
