//
//  UserProfile.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct UserProfile: Codable {
    var id: Int
    var first_name: String?
    var last_name: String?
    var email: String?
    var location: String?
    var accountType: String
    var matches: [Int] // List of match IDs
    var followers: [Int] // List of user IDs
    var following: [Int] // List of user IDs
    let phone: String?        // Optional property
    let date_of_birth: String? // Optional property
    let gender: String?       // Optional property
    var playerLevel: String
    var bestHand: String?
    var courtPosition: String?
    var matchType: String?
    var preferredTime: String?
}
