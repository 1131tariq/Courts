//
//  Message.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct Message: Identifiable {
    let id = UUID()
    let sender: String
    let content: String
    let timestamp: Date
}
