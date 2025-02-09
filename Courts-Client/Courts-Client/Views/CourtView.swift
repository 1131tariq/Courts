import SwiftUI

struct CourtView: View {
    let court: Court
    @ObservedObject var viewModel: CourtViewModel
    @State private var selectedDuration = 60

    var body: some View {
        VStack {
            Text(court.name)
                .font(.largeTitle)
                .padding()

            Text("Location: \(court.location)")
                .font(.subheadline)
                .foregroundColor(.gray)

            // 📅 Date Picker with onChange
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                .padding()
                .onChange(of: viewModel.selectedDate) {
                    print("📅 Selected Date Changed: \(viewModel.selectedDate)")
                    viewModel.fetchAvailableSlots(for: court, date: viewModel.selectedDate)
                }

            // 🕒 Available Slots Grid
            if viewModel.availableSlots.isEmpty {
                Text("No available slots found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(viewModel.availableSlots) { slot in
                            Button(action: {
                                viewModel.selectedSlot = slot
                                print("✅ Selected Slot: \(slot.start_time) - \(slot.end_time)")
                            }) {
                                Text("\(formatTime(slot.start_time)) - \(formatTime(slot.end_time))")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.selectedSlot?.id == slot.id ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(viewModel.selectedSlot?.id == slot.id ? .white : .black)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
            }

            // ⏳ Duration Picker
            Picker("Select Duration", selection: $selectedDuration) {
                Text("60 min").tag(60)
                Text("90 min").tag(90)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // 🔘 Proceed to Payment
            NavigationLink(destination: PaymentView(viewModel: viewModel)) {
                Text("Proceed to Payment")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Book Court")
        .onAppear {
            print("📡 CourtView Appeared - Fetching Slots...")
            viewModel.fetchAvailableSlots(for: court, date: viewModel.selectedDate)
        }
    }
}

// Helper Function to Format Time
func formatTime(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    guard let date = formatter.date(from: dateString) else { return "Invalid Time" }
    
    let timeFormatter = DateFormatter()
    timeFormatter.timeStyle = .short
    return timeFormatter.string(from: date)
}

