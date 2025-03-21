import SwiftUI

struct ChatInterfaceView: View {
    @Binding var isChatOpen: Bool
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var isCreatingChat = false
    @State private var searchText = ""
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let error = chatStore.error {
                    VStack(spacing: 10) {
                        Text("Ошибка подключения")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            chatStore.fetchChats()
                        }) {
                            Text("Повторить")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatStore.isLoading {
                    ProgressView("Загрузка чатов...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatStore.chats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("У вас пока нет чатов")
                            .font(.headline)
                            .foregroundColor(.gray)

                        Button(action: {
                            isCreatingChat = true
                        }) {
                            Text("Начать новый чат")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if let chatId = chatStore.chatWithColleague, chatStore.isFromColleaguePage {
                        // Открываем чат с коллегой
                        ChatDetailsView(chatId: chatId)
                            .onAppear {
                                chatStore.resetColleagueChatState()
                            }
                    } else if let currentChatId = chatStore.currentChatId {
                        // Открываем выбранный чат
                        ChatDetailsView(chatId: currentChatId)
                            .offset(x: offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        self.offset = value.translation.width
                                    }
                                    .onEnded { value in
                                        if value.translation.width > geometry.size.width / 3 {
                                            self.offset = geometry.size.width
                                            chatStore.currentChatId = nil
                                        } else {
                                            self.offset = 0
                                        }
                                    }
                            )
                    } else {
                        // Показываем список чатов
                        ChatListView(
                            isCreatingChat: $isCreatingChat,
                            searchText: $searchText
                        )
                    }
                }
            }
            .onAppear {
                chatStore.fetchChats()
                chatStore.setupWebSocket()
                isChatOpen = chatStore.currentChatId != nil
            }
            .onChange(of: chatStore.currentChatId) { newValue in
                isChatOpen = newValue != nil
                if newValue == nil {
                    self.offset = 0
                }
            }
            .sheet(isPresented: $isCreatingChat) {
                CreateChatView()
            }
            .overlay(
                // Показываем уведомление о новом сообщении
                Group {
                    if let notification = chatStore.notification {
                        NotificationBanner(notification: notification)
                            .transition(.move(edge: .top))
                            .animation(.spring(), value: chatStore.notification != nil)
                    }
                }
            )
        }
    }
}


struct ChatListView: View {
    @Binding var isCreatingChat: Bool
    @Binding var searchText: String
    @EnvironmentObject private var chatStore: ChatStore
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chatStore.chats
        } else {
            return chatStore.chats.filter { chat in
                chat.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Чаты")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    isCreatingChat = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(15)
            }
            .padding(.top,60)
            
            // Поле поиска
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Поиск", text: $searchText)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if filteredChats.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    Text("Чаты не найдены")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredChats) { chat in
                        ChatListItem(chat: chat)
                            .onTapGesture {
                                selectChat(chat.id)
                            }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func selectChat(_ chatId: Int) {
        chatStore.selectChat(chatId: chatId) { error in
            if let error = error {
                print("Error selecting chat: \(error)")
            }
        }
    }
}

struct ChatListItem: View {
    let chat: Chat
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    
    var body: some View {
        HStack {
            // Аватар
            if chat.type == "private" {
                if let userId = chat.users.first(where: { $0 != userStore.user?.id }) {
                    if let user = userStore.users.first(where: { $0.id == userId }) {
                        Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
                    } else {
                        Text("??")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                } else {
                    Text("??")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
            } else {
                Text(String(chat.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            
            // Информация о чате
            VStack(alignment: .leading, spacing: 4) {
                Text(chatName)
                    .font(.headline)
                
                HStack {
                    // Если это пересланное сообщение, показываем специальный текст
                    if chat.lastMessageText.hasPrefix("#Переслано от") {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Пересланное сообщение")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    // Если это файл, показываем иконку файла
                    else if chat.lastMessageText == "Файл" {
                        Image(systemName: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Файл")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text(chat.lastMessageText)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Время и индикатор непрочитанных
            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
        .background(chatStore.currentChatId == chat.id ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    private var chatName: String {
        if chat.type == "private" {
            if let userId = chat.users.first(where: { $0 != userStore.user?.id }),
               let user = userStore.users.first(where: { $0.id == userId }) {
                return "\(user.firstName) \(user.lastName)"
            } else {
                return chat.name
            }
        } else {
            return chat.name
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        
        // Сегодня показываем только время
        if Calendar.current.isDateInToday(chat.lastMessageTime) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: chat.lastMessageTime)
        } else if Calendar.current.isDateInYesterday(chat.lastMessageTime) {
            return "Вчера"
        } else {
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: chat.lastMessageTime)
        }
    }
}

struct NotificationBanner: View {
    let notification: ChatNotification
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(notification.chatName)
                        .font(.headline)
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ChatInterfaceView_Previews: PreviewProvider {
    static var previews: some View {
        // Используем .constant(false) для передачи состояния isChatOpen
        ChatInterfaceView(isChatOpen: .constant(false))
            .environmentObject(UserStore())
            .environmentObject(ChatStore(userStore: UserStore()))
    }
}

