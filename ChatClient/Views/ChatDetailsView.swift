import SwiftUI
import Combine

struct ChatDetailsView: View {
    let chatId: Int
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    
    @State private var newMessage = ""
    @State private var selectedMedia: [MediaAttachment] = []
    @State private var isShowingMediaPicker = false
    @State private var isShowingForwardSheet = false
    @State private var isLoadingMore = false
    @State private var showScrollToBottom = false
    @State private var currentPage = 1
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if let chat = chatStore.chats.first(where: { $0.id == chatId }) {
                // Заголовок чата
                ChatHeader(chat: chat)
                
                // Сообщения
                MessagesView(
                    chatId: chatId,
                    showScrollToBottom: $showScrollToBottom,
                    isLoadingMore: $isLoadingMore,
                    currentPage: $currentPage,
                    scrollViewProxy: $scrollViewProxy
                )
                
                // Панель пересылки сообщений
                if !chatStore.forwardingMessages.isEmpty {
                    ForwardingPanel(
                        messages: chatStore.forwardingMessages,
                        onCancel: {
                            chatStore.forwardingMessages = []
                        },
                        onForward: {
                            isShowingForwardSheet = true
                        }
                    )
                }
                
                // Панель выбора медиа
                if isShowingMediaPicker {
                    MediaPickerView(selectedMedia: $selectedMedia)
                }
                
                // Поле ввода сообщения
                MessageInputView(
                    newMessage: $newMessage,
                    selectedMedia: $selectedMedia,
                    isShowingMediaPicker: $isShowingMediaPicker,
                    onSend: sendMessage
                )
            } else {
                Spacer()
                Text("Чат не найден")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .sheet(isPresented: $isShowingForwardSheet) {
            ForwardChatSelectionView(
                onChatSelected: { selectedChatId in
                    forwardMessages(to: selectedChatId)
                }
            )
        }
        .onAppear {
            // Загружаем сообщения при открытии чата
            chatStore.selectChat(chatId: chatId) { _ in }
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Если есть медиа для отправки
        if !selectedMedia.isEmpty {
            for (index, media) in selectedMedia.enumerated() {
                // Обновляем состояние загрузки
                selectedMedia[index].uploadState = .uploading(progress: 0.0)
                
                Task {
                    do {
                        // Загружаем файл на сервер
                        let fileId = try await chatStore.uploadFile(
                            media.data,
                            fileName: media.fileName,
                            chatId: chatId
                        )
                        
                        // Обновляем состояние загрузки
                        DispatchQueue.main.async {
                            if let idx = self.selectedMedia.firstIndex(where: { $0.id == media.id }) {
                                self.selectedMedia[idx].uploadState = .success(fileId: fileId)
                            }
                        }
                        
                        // Отправляем сообщение с файлом
                        try await chatStore.sendMessage(
                            content: trimmedMessage.isEmpty ? "Файл" : trimmedMessage,
                            fileId: fileId,
                            chatId: chatId
                        )
                        
                        // Очищаем поле ввода и медиа после успешной отправки
                        DispatchQueue.main.async {
                            if index == selectedMedia.count - 1 {
                                newMessage = ""
                                selectedMedia = []
                                isShowingMediaPicker = false
                            }
                        }
                    } catch {
                        print("Error uploading file: \(error)")
                        
                        // Обновляем состояние загрузки при ошибке
                        DispatchQueue.main.async {
                            if let idx = self.selectedMedia.firstIndex(where: { $0.id == media.id }) {
                                self.selectedMedia[idx].uploadState = .failed(error: error.localizedDescription)
                            }
                        }
                    }
                }
            }
        } else if !trimmedMessage.isEmpty {
            // Отправляем обычное текстовое сообщение
            Task {
                do {
                    try await chatStore.sendMessage(content: trimmedMessage, chatId: chatId)
                    newMessage = ""
                } catch {
                    print("Error sending message: \(error)")
                }
            }
        }
    }
    
    private func forwardMessages(to targetChatId: Int) {
        Task {
            do {
                try await chatStore.forwardMessages(chatStore.forwardingMessages, to: targetChatId)
                
                DispatchQueue.main.async {
                    chatStore.forwardingMessages = []
                }
            } catch {
                print("Error forwarding messages: \(error)")
            }
        }
    }
}

struct ChatHeader: View {
    let chat: Chat
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var showChatInfo = false
    
