//
//  NotificationsView.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 02/02/2025.
//

import SwiftUI

import SwiftUI

struct NotificationsView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Tabs", selection: $selectedTab) {
                    Text("Notifications").tag(0)
                    Text("Chats").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    NotificationsListView()
                } else {
                    ChatsListView()
                }
                
                Spacer()
            }
            .navigationTitle("Inbox")
        }
    }
}

struct NotificationsListView: View {
    var notifications: [NotificationModel] = sampleNotifications

    
    var body: some View {
        List(notifications) { notification in
            Text(notification.message)
        }
    }
}

struct ChatsListView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        List(chatViewModel.chats) { chat in
            if let user = authViewModel.user { // ✅ Safely unwrap user
                NavigationLink(destination: ChatDetailView(userId: user.id, chatId: chat.id, participantName: "String")) {
                    VStack(alignment: .leading) {
                        Text("Chat with: \(chat.participants.map { String($0) }.joined(separator: ", "))")
                            .font(.headline)
                        Text(chat.lastMessage?.content ?? "No messages yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Text("Loading user data...") // ✅ Show a placeholder if user is nil
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            chatViewModel.fetchChats() // ✅ Fetches chats from the ViewModel
        }
    }
}

struct ChatDetailView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    let userId: Int
    let chatId: Int
    let participantName: String // ✅ Added name of the person you're chatting with
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy? // ✅ Used for auto-scrolling

    var body: some View {
        VStack {
            // ✅ Fixed header with participant's name
            HStack {
                Text("Chat with \(participantName)")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .background(Color.gray.opacity(0.2))

            ScrollViewReader { proxy in // ✅ Enables auto-scrolling
                ScrollView {
                    VStack {
                        ForEach(chatViewModel.messages) { message in
                            HStack {
                                if message.sender == userId {
                                    Spacer()
                                    Text(message.content)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .id(message.id) // ✅ Identify messages for scrolling
                                } else {
                                    Text(message.content)
                                        .padding()
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                        .id(message.id) // ✅ Identify messages for scrolling
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .onAppear {
                        scrollProxy = proxy // ✅ Save proxy to use later
                        scrollToBottom()
                    }
                    .onChange(of: chatViewModel.messages.count) {
                        scrollToBottom() // ✅ Scroll when new messages arrive
                    }
                }
            }

            HStack {
                TextField("Enter message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Send") {
                    chatViewModel.sendMessage(chatId: chatId, userId: userId, content: messageText)
                    messageText = ""
                    scrollToBottom()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            chatViewModel.fetchMessages(for: chatId)
            chatViewModel.connectToChat(userId: userId, chatId: chatId)
        }
        .onDisappear {
            chatViewModel.disconnect()
        }
    }

    // ✅ Helper function to scroll to the bottom
    private func scrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let lastMessage = chatViewModel.messages.last {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}



// MARK: - Models
struct NotificationModel: Identifiable {
    let id = UUID()
    let message: String
    let date: Date
}

let sampleNotifications: [NotificationModel] = [
    NotificationModel(message: "Your court booking for 5 PM is confirmed!", date: Date()),
    NotificationModel(message: "Match results are in! Check your updated ranking.", date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!),
    NotificationModel(message: "New paddle court available near you!", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
    NotificationModel(message: "A new player has challenged you for a match!", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
]

#Preview {
    NotificationsView()
}
