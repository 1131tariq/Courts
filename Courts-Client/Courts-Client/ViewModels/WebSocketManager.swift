//
//  WebSocketManager.swift
//  Courts-Client
//
//  Created by Tareq Batayneh on 04/02/2025.
//

import Foundation

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var messages: [Message] = []
    private let serverURL = URL(string: "ws://localhost:3000")!
    
    func connect(userId: String) {
        webSocketTask = URLSession.shared.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        sendMessage(event: "joinChat", data: ["userId": userId])
        receiveMessages()
    }
    
    func sendMessage(event: String, data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: ["event": event, "data": data])
            let message = URLSessionWebSocketTask.Message.data(jsonData)
            webSocketTask?.send(message) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
        } catch {
            print("Failed to serialize message data: \(error)")
        }
    }
    
    func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case let .data(data) = message {
                    do {
                        let receivedMessage = try JSONDecoder().decode(Message.self, from: data)
                        DispatchQueue.main.async {
                            self?.messages.append(receivedMessage)
                        }
                    } catch {
                        print("Error decoding received message: \(error)")
                    }
                }
            case .failure(let error):
                print("Error receiving message: \(error)")
            }
            self?.receiveMessages() // Keep listening for messages
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
