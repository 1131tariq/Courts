//
//  BookingRequest.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 08/02/2025.
//

import Foundation

struct BookingRequest: Codable {
    let court_id: Int
    let user_id: Int
    let start_time: String
    let duration: Int
}
