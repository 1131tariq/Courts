//
//  BookCourtView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 04/02/2025.
//

import SwiftUI
import MapKit
import CoreLocation


struct BookCourtView: View {
    @StateObject var viewModel = CourtViewModel()
    @State private var showMapView = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 🔍 Search Bar
                TextField("Search courts...", text: $viewModel.searchText, onCommit: {
                    viewModel.searchCourts()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                // 🔁 Toggle Between List & Map View
                Picker("View Mode", selection: $showMapView) {
                    Text("List").tag(false)
                    Text("Map").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                if showMapView {
                    // 🌍 Map View
                    MapView(courts: viewModel.filteredCourts)
                        .frame(height: 300)
                } else {
                    // 📃 List View
                    List(viewModel.filteredCourts.isEmpty ? viewModel.courts : viewModel.filteredCourts) { court in
                        NavigationLink(destination: CourtView(court: court, viewModel: viewModel)) {
                            VStack(alignment: .leading) {
                                Text(court.name).font(.headline)
                                Text(court.location).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchCourts() // Ensure courts are loaded when view appears
            }
            .navigationTitle("Book a Court")
        }
    }
}

struct MapView: View {
    let courts: [Court]

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.9539, longitude: 35.9106), // Default center
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: courts) { court in
            MapAnnotation(coordinate: court.locationCoordinate) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                    Text(court.name)
                        .font(.caption)
                        .foregroundColor(.black)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
        }
    }
}



#Preview {
    BookCourtView()
}
