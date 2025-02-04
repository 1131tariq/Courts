//
//  Notification.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import Foundation

struct Notification: Identifiable, Codable {
    let id: Int
    let title: String
    let message: String
    let timestamp: String
}
