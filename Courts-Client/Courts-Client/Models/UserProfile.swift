//
//  UserProfile.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct UserProfile: Codable {
    var first_name: String?
    var last_name: String?
    var email: String?
    var location: String?
    var accountType: String
    var matches: [Int] // List of match IDs
    var followers: [Int] // List of user IDs
    var following: [Int] // List of user IDs
    var playerLevel: String
    var bestHand: String?
    var courtPosition: String?
    var matchType: String?
    var preferredTime: String?
}
