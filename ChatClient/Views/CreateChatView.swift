import SwiftUI

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

