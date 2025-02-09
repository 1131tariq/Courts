//
//  AuthViewModel.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct LoginResponse: Codable {
    let message: String
    let user: UserProfile
}

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: UserProfile?
    
    func checkAuthStatus() {
        guard let url = URL(string: "http://localhost:3000/auth/status") else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode([String: UserProfile].self, from: data)
                DispatchQueue.main.async {
                    self.isAuthenticated = response["user"] != nil
                    self.user = response["user"]
                }
            } catch {
                print("Error checking auth status: \(error.localizedDescription)")
            }
        }
    }
    
    func login(email: String, password: String) {
        guard let url = URL(string: "http://localhost:3000/login") else { return }
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: String] = ["email": email, "password": password]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    print("🔹 Login HTTP Response Code:", httpResponse.statusCode)
                }

                let jsonString = String(data: data, encoding: .utf8) ?? "Invalid JSON"
                print("🔹 Raw JSON Response:", jsonString) // Debugging

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let decodedResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.isAuthenticated = true
                        self.user = decodedResponse.user
                    }
                } else {
                    print("❌ Login failed with response:", jsonString)
                }
            } catch {
                print("❌ Error logging in:", error.localizedDescription)
            }
        }
    }

    func register(email: String, password: String) {
            guard let url = URL(string: "http://localhost:3000/register") else { return }
            Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let body: [String: String] = ["email": email, "password": password]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                        let decodedResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                        DispatchQueue.main.async {
                            self.isAuthenticated = true
                            self.user = decodedResponse.user
                        }
                    }
                } catch {
                    print("Error registering: \(error.localizedDescription)")
                }
            }
        }
    
    func logout() {
        guard let url = URL(string: "http://localhost:3000/logout") else { return }
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.isAuthenticated = false
                        self.user = nil
                    }
                }
            } catch {
                print("Error logging out: \(error.localizedDescription)")
            }
        }
    }
    
    struct UpdateProfileResponse: Codable {
        let message: String
        let user: UserProfile
    }
    
    func updateProfile(data: [String: Any], completion: @escaping () -> Void) {
            guard let userId = user?.id else { return }
            guard let url = URL(string: "http://localhost:3000/profile/update/\(userId)") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                request.httpBody = jsonData
            } catch {
                print("❌ Error encoding update data:", error)
                return
            }

            Task {
                do {
                    let (responseData, _) = try await URLSession.shared.data(for: request)
                    let decodedResponse = try JSONDecoder().decode(UpdateProfileResponse.self, from: responseData)

                    DispatchQueue.main.async {
                        self.user = decodedResponse.user
                        completion()
                        print("✅ Profile updated successfully!")
                    }
                } catch {
                    print("❌ Error updating profile:", error)
                }
            }
        }
}
