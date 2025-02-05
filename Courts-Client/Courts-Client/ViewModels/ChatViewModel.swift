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
    
    private var webSocketManager = WebSocketManager()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchMessages(for chatId: Int) {
        guard let url = URL(string: "http://localhost:3000/chats/\(chatId)/messages") else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Message].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error fetching messages: \(error)")
                }
            }, receiveValue: { [weak self] fetchedMessages in
                self?.messages = fetchedMessages
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
                    print("Error fetching chats: \(error)")
                }
            }, receiveValue: { [weak self] fetchedChats in
                DispatchQueue.main.async {
                    self?.chats = fetchedChats
                }
            })
            .store(in: &cancellables)
    }
    
    func connectToChat(userId: Int, chatId: Int) {
        webSocketManager.connect(userId: String(userId))
        webSocketManager.$messages
            .sink { [weak self] newMessages in
                DispatchQueue.main.async {
                    self?.messages = newMessages.filter { $0.chatId == chatId }
                }
            }
            .store(in: &cancellables)
    }
    
    func sendMessage(chatId: Int, sender: Int, content: String) {
        let message = Message(id: Int.random(in: 1000...9999), chatId: chatId, sender: sender, content: content, timestamp: Date())
        webSocketManager.sendMessage(event: "sendMessage", data: [
            "chatId": chatId,
            "sender": sender,
            "content": content,
            "timestamp": ISO8601DateFormatter().string(from: message.timestamp)
        ])
    }
    
    func disconnect() {
        webSocketManager.disconnect()
    }
}
