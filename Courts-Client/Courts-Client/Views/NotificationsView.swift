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
    var chats: [Chat] = sampleChats

    
    var body: some View {
        List(chats) { chat in
            NavigationLink(destination: ChatDetailView(chat: chat)) {
                VStack(alignment: .leading) {
                    Text(chat.name)
                        .font(.headline)
                    Text(chat.lastMessage?.content ?? "No messages yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

struct ChatDetailView: View {
    let chat: Chat
    
    var body: some View {
        VStack {
            List(chat.messages) { message in
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(message.sender)
                            .font(.headline)
                        Text(message.content)
                            .font(.body)
                    }
                    Spacer()
                    Text(message.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle(chat.name)
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

let sampleMessages: [Message] = [
    Message(sender: "Ali", content: "Hey! Are we still on for our match today?", timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!),
    Message(sender: "You", content: "Yes! I'll be there in 15 minutes.", timestamp: Calendar.current.date(byAdding: .minute, value: -10, to: Date())!),
    Message(sender: "Ali", content: "Great! See you soon.", timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!),
    Message(sender: "You", content: "I'm here!", timestamp: Date()),
]

let sampleChats: [Chat] = [
    Chat(name: "Ali", messages: sampleMessages),
    Chat(name: "Omar", messages: [
        Message(sender: "Omar", content: "Want to team up for the tournament?", timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!),
        Message(sender: "You", content: "Sure! Let's register.", timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!),
    ]),
    Chat(name: "Sara", messages: [
        Message(sender: "Sara", content: "Hey, good game today!", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
    ])
]


#Preview {
    NotificationsView()
}
