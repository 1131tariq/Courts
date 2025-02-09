//
//  Court.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 08/02/2025.
//

import Foundation
import CoreLocation

struct Court: Identifiable, Codable {
    let id: Int
    let name: String
    let location: String
    let latitude: Double
    let longitude: Double
    let open_time: String
    let close_time: String

    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
