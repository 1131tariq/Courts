//
//  PaymentView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 08/02/2025.
//

import SwiftUI

struct PaymentView: View {
    @ObservedObject var viewModel: CourtViewModel

    var body: some View {
        VStack {
            Text("Confirm Payment").font(.title)
            Button("Confirm Booking") {
                viewModel.bookSlot()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}


#Preview {
    PaymentView(viewModel: CourtViewModel())
}
