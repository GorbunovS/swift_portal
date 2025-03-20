import Foundation
import Combine
import SwiftUI
// import Starscream

enum ChatError: Error {
    case serverError(String)
    case networkError(String)
    case decodingError(String)
}

class ChatStore: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var currentChatId: Int? = nil
    @Published var messages: [Message] = []
    @Published var notification: ChatNotification?
    @Published var forwardingMessages: [Message] = []
    @Published var scrollPositions: [Int: CGFloat] = [:]
    @Published var chatWithColleague: Int?
    @Published var isFromColleaguePage: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var isNewMessage: Bool = false
    @Published var isConnected: Bool = false
    @Published var news: [News] = []
    
    // Используем более гибкий подход, впоследствии это можно заменить на чтение из конфигурационного файла
    // или использовать относительные URL
    #if DEBUG
    private let baseURL = "http://192.168.1.67:5005"
    private let apiURL = "http://192.168.1.67:5005/api"
    private let wsProtocol = "ws"
    #else

    #endif
    
    private let userDefaults = UserDefaults.standard
    private var socket: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTimer: Timer?
    private let userStore: UserStore
    
    // Публичный доступ к списку пользователей
    var users: [User] {
        return userStore.users
    }
    
    init(userStore: UserStore) {
        self.userStore = userStore
    }
    
    func setupWebSocket() {
//        guard let token = userDefaults.string(forKey: "token") else {
//            print("Error setting up WebSocket: No token")
//            return
//        }
        
        // Close existing connection if any
        socket?.cancel()
        
        // Create WebSocket URL without socket.io path
        let socketHost = baseURL.replacingOccurrences(of: "http://", with: "")
                               .replacingOccurrences(of: "https://", with: "")
        let socketURL = "\(wsProtocol)://\(socketHost)/ws?token=\(userStore.token)"
        print("Connecting to WebSocket: \(socketURL)")
        
        guard let url = URL(string: socketURL) else {
            print("Error: Invalid WebSocket URL")
            return
        }
        
        let session = URLSession(configuration: .default)
        self.session = session
        
        socket = session.webSocketTask(with: url)
        
        // Setup ping timer
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.socket != nil {
                print("Sending ping")
                self.socket?.send(.string("ping")) { error in
                    if let error = error {
                        print("Error sending ping: \(error)")
                    }
                }
            } else {
                print("WebSocket not connected, attempting to reconnect...")
                DispatchQueue.main.async {
                    self.setupWebSocket()
                }
            }
        }
        
        // Start receiving messages
        socket?.resume()
        receiveMessage()
    }
    
    private func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received message: \(text)")
                    self.handleSocketIOMessage(text)
                case .data(let data):
                    print("Received binary data: \(data.count) bytes")
                @unknown default:
                    print("Received unknown message type")
                }
                
                // Continue listening for messages
                self.receiveMessage()
                
            case .failure(let error):
                print("WebSocket error: \(error)")
                self.isConnected = false
                
                // Try to reconnect after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                    self?.setupWebSocket()
                }
            }
        }
    }
    
    private func handleSocketIOMessage(_ message: String) {
        // Handle different socket.io message types
        if message.hasPrefix("0") {
            // Socket.io handshake response
            print("Socket.io handshake response received")
            DispatchQueue.main.async {
                self.isConnected = true
            }
        } else if message.hasPrefix("40") {
            // Socket.io connection established
            print("Socket.io connection established")
            DispatchQueue.main.async {
                self.isConnected = true
            }
            // Join the current chat room if we have oneгы
            if let chatId = currentChatId, chatId > 0 {
                joinSocketRoom(chatId: chatId)
            }
        } else if message.hasPrefix("42") {
            // Socket.io event message: 42["event_name",{event_data}]
            handleSocketIOEvent(message)
        }
    }
    
    private func handleSocketIOEvent(_ message: String) {
        // Extract the JSON part from socket.io message format (42["event_name",{event_data}])
        guard let startIndex = message.firstIndex(of: "[") else {
            print("Invalid socket.io event format: \(message)")
            return
        }
        
        let jsonPart = String(message[startIndex...])
        print("Extracted JSON part: \(jsonPart)")
        
        do {
            // Parse the event array: ["event_name", {event_data}]
            if let eventArray = try JSONSerialization.jsonObject(with: jsonPart.data(using: .utf8)!) as? [Any],
               eventArray.count >= 2,
               let eventName = eventArray[0] as? String {
                
                print("Received socket.io event: \(eventName)")
                
                // Handle different event types
                switch eventName {
                case "receive_message":
                    if let messageData = eventArray[1] as? [String: Any] {
                        handleNewMessage(messageData)
                    }
                case "message_deleted":
                    if let deletedData = eventArray[1] as? [String: Any],
                       let messageId = deletedData["message_id"] as? Int {
                        handleMessageDeleted(messageId: messageId)
                    }
                default:
                    print("Unhandled socket.io event: \(eventName)")
                }
            }
        } catch {
            print("Error parsing socket.io event: \(error)")
        }
    }
    
    private func handleNewMessage(_ messageData: [String: Any]) {
        guard let id = messageData["id"] as? Int,
              let chatId = messageData["chat_id"] as? Int,
              let content = messageData["content"] as? String,
              let senderId = messageData["sender_id"] as? Int,
              let timestampStr = messageData["timestamp"] as? String else {
            print("Invalid message data format")
            return
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.date(from: timestampStr) ?? Date()
        
        // Create message object using the custom initializer
        let message = Message(
            id: id,
            content: content,
            createdAt: timestamp,
            userId: senderId,
            fileUrl: messageData["file_url"] as? String,
            status: messageData["status"] as? String,
            isDeleted: messageData["is_deleted"] as? Bool ?? false,
            isRead: messageData["is_read"] as? Bool ?? false,
            fileId: messageData["file_id"] as? String,
            firstName: messageData["first_name"] as? String,
            lastName: messageData["last_name"] as? String,
            chatId: chatId
        )
        
        // Update the message list if we're in the same chat
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.currentChatId == chatId {
                self.messages.append(message)
                self.isNewMessage = true // Trigger scroll to bottom
            }
            
            // Update the last message in the chat list
            if let index = self.chats.firstIndex(where: { $0.id == chatId }) {
                var updatedChat = self.chats[index]
                let lastMessage = LastMessage(
                    content: content,
                    timestamp: timestamp,
                    senderId: senderId
                )
                updatedChat.lastMessage = lastMessage
                self.chats[index] = updatedChat
                
                // If we're not currently viewing this chat, show a notification
                if self.currentChatId != chatId {
                    self.showNotification(chatName: updatedChat.name, message: content)
                }
            }
        }
    }
    
    private func handleMessageDeleted(messageId: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove the message from the current list
            self.messages.removeAll { $0.id == messageId }
            
            // Update the last message in chats if needed
            for (index, chat) in self.chats.enumerated() {
                if chat.lastMessage.content == "Deleted message" { // Check if message was already marked as deleted
                    continue
                }
                
                // For now, just update message to say it was deleted
                // In a real app, you'd need to check if this was actually the last message
                var updatedChat = chat
                let deletedMessage = LastMessage(
                    content: "Message was deleted",
                    timestamp: Date(),
                    senderId: nil
                )
                updatedChat.lastMessage = deletedMessage
                self.chats[index] = updatedChat
            }
        }
    }
    
    func setChatWithColleague(chatId: Int) {
        self.chatWithColleague = chatId
        self.isFromColleaguePage = true
    }
    
    func resetColleagueChatState() {
        self.chatWithColleague = nil
        self.isFromColleaguePage = false
    }
    
    func saveScrollPosition(chatId: Int, position: CGFloat) {
        scrollPositions[chatId] = position
    }
    
    func getScrollPosition(chatId: Int) -> CGFloat {
        return scrollPositions[chatId] ?? 0
    }
    
    func showNotification(chatName: String, message: String) {
        self.notification = ChatNotification(chatName: chatName, message: message)
        
        // Автоматически убираем уведомление через 3 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.notification = nil
        }
        
        playNotificationSound()
    }
    
    func playNotificationSound() {
        // Здесь должен быть код для воспроизведения звука уведомления
        // В iOS можно использовать AVFoundation для воспроизведения звуков
    }
    
    func fetchChats() {
        fetchChats { _ in }
    }
    
    func fetchChats(completion: @escaping (Error?) -> Void) {
        guard let token = userStore.token else {
            let error = NSError(domain: "No token", code: -1, userInfo: nil)
            print("Error fetching chats: \(error)")
            DispatchQueue.main.async {
                self.error = "Authentication token not found"
                completion(error)
            }
            return
        }
        
        // Try using /api prefix - many APIs have this structure
        let url = URL(string: "\(apiURL)/chat/user_chats")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Set the token in Authorization header with Bearer prefix
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching chats from URL: \(url.absoluteString) with token: \(token)")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("Error fetching chats: \(error)")
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    completion(error)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Chats response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
                    print("Error fetching chats: \(error)")
                    
                    // If we get a 404 with the /api prefix, try without it
                    if httpResponse.statusCode == 404 && url.absoluteString.contains("/api/") {
                        self.tryAlternativeChatsEndpoint(token: token, completion: completion)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.error = "HTTP Error: \(httpResponse.statusCode)"
                        completion(error)
                    }
                    return
                }
            }
            
            guard let data = data else {
                let error = NSError(domain: "No data", code: -1, userInfo: nil)
                print("Error fetching chats: \(error)")
                DispatchQueue.main.async {
                    self.error = "No data received from server"
                    completion(error)
                }
                return
            }
            
            // For debugging, print the received JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received JSON: \(jsonString)")
            }
            
            self.processChatsData(data: data, completion: completion)
        }.resume()
    }
    
    private func tryAlternativeChatsEndpoint(token: String, completion: @escaping (Error?) -> Void) {
        // Try alternative endpoint structures
        let alternativeEndpoints = [
            "\(baseURL)/chats",
            "\(baseURL)/chat/user_chats",
            "\(baseURL)/api/chat/user_chats"
        ]
        
        for endpoint in alternativeEndpoints {
            guard let url = URL(string: endpoint) else { continue }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
            
            print("Trying alternative chats endpoint: \(url.absoluteString)")
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching from alternative endpoint: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data {
                    print("Successful response from alternative endpoint: \(url.absoluteString)")
                    self.processChatsData(data: data, completion: completion)
                    return
                }
            }.resume()
        }
    }
    
    private func processChatsData(data: Data, completion: @escaping (Error?) -> Void) {
        // For debugging, print the received JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Received JSON: \(jsonString)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Try to decode as ChatResponse first
            do {
                let response = try decoder.decode(ChatResponse.self, from: data)
                DispatchQueue.main.async {
                    print("Successfully decoded \(response.chats.count) chats")
                    self.chats = response.chats.sorted(by: { $0.lastMessageTime > $1.lastMessageTime })
                    self.error = nil
                    completion(nil)
                }
            } catch let chatResponseError {
                print("Failed to decode as ChatResponse: \(chatResponseError)")
                
                // If that fails, try decoding as an array of Chat
                do {
                    let fetchedChats = try decoder.decode([Chat].self, from: data)
                    DispatchQueue.main.async {
                        print("Successfully decoded \(fetchedChats.count) chats as array")
                        self.chats = fetchedChats.sorted(by: { $0.lastMessageTime > $1.lastMessageTime })
                        self.error = nil
                        completion(nil)
                    }
                } catch let arrayError {
                    print("Failed to decode as [Chat]: \(arrayError)")
                    
                    // If both fail, try to understand the response format
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Received JSON structure: \(jsonObject.keys)")
                        
                        // Check if it matches the structure from the old app but with different field names
                        if let chatsArray = jsonObject["chats"] as? [[String: Any]] {
                            print("Found 'chats' array with \(chatsArray.count) items")
                            
                            var parsedChats: [Chat] = []
                            for chatData in chatsArray {
                                if let id = chatData["id"] as? Int,
                                   let name = chatData["name"] as? String,
                                   let type = chatData["type"] as? String {
                                    
                                    // Create a basic LastMessage if not present
                                    var lastMessage: LastMessage
                                    if let lastMessageData = chatData["last_message"] as? [String: Any],
                                       let content = lastMessageData["content"] as? String {
                                        lastMessage = LastMessage(
                                            content: content,
                                            timestamp: Date(), // Use current date if not provided
                                            senderId: lastMessageData["sender_id"] as? Int
                                        )
                                    } else {
                                        lastMessage = LastMessage(
                                            content: "No messages",
                                            timestamp: Date(),
                                            senderId: nil
                                        )
                                    }
                                    
                                    let chat = Chat(
                                        id: id,
                                        name: name,
                                        type: type,
                                        lastMessage: lastMessage,
                                        isDeleted: chatData["is_deleted"] as? Bool ?? false,
                                        avatarUrl: chatData["avatar_url"] as? String,
                                        members: chatData["members"] as? [Int] ?? []
                                    )
                                    parsedChats.append(chat)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                print("Manually parsed \(parsedChats.count) chats")
                                self.chats = parsedChats.sorted(by: { $0.lastMessageTime > $1.lastMessageTime })
                                self.error = nil
                                completion(nil)
                            }
                            return
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.error = "Error decoding chats: Unknown format"
                        completion(NSError(domain: "Decoding Error", code: -1, userInfo: nil))
                    }
                }
            }
        } catch {
            print("Error decoding chats: \(error)")
            DispatchQueue.main.async {
                self.error = "Error decoding chats: \(error.localizedDescription)"
                completion(error)
            }
        }
    }
    
    // Add ChatResponse struct to match server response format
    struct ChatResponse: Codable {
        let chats: [Chat]
    }
    
    func selectChat(chatId: Int, completion: @escaping (Error?) -> Void) {
        print("Selecting chat with ID: \(chatId)")
        
        DispatchQueue.main.async {
            self.currentChatId = chatId
        }
        
        fetchMessages(chatId: chatId, completion: completion)
        joinSocketRoom(chatId: chatId)
    }
    
    func fetchMessages(chatId: Int, completion: @escaping (Error?) -> Void) {
        guard let token = userDefaults.string(forKey: "token") else {
            let error = NSError(domain: "No token", code: -1, userInfo: nil)
            print("Error fetching messages: \(error)")
            completion(error)
            return
        }
        
        // Use the correct API endpoint for chat history
        let urlString = "\(apiURL)/chat/chat_history?chat_id=\(chatId)"
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            print("Error fetching messages: \(error)")
            completion(error)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        print("Fetching messages from URL: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching messages: \(error)")
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Messages response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
                    print("Error fetching messages: \(error)")
                    DispatchQueue.main.async {
                        completion(error)
                    }
                    return
                }
            }
            
            guard let data = data else {
                print("No data received from server")
                DispatchQueue.main.async {
                    completion(NSError(domain: "No data", code: -1, userInfo: nil))
                }
                return
            }
            
            // For debugging, print the received JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received messages JSON: \(jsonString)")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Try to decode with MessageResponse wrapper first
                let response = try decoder.decode(MessageResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.messages = response.history
                    
                    // Mark messages as read
                    for message in response.history where !message.isRead {
                        if let messageId = message.id {
                            self?.markMessageAsRead(messageId: messageId)
                        }
                    }
                    
                    completion(nil)
                }
            } catch {
                print("Error decoding messages: \(error)")
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }.resume()
    }
    
    // Add MessageResponse struct to match server response format
    struct MessageResponse: Codable {
        let history: [Message]
    }
    
    func markMessageAsRead(messageId: Int) {
        guard let token = userDefaults.string(forKey: "token") else { return }
        guard let url = URL(string: "\(baseURL)/messages/\(messageId)/read") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
    
    func sendMessage(content: String, fileId: String? = nil, chatId: Int? = nil) async throws {
        let targetChatId = chatId ?? currentChatId ?? 0
        
        // Проверяем, что ID чата существует
        guard targetChatId > 0 else {
            throw ChatError.serverError("No chat ID")
        }
        
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        // Create message data
        var eventData: [String: Any] = [
            "chat_id": targetChatId,
            "content": content,
            "token": token
        ]
        
        if let fileId = fileId {
            eventData["file_id"] = fileId
        }
        
        // Use socket.io instead of HTTP request for sending messages
        if socket != nil {
            let socketMessage = formatSocketIOEvent(eventName: "send_message", data: eventData)
            print("Sending message via socket.io: \(socketMessage)")
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                socket?.send(.string(socketMessage)) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } else {
            // Fallback to HTTP if socket is not available
            guard let url = URL(string: "\(baseURL)/api/chat/send_message") else {
                throw ChatError.serverError("Invalid URL")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
            
            let body = ["content": content, "file_id": fileId as Any, "chat_id": targetChatId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode < 400 else {
                throw ChatError.serverError("Failed to send message")
            }
        }
    }
    
    func joinSocketRoom(chatId: Int) {
        guard let token = userDefaults.string(forKey: "token") else { return }
        
        // For socket.io, events need to be formatted as: 42["event_name",{event_data}]
        let eventData: [String: Any] = ["chat_id": chatId, "token": token]
        let socketMessage = formatSocketIOEvent(eventName: "join_chat", data: eventData)
        
        socket?.send(.string(socketMessage)) { error in
            if let error = error {
                print("Error joining room: \(error)")
            } else {
                print("Joined chat room: \(chatId)")
            }
        }
    }
    
    func leaveSocketRoom(chatId: Int) {
        guard let token = userDefaults.string(forKey: "token") else { return }
        
        // For socket.io, events need to be formatted as: 42["event_name",{event_data}]
        let eventData: [String: Any] = ["chat_id": chatId, "token": token]
        let socketMessage = formatSocketIOEvent(eventName: "leave_chat", data: eventData)
        
        socket?.send(.string(socketMessage)) { error in
            if let error = error {
                print("Error leaving room: \(error)")
            } else {
                print("Left chat room: \(chatId)")
            }
        }
    }
    
    private func formatSocketIOEvent(eventName: String, data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Format: 42["event_name",{json_data}]
                return "42[\"" + eventName + "\"," + jsonString + "]"
            }
        } catch {
            print("Error serializing socket event data: \(error)")
        }
        
        // Fallback to empty data if serialization fails
        return "42[\"" + eventName + "\",{}]"
    }
    
    func createPrivateChat(userId: Int, completion: @escaping (Int?, Error?) -> Void) {
        guard let token = userDefaults.string(forKey: "token") else {
            let error = NSError(domain: "No token", code: -1, userInfo: nil)
            print("Error creating chat: \(error)")
            completion(nil, error)
            return
        }
        
        guard let url = URL(string: "\(baseURL)/chats") else {
            let error = NSError(domain: "Invalid URL", code: -1, userInfo: nil)
            print("Error creating chat: \(error)")
            completion(nil, error)
            return
        }
        
        let parameters: [String: Any] = ["user_id": userId, "type": "private"]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("Error creating chat: \(error)")
            completion(nil, error)
            return
        }
        
        print("Creating chat at URL: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error creating chat: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Create chat response status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode >= 400 {
                    let error = NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
                    print("Error creating chat: \(error)")
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                    return
                }
            }
            
            guard let data = data else {
                let error = NSError(domain: "No data", code: -1, userInfo: nil)
                print("Error creating chat: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let chatId = json["chat_id"] as? Int {
                    DispatchQueue.main.async {
                        completion(chatId, nil)
                    }
                } else {
                    let error = NSError(domain: "Invalid response", code: -1, userInfo: nil)
                    print("Error creating chat: \(error)")
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            } catch {
                print("Error creating chat: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    func fetchNews() async throws {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        let url = URL(string: "\(baseURL)/api/news/get_news")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.serverError("Invalid server response")
        }
        
        let newsResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
        DispatchQueue.main.async {
            self.news = newsResponse.news
        }
    }
    
    func uploadImage(_ imageData: Data) async throws -> String {
        let url = URL(string: "\(baseURL)/api/file/upload_file/news/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(userStore.token ?? "")", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Добавляем файл
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.serverError("Ошибка при загрузке изображения")
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(FileUploadResponse.self, from: data)
        return result.fileId
    }
    
    func createPost(post: Post, fileId: String) async throws {
        let url = URL(string: "\(baseURL)/api/news/publish_news")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(userStore.token ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let postData = CreatePostRequest(
            title: post.title,
            content: post.text,
            file_id: fileId,
            type: "news",
            publish_datetime: post.date
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(postData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw ChatError.serverError("Ошибка при создании поста")
        }
        
        // Обновляем список новостей
        try await fetchNews()
    }
    
    func forwardMessages(_ messages: [Message], to targetChatId: Int) async throws {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        for message in messages {
            let forwardedContent = "#Переслано от \(userStore.fullName) - \(message.content)"
            try await sendMessage(content: forwardedContent, fileId: message.fileId ?? "", chatId: targetChatId)
        }
    }
    
    func getPrivateChatInfo(userId: Int) async throws -> Int? {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        let url = URL(string: "\(baseURL)/api/chat/get_private_chat_info/\(userId)")!
        var request = URLRequest(url: url)
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatError.serverError("Invalid server response")
        }
        
        switch httpResponse.statusCode {
        case 200:
            let chatInfo = try JSONDecoder().decode(ChatInfo.self, from: data)
            return chatInfo.id
        case 404:
            return nil
        default:
            throw ChatError.serverError("Failed to get private chat info")
        }
    }
    
    func createPrivateChat(userId: Int) async throws -> Int {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        let url = URL(string: "\(baseURL)/api/chat/create_private_chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["user_id": userId]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw ChatError.serverError("Failed to create private chat")
        }
        
        let chatInfo = try JSONDecoder().decode(ChatInfo.self, from: data)
        return chatInfo.id
    }
    
    func editMessage(messageId: Int, newContent: String) async throws {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        let eventData: [String: Any] = [
            "message_id": messageId,
            "new_content": newContent,
            "token": token
        ]
        
        let socketMessage = formatSocketIOEvent(eventName: "edit_message", data: eventData)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket?.send(.string(socketMessage)) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func deleteMessage(messageId: Int) async throws {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        let eventData: [String: Any] = [
            "message_id": messageId,
            "token": token
        ]
        
        let socketMessage = formatSocketIOEvent(eventName: "delete_message", data: eventData)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            socket?.send(.string(socketMessage)) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func uploadFile(_ fileData: Data, fileName: String, chatId: Int) async throws -> String {
        guard let token = userStore.token else {
            throw ChatError.networkError("No authorization token")
        }
        
        let url = URL(string: "\(baseURL)/api/file/upload_file/chat/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Add file data
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        bodyData.append(fileData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        // Add chat_id
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(chatId)\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChatError.serverError("Failed to upload file")
        }
        
        let result = try JSONDecoder().decode(FileUploadResponse.self, from: data)
        return result.fileId
    }
    
    func sendFile(fileId: String, chatId: Int) async throws {
        try await sendMessage(content: "Файл", fileId: fileId, chatId: chatId)
    }
}

struct Chat: Identifiable, Codable {
    let id: Int
    let name: String
    let type: String
    var lastMessage: LastMessage
    let isDeleted: Bool
    let avatarUrl: String?
    let members: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case lastMessage = "last_message"
        case isDeleted = "is_deleted"
        case avatarUrl = "avatar_url"
        case members
    }
    
    var lastMessageTime: Date {
        return lastMessage.timestamp
    }
    
    var unreadCount: Int {
        return 0 // TODO: Implement unread count
    }
    
    // Для обратной совместимости с существующим кодом
    var users: [Int] {
        return members ?? []
    }
    
    // Для совместимости с кодом UI, который ожидает lastMessage в виде строки
    var lastMessageText: String {
        return lastMessage.content
    }
}

struct LastMessage: Codable {
    let content: String
    let timestamp: Date
    let senderId: Int?
    
    enum CodingKeys: String, CodingKey {
        case content
        case timestamp
        case senderId = "sender_id"
    }
}

struct Message: Identifiable, Codable {
    let id: Int?
    let content: String
    let createdAt: Date
    let userId: Int?
    let fileUrl: String?
    let status: String?
    let isDeleted: Bool
    let isRead: Bool
    let fileId: String?
    let firstName: String?
    let lastName: String?
    let chatId: Int?
    
    var isFromCurrentUser: Bool {
        guard let currentUserId = UserDefaults.standard.integer(forKey: "userId") as Int?,
              let messageUserId = userId else {
            return false
        }
        return currentUserId == messageUserId
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt = "timestamp"
        case userId = "sender_id"
        case fileUrl = "file_url"
        case status
        case isDeleted = "is_deleted"
        case isRead = "is_read"
        case fileId = "file_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case chatId = "chat_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        chatId = try container.decodeIfPresent(Int.self, forKey: .chatId)
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        fileUrl = try container.decodeIfPresent(String.self, forKey: .fileUrl)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        
        // Handle content
        if let contentValue = try container.decodeIfPresent(String.self, forKey: .content), !contentValue.isEmpty {
            content = contentValue
        } else {
            content = "Файл"
        }
        
        // Handle timestamp
        let timestampString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        createdAt = formatter.date(from: timestampString) ?? Date()
        
        // Handle isRead as Int (1 = true) or Bool
        if let isReadInt = try container.decodeIfPresent(Int.self, forKey: .isRead) {
            isRead = isReadInt == 1
        } else {
            isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        }
    }
    
    init(id: Int?, content: String, createdAt: Date, userId: Int?, fileUrl: String?, status: String?, isDeleted: Bool, isRead: Bool, fileId: String?, firstName: String?, lastName: String?, chatId: Int?) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.userId = userId
        self.fileUrl = fileUrl
        self.status = status
        self.isDeleted = isDeleted
        self.isRead = isRead
        self.fileId = fileId
        self.firstName = firstName
        self.lastName = lastName
        self.chatId = chatId
    }
}

struct ChatNotification {
    let chatName: String
    let message: String
}

struct SocketMessage: Codable {
    let type: String
    let data: SocketMessageData?
}

struct SocketMessageData: Codable {
    let chatId: Int?
    let message: Message?
    let messageId: Int?
    
    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case message
        case messageId = "message_id"
    }
}

struct NewsResponse: Codable {
    let news: [News]
}

// Структуры для запросов
struct FileUploadResponse: Codable {
    let fileId: String
    
    enum CodingKeys: String, CodingKey {
        case fileId = "file_id"
    }
}

struct CreatePostRequest: Codable {
    let title: String
    let content: String
    let file_id: String
    let type: String
    let publish_datetime: String
}

struct ChatInfo: Codable {
    let id: Int
    let name: String
    let type: String
    let members: [Int]
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case members
    }
}

// This is the end of the file - no WebSocketDelegate extension needed with URLSessionWebSocketTask 

