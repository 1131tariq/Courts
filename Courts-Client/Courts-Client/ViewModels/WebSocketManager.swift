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
        if webSocketTask != nil {
            print("⚠️ WebSocket is already connected.")
            return
        }
        
        print("🔹 Connecting to WebSocket as user \(userId)")
        webSocketTask = URLSession.shared.webSocketTask(with: serverURL)
        webSocketTask?.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔹 Sending joinChat event for user \(userId)")
            
            let joinMessage: [String: Any] = [
                "event": "joinChat",
                "data": ["userId": userId]
            ]
            
            self.sendMessage(data: joinMessage) // ✅ Ensure join event is sent
            self.receiveMessages() // ✅ Start listening immediately
        }
    }


    func sendMessage(data: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data) // ✅ No extra wrapping
            let message = URLSessionWebSocketTask.Message.data(jsonData)
            
            print("📤 Sending WebSocket Message:", String(data: jsonData, encoding: .utf8) ?? "{}") // ✅ Debugging Output

            webSocketTask?.send(message) { error in
                if let error = error {
                    print("Error sending message: \(error)")
                }
            }
            self.receiveMessages()
        } catch {
            print("Failed to serialize message data: \(error)")
        }
    }

    func receiveMessages() {
        print("🔄 Listening for incoming messages...")

        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                print("📥 Raw WebSocket Message Received:", message) // ✅ Log raw message
                
                if case let .string(text) = message { // ✅ First check if it's a string
                    guard let jsonData = text.data(using: .utf8) else {
                        print("❌ Failed to convert received string to Data")
                        return
                    }
                    self?.handleIncomingMessage(jsonData) // ✅ Process JSON properly
                } else if case let .data(data) = message { // ✅ If it's already Data
                    self?.handleIncomingMessage(data)
                }
            case .failure(let error):
                print("❌ Error receiving message:", error)
            }

            self?.receiveMessages() // ✅ Keep listening for messages
        }
    }

    // ✅ Helper function to properly decode incoming JSON
    private func handleIncomingMessage(_ data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            print("📥 Parsed WebSocket Message:", jsonObject ?? "nil") // ✅ Debugging output
            
            if let event = jsonObject?["event"] as? String, event == "newMessage",
               let messageData = jsonObject?["data"] as? [String: Any] {
                
                let jsonData = try JSONSerialization.data(withJSONObject: messageData)
                let receivedMessage = try JSONDecoder().decode(Message.self, from: jsonData)

                DispatchQueue.main.async {
                    self.messages.append(receivedMessage)
                    print("✅ Message added to UI:", receivedMessage)
                }
            } else {
                print("⚠️ Invalid WebSocket message format:", jsonObject ?? "nil")
            }
        } catch {
            print("❌ Error decoding received message:", error)
        }
    }


    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
