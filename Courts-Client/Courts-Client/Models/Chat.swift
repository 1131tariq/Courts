//
//  Chat.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct Chat: Identifiable {
    let id = UUID()
    let name: String
    let messages: [Message]
    
    var lastMessage: Message? {
        messages.last
    }
}