    var body: some View {
        HStack {
            Button(action: {
                chatStore.currentChatId = nil
            }) {
                Image(systemName: "arrow.left")
                    .font(.title3)
            }
            .padding(.trailing, 8)
            
            // Аватар чата
            if chat.type == "private" {
                if let userId = chat.users.first(where: { $0 != userStore.user?.id }),
                   let user = userStore.users.first(where: { $0.id == userId }) {
                    Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
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
            
            // Название чата
            VStack(alignment: .leading, spacing: 2) {
                Text(chatName)
                    .font(.headline)
                
                if chat.type == "private" {
                    Text("В сети")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Text("\(chat.users.count) участников")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Кнопка информации о чате
            Button(action: {
                showChatInfo = true
            }) {
                Image(systemName: "info.circle")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .sheet(isPresented: $showChatInfo) {
            ChatInfoView(chat: chat)
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
}

struct MessagesView: View {
    let chatId: Int
    @Binding var showScrollToBottom: Bool
    @Binding var isLoadingMore: Bool
    @Binding var currentPage: Int
    @Binding var scrollViewProxy: ScrollViewProxy?
    
    @EnvironmentObject private var chatStore: ChatStore
    @State private var lastMessageId: Int?
    @State private var scrollPosition: CGFloat = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Кнопка загрузки предыдущих сообщений
                    if chatStore.messages.count >= 20 {
                        Button(action: loadMoreMessages) {
                            if isLoadingMore {
                                ProgressView()
                                    .padding()
                            } else {
                                Text("Загрузить предыдущие сообщения")
                                    .padding()
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Группируем сообщения по дате
                    ForEach(groupedMessages.keys.sorted(by: >), id: \.self) { date in
                        if let messagesForDate = groupedMessages[date] {
                            VStack(spacing: 0) {
                                // Заголовок с датой
                                Text(formatDate(date))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 8)
                                
                                // Сообщения за эту дату
                                ForEach(messagesForDate) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                    }
                    
                    // Невидимый элемент для прокрутки вниз
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical)
            }
            .onReceive(chatStore.$messages) { newMessages in
                // Если появилось новое сообщение, прокручиваем вниз
                if let lastMessage = newMessages.last, lastMessage.id != lastMessageId {
                    lastMessageId = lastMessage.id
                    
                    if chatStore.isNewMessage {
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                        chatStore.isNewMessage = false
                    }
                }
            }
            .onReceive(chatStore.$isNewMessage) { isNew in
                if isNew {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                    chatStore.isNewMessage = false
                }
            }
            .onAppear {
                scrollViewProxy = proxy
                
                // Прокручиваем к последнему сообщению при появлении
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var groupedMessages: [Date: [Message]] {
        Dictionary(grouping: chatStore.messages) { message in
            // Группируем по дате (без времени)
            Calendar.current.startOfDay(for: message.createdAt)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Сегодня"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Вчера"
        } else {
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func loadMoreMessages() {
        isLoadingMore = true
        currentPage += 1
        
        // Загружаем предыдущие сообщения
        // Примечание: здесь нужно реализовать логику загрузки с пагинацией на сервере
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoadingMore = false
        }
    }
}

struct MessageInputView: View {
    @Binding var newMessage: String
    @Binding var selectedMedia: [MediaAttachment]
    @Binding var isShowingMediaPicker: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .bottom) {
                // Кнопка прикрепления файла
                Button(action: {
                    isShowingMediaPicker.toggle()
                }) {
                    Image(systemName: isShowingMediaPicker ? "xmark.circle.fill" : "paperclip")
                        .font(.title3)
                        .foregroundColor(isShowingMediaPicker ? .red : .gray)
                }
                .padding(.horizontal, 8)
                
                // Текстовое поле
                ZStack(alignment: .leading) {
                    if newMessage.isEmpty && selectedMedia.isEmpty {
                        Text("Напишите сообщение...")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                            .padding(.top, 8)
                    }
                    
                    TextEditor(text: $newMessage)
                        .padding(4)
                        .frame(minHeight: 36, maxHeight: 120)
                        .background(Color(.systemGray6))
                        .cornerRadius(18)
                }
                
                // Кнопка отправки
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedMedia.isEmpty)
            }
            .padding()
        }
    }
}

struct ForwardingPanel: View {
    let messages: [Message]
    let onCancel: () -> Void
    let onForward: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Пересылка: \(messages.count) сообщ.")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Button(action: onForward) {
                    Text("Выбрать чат")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct ForwardChatSelectionView: View {
    @EnvironmentObject private var chatStore: ChatStore
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.presentationMode) var presentationMode
    
    let onChatSelected: (Int) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(chatStore.chats) { chat in
                    Button(action: {
                        onChatSelected(chat.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            // Аватар чата
                            if chat.type == "private" {
                                if let userId = chat.users.first(where: { $0 != userStore.user?.id }),
                                   let user = userStore.users.first(where: { $0.id == userId }) {
                                    Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue)
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
                            
                            // Название чата
                            Text(getChatName(chat))
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("Выберите чат")
            .navigationBarItems(trailing: Button("Отмена") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func getChatName(_ chat: Chat) -> String {
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
}

struct ChatInfoView: View {
    let chat: Chat
    @EnvironmentObject private var userStore: UserStore
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Информация")) {
                    HStack {
                        Text("Название")
                        Spacer()
                        Text(chat.name)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Тип")
                        Spacer()
                        Text(chat.type == "private" ? "Личный" : "Групповой")
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("Участники")) {
                    ForEach(chat.users, id: \.self) { userId in
                        if let user = userStore.users.first(where: { $0.id == userId }) {
                            HStack {
                                Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                
                                Text("\(user.firstName) \(user.lastName)")
                                
                                Spacer()
                                
                                if userId == userStore.user?.id {
                                    Text("Вы")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("О чате")
            .listStyle(InsetGroupedListStyle())
        }
    }
}

