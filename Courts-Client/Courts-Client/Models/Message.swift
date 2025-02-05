//
//  Message.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let chatId: Int // ✅ Added this field to match API response
    let sender: Int
    let content: String
    let timestamp: Date
}



