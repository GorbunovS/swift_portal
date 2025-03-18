import SwiftUI

struct ChatInterfaceView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var isCreatingChat = false
    
    var body: some View {
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
                // ...остальной код для отображения списка чатов
                if let chatId = chatStore.chatWithColleague, chatStore.isFromColleaguePage {
                    // Открываем чат с коллегой
                    LegacyChatDetailsView(chatId: chatId)
                        .onAppear {
                            chatStore.resetColleagueChatState()
                        }
                } else if let currentChatId = chatStore.currentChatId {
                    // Открываем выбранный чат
                    LegacyChatDetailsView(chatId: currentChatId)
                } else {
                    // Показываем список чатов
                    ChatListView(isCreatingChat: $isCreatingChat)
                }
            }
        }
        .onAppear {
            chatStore.fetchChats()
        }
        .sheet(isPresented: $isCreatingChat) {
            CreateChatView()
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
                            .frame(width: 40, height: 40)
                            .background(Color.blue)
                            .clipShape(Circle())
                    } else {
                        Text("??")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                } else {
                    Text("??")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
            } else {
                Text(String(chat.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            
            // Информация о чате
            VStack(alignment: .leading, spacing: 4) {
                Text(chatName)
                    .font(.headline)
                
                Text(chat.lastMessageText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
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

struct ChatView: View {
    let chat: Chat
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var newMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Шапка чата
            HStack {
                Text(chatName)
                    .font(.headline)
                
                Spacer()
                
                // Дополнительные действия с чатом
                Menu {
                    Button(action: {
                        // Информация о чате
                    }) {
                        Label("Информация", systemImage: "info.circle")
                    }
                    
                    Button(action: {
                        // Поиск в чате
                    }) {
                        Label("Поиск", systemImage: "magnifyingglass")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        // Выйти из чата
                    }) {
                        Label("Выйти из чата", systemImage: "arrow.right.square")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Список сообщений
            ScrollView {
                if isLoading {
                    ProgressView("Загрузка сообщений...")
                        .padding()
                } else if chatStore.messages.isEmpty {
                    Text("Нет сообщений")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(chatStore.messages) { message in
                            MessageBubble(message: message)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Поле ввода сообщения
            HStack {
                // Кнопка прикрепления файла
                Button(action: {
                    // Прикрепить файл
                }) {
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
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
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
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else { return }
        
        Task {
            do {
                try await chatStore.sendMessage(content: trimmedMessage)
                newMessage = ""
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject private var userStore: UserStore
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                
                // Сообщение от текущего пользователя
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 60)
            } else {
                // Сообщение от другого пользователя
                VStack(alignment: .leading, spacing: 4) {
                    Text(senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(message.content)
                        .padding()
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 60)
                
                Spacer()
            }
        }
    }
    
    private var isFromCurrentUser: Bool {
        return message.userId == userStore.user?.id
    }
    
    private var senderName: String {
        if let user = userStore.users.first(where: { $0.id == message.userId }) {
            return "\(user.firstName) \(user.lastName)"
        } else {
            return "Неизвестный пользователь"
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.createdAt)
    }
}

struct CreateChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var chatName = ""
    @State private var searchText = ""
    @State private var selectedUsers: [User] = []
    @State private var isPrivateChat = true
    @State private var isLoading = false
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return userStore.users.filter { $0.id != userStore.user?.id }
        } else {
            return userStore.users.filter { user in
                user.id != userStore.user?.id &&
                (user.firstName.localizedCaseInsensitiveContains(searchText) ||
                 user.lastName.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Тип чата
                Picker("Тип чата", selection: $isPrivateChat) {
                    Text("Личный").tag(true)
                    Text("Групповой").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Имя группового чата
                if !isPrivateChat {
                    TextField("Название группы", text: $chatName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Поиск пользователей
                TextField("Поиск пользователей", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                // Выбранные пользователи
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedUsers) { user in
                                HStack {
                                    Text("\(user.firstName) \(user.lastName)")
                                    
                                    Button(action: {
                                        selectedUsers.removeAll { $0.id == user.id }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Список пользователей
                List {
                    ForEach(filteredUsers) { user in
                        Button(action: {
                            toggleUserSelection(user)
                        }) {
                            HStack {
                                Text("\(user.firstName) \(user.lastName)")
                                
                                Spacer()
                                
                                if selectedUsers.contains(where: { $0.id == user.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Кнопка создания чата
                Button(action: createChat) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text("Создать чат")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .disabled(isLoading || selectedUsers.isEmpty || (!isPrivateChat && chatName.isEmpty))
            }
            .navigationTitle("Новый чат")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func toggleUserSelection(_ user: User) {
        if isPrivateChat {
            // Для личного чата можно выбрать только одного пользователя
            selectedUsers = [user]
        } else {
            // Для группового чата можно выбрать нескольких пользователей
            if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
                selectedUsers.remove(at: index)
            } else {
                selectedUsers.append(user)
            }
        }
    }
    
    private func createChat() {
        isLoading = true
        
        if isPrivateChat, let user = selectedUsers.first {
            chatStore.createPrivateChat(userId: user.id) { chatId, error in
                isLoading = false
                
                if let chatId = chatId {
                    presentationMode.wrappedValue.dismiss()
                    
                    // Выбрать созданный чат
                    DispatchQueue.main.async {
                        chatStore.selectChat(chatId: chatId) { _ in }
                    }
                }
            }
        } else {
            // Здесь должен быть код для создания группового чата
            // В реальном приложении это будет отдельный запрос к API
            
            // После создания группового чата
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ChatListView: View {
    @Binding var isCreatingChat: Bool
    @EnvironmentObject private var chatStore: ChatStore
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Чаты")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isCreatingChat = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            List {
                ForEach(chatStore.chats) { chat in
                    ChatListItem(chat: chat)
                        .onTapGesture {
                            selectChat(chat.id)
                        }
                }
            }
            .listStyle(PlainListStyle())
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

struct LegacyChatDetailsView: View {
    let chatId: Int
    @EnvironmentObject private var chatStore: ChatStore
    @State private var newMessage = ""
    
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
                                MessageBubble(message: message)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                // Поле ввода сообщения
                HStack {
                    // Кнопка прикрепления файла
                    Button(action: {
                        // Прикрепить файл
                    }) {
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
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            } else {
                Spacer()
                Text("Чат не найден")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else { return }
        
        Task {
            do {
                try await chatStore.sendMessage(content: trimmedMessage)
                newMessage = ""
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}

struct ChatInterfaceView_Previews: PreviewProvider {
    static var previews: some View {
        ChatInterfaceView()
            .environmentObject(UserStore())
            .environmentObject(ChatStore(userStore: UserStore()))
    }
} 