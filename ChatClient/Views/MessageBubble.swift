import SwiftUI

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var showActionSheet = false
    @State private var isEditing = false
    @State private var editedContent = ""
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // Имя отправителя (только для сообщений от других пользователей)
            if !isFromCurrentUser {
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Содержимое сообщения
            HStack {
                if isFromCurrentUser {
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Контент сообщения в зависимости от типа
                    switch message.messageType {
                    case .text:
                        if isEditing {
                            TextField("Редактировать сообщение", text: $editedContent)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal, 4)
                            
                            HStack {
                                Button("Отмена") {
                                    isEditing = false
                                }
                                .foregroundColor(.red)
                                
                                Spacer()
                                
                                Button("Сохранить") {
                                    saveEditedMessage()
                                }
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                        } else {
                            Text(message.content)
                                .padding()
                                .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                                .foregroundColor(isFromCurrentUser ? .white : .black)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        
                    case .image:
                        VStack(alignment: .leading, spacing: 4) {
                            if let fileUrl = message.fileUrl, let url = URL(string: fileUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 200, height: 200)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: 200, maxHeight: 200)
                                            .cornerRadius(12)
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .padding()
                                .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                                .foregroundColor(isFromCurrentUser ? .white : .black)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                        
                    case .file:
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc")
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(message.fileName ?? "Файл")
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    
                                    if let fileUrl = message.fileUrl {
                                        Button(action: {
                                            // Открыть файл
                                            if let url = URL(string: fileUrl) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            Text("Скачать")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                            .foregroundColor(isFromCurrentUser ? .white : .black)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        
                    case .voice:
                        VoiceMessageView(message: message, isFromCurrentUser: isFromCurrentUser)
                            .padding()
                            .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                            .foregroundColor(isFromCurrentUser ? .white : .black)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                    case .forwarded:
                        VStack(alignment: .leading, spacing: 4) {
                            // Извлекаем оригинальное сообщение из пересланного
                            let forwardedPrefix = "#Переслано от "
                            let startIndex = message.content.range(of: forwardedPrefix)?.upperBound ?? message.content.startIndex
                            let dashIndex = message.content.range(of: " - ", range: startIndex..<message.content.endIndex)?.upperBound ?? message.content.startIndex
                            let originalContent = String(message.content[dashIndex...])
                            
                            Text(String(message.content[startIndex..<dashIndex]))
                                .font(.caption)
                                .foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : .gray)
                            
                            Text(originalContent)
                                .padding(.top, 2)
                        }
                        .padding()
                        .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(isFromCurrentUser ? .white : .black)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
                .onTapGesture {
                    if !isEditing {
                        showActionSheet = true
                    }
                }
                
                if !isFromCurrentUser {
                    Spacer()
                }
            }
            
            // Время отправки
            Text(message.formattedTime)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("Действия с сообщением"),
                buttons: [
                    .default(Text("Ответить")) {
                        // Реализация ответа на сообщение
                    },
                    .default(Text("Переслать")) {
                        chatStore.forwardingMessages = [message]
                    },
                    .default(Text("Копировать")) {
                        UIPasteboard.general.string = message.content
                    },
                    .default(Text("Редактировать")) {
                        if isFromCurrentUser && message.messageType == .text {
                            editedContent = message.content
                            isEditing = true
                        }
                    },
                    .destructive(Text("Удалить")) {
                        deleteMessage()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private var isFromCurrentUser: Bool {
        return message.userId == userStore.user?.id
    }
    
    private var senderName: String {
        if let user = userStore.users.first(where: { $0.id == message.userId }) {
            return "\(user.firstName) \(user.lastName)"
        } else if let firstName = message.firstName, let lastName = message.lastName {
            return "\(firstName) \(lastName)"
        } else {
            return "Неизвестный пользователь"
        }
    }
    
    private func saveEditedMessage() {
        guard !editedContent.isEmpty, editedContent != message.content, let messageId = message.id else {
            isEditing = false
            return
        }
        
        Task {
            do {
                try await chatStore.editMessage(messageId: messageId, newContent: editedContent)
                isEditing = false
            } catch {
                print("Error editing message: \(error)")
            }
        }
    }
    
    private func deleteMessage() {
        guard let messageId = message.id else { return }
        
        Task {
            do {
                try await chatStore.deleteMessage(messageId: messageId)
            } catch {
                print("Error deleting message: \(error)")
            }
        }
    }
}

