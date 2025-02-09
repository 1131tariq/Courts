//
//  AvailableSlot.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 08/02/2025.
//

import Foundation

struct AvailableSlot: Identifiable, Codable {
    let id: Int
    let start_time: String
    let end_time: String
}
