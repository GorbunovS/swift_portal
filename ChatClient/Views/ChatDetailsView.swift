import SwiftUI
import PhotosUI

struct ChatDetailsView: View {
    let chatId: Int
    @EnvironmentObject private var chatStore: ChatStore
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var showFilePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 0) {
            if let chat = chatStore.chats.first(where: { $0.id == chatId }) {
                // Заголовок чата
                HStack {
                    Button(action: {
                        chatStore.currentChatId = nil
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title3)
                    }
                    .padding(.trailing, 8)
                    
                    Text(chat.name)
                        .font(.headline)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Сообщения
                if chatStore.messages.isEmpty {
                    Spacer()
                    Text("Нет сообщений")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatStore.messages) { message in
                                MessageView(message: message, chatId: chatId, chatStore: chatStore)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                // Поле ввода сообщения
                HStack {
                    // Кнопка прикрепления файла
                    PhotosPicker(selection: $selectedItem,
                               matching: .any(of: [.images, .videos])) {
                        Image(systemName: "paperclip")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 8)
                    
                    // Текстовое поле
                    TextField("Напишите сообщение...", text: $newMessage)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    
                    // Кнопка отправки
                    Button(action: sendMessage) {
                        if isLoading {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 8)
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding()
            } else {
                Spacer()
                Text("Чат не найден")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    do {
                        let fileName = newItem?.itemIdentifier ?? "file"
                        let fileId = try await chatStore.uploadFile(data, fileName: fileName, chatId: chatId)
                        try await chatStore.sendFile(fileId: fileId, chatId: chatId)
                    } catch {
                        print("Error sending file: \(error)")
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else { return }
        
        isLoading = true
        
        Task {
            do {
                try await chatStore.sendMessage(content: trimmedMessage)
                newMessage = ""
            } catch {
                print("Error sending message: \(error)")
            }
            
            isLoading = false
        }
    }
} 