//
//  Chat.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct Chat: Identifiable, Codable {
    let id: Int
    let participants: [Int] // Stores user IDs instead of name
    let lastMessage: Message?
}
