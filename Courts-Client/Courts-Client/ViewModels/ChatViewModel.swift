//
//  ChatViewModel.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 04/02/2025.
//
import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var chats: [Chat] = [] // Store fetched chats
    
    private var webSocketManager: WebSocketManager? // ✅ Prevent multiple WebSocket instances
    private var cancellables = Set<AnyCancellable>()

    func connectToWebSocket(userId: Int) {
        if webSocketManager == nil {
            webSocketManager = WebSocketManager()
            webSocketManager?.connect(userId: String(userId)) // ✅ Ensure WebSocket is connected
        }
    }
    
    func fetchMessages(for chatId: Int) {
        guard let url = URL(string: "http://localhost:3000/chats/\(chatId)/messages") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Message].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error fetching messages:", error)
                }
            }, receiveValue: { [weak self] fetchedMessages in
                DispatchQueue.main.async {
                    self?.messages = fetchedMessages
                }
            })
            .store(in: &cancellables)
    }
    
    func fetchChats() {
        guard let url = URL(string: "http://localhost:3000/chats") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Chat].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ Error fetching chats:", error)
                }
            }, receiveValue: { [weak self] fetchedChats in
                DispatchQueue.main.async {
                    self?.chats = fetchedChats
                }
            })
            .store(in: &cancellables)
    }
    
    func connectToChat(userId: Int, chatId: Int) {
        connectToWebSocket(userId: userId) // ✅ Ensure WebSocket is connected before subscribing
        
        webSocketManager?.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newMessages in
                DispatchQueue.main.async {
                    for message in newMessages {
                        if message.chatId == chatId && !(self?.messages.contains(where: { $0.id == message.id }) ?? false) {
                            self?.messages.append(message) // ✅ Append instead of replacing
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    
    func sendMessage(chatId: Int, userId: Int, content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ Cannot send an empty message.")
            return
        }

        let message = Message(
            id: Int.random(in: 1000...9999),
            chatId: chatId,
            sender: userId,
            content: content,
            timestamp: Date().timeIntervalSince1970
        )

        let messageData: [String: Any] = [  // ✅ Fixed JSON structure
            "event": "sendMessage",
            "data": [
                "userId": userId,
                "chatId": chatId,
                "sender": userId,
                "content": content,
                "timestamp": message.timestamp
            ]
        ]

        webSocketManager?.sendMessage(data: messageData) // ✅ Ensures message is sent correctly
    }

    func disconnect() {
        webSocketManager?.disconnect()
        webSocketManager = nil // ✅ Prevents reconnect issues
    }
}
