//
//  CourtViewModel.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 08/02/2025.
//

import Foundation
import Combine
import CoreLocation

class CourtViewModel: ObservableObject {
    @Published var courts: [Court] = []
    @Published var filteredCourts: [Court] = []
    @Published var availableSlots: [AvailableSlot] = []
    @Published var selectedCourt: Court?
    @Published var selectedSlot: AvailableSlot?
    @Published var selectedDuration: Int = 60 // Default to 60 minutes
    @Published var searchText: String = ""
    @Published var selectedDate: Date = Date()

    private var cancellables = Set<AnyCancellable>()
    
    init() {
            print("CourtViewModel Initialized - Fetching Courts...")
            fetchCourts() // Ensure it runs when the view model is created
        }
    
    // 🔹 Fetch Courts from API
    func fetchCourts() {
        print("Fetching courts from API...")
        guard let url = URL(string: "http://localhost:3000/api/courts") else {
            print("Invalid API URL")
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Court].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error fetching courts:", error)
                case .finished:
                    print("Successfully fetched courts")
                }
            }, receiveValue: { courts in
                print("Courts fetched: \(courts.count)") // ✅ Debugging
                courts.forEach { print("Court: \($0.name) - Location: \($0.location)") } // ✅ Debugging

                self.courts = courts
                self.filteredCourts = courts
            })
            .store(in: &cancellables)
    }


    // 🔹 Fetch Available Slots for a Selected Court & Date
    func fetchAvailableSlots(for court: Court, date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        guard let url = URL(string: "http://localhost:3000/api/court/\(court.id)/available-slots?date=\(dateString)") else {
            print("❌ Invalid available slots API URL")
            return
        }

        print("📡 Fetching available slots from:", url)

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Error fetching available slots:", error)
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                return
            }
            
            print("📡 Raw API response:", String(data: data, encoding: .utf8) ?? "Invalid JSON")

            do {
                let decodedSlots = try JSONDecoder().decode([AvailableSlot].self, from: data)
                DispatchQueue.main.async {
                    self.availableSlots = self.breakIntoOneHourSlots(slots: decodedSlots)
                    print("✅ Available 1-hour slots fetched:", self.availableSlots.count)
                    self.availableSlots.forEach { print("🕒 Slot: \($0.start_time) - \($0.end_time)") }
                }
            } catch {
                print("❌ Decoding error:", error)
            }
        }.resume()
    }
    
    func breakIntoOneHourSlots(slots: [AvailableSlot]) -> [AvailableSlot] {
        var oneHourSlots: [AvailableSlot] = []
        var idCounter = 1

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // ✅ Ensure it handles ".000Z"

        for slot in slots {
            guard let start = isoFormatter.date(from: slot.start_time),
                  let end = isoFormatter.date(from: slot.end_time) else {
                print("❌ Failed to parse slot times: \(slot.start_time) - \(slot.end_time)")
                continue
            }

            print("⏳ Splitting Slot: \(slot.start_time) - \(slot.end_time)")

            var currentStart = start
            while currentStart < end {
                let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: currentStart) ?? end
                if nextHour > end { break } // Stop if exceeding original slot

                let formattedStart = isoFormatter.string(from: currentStart)
                let formattedEnd = isoFormatter.string(from: nextHour)

                oneHourSlots.append(AvailableSlot(id: idCounter, start_time: formattedStart, end_time: formattedEnd))
                print("🕒 Created Slot: \(formattedStart) - \(formattedEnd)")

                idCounter += 1
                currentStart = nextHour
            }
        }

        print("✅ Total 1-hour slots created:", oneHourSlots.count)
        return oneHourSlots
    }


    // 🔹 Book a Slot
    func bookSlot() {
        guard let court = selectedCourt, let slot = selectedSlot else { return }
        
        let bookingRequest = BookingRequest(
            court_id: court.id,
            user_id: 1, // Replace with actual user ID
            start_time: slot.start_time,
            duration: selectedDuration
        )
        
        guard let url = URL(string: "http://localhost:3000/api/book-slot") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(bookingRequest)
        
        URLSession.shared.dataTask(with: request).resume()
    }

    // 🔹 Search Courts by Name, Location, Date, and Time
    func searchCourts() {
            if searchText.isEmpty {
                filteredCourts = courts // Reset to show all courts when search is empty
            } else {
                filteredCourts = courts.filter { court in
                    court.name.localizedCaseInsensitiveContains(searchText) ||
                    court.location.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
}





