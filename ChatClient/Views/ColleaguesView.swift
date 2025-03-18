import SwiftUI

struct ColleaguesView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var searchText = ""
    @State private var selectedPosition: String = "Все"
    
    var positions: [String] {
        let allPositions = userStore.users.map { $0.position }
        return ["Все"] + Array(Set(allPositions)).sorted()
    }
    
    var filteredUsers: [User] {
        var users = userStore.users.filter { $0.id != userStore.user?.id }
        
        if selectedPosition != "Все" {
            users = users.filter { $0.position == selectedPosition }
        }
        
        if !searchText.isEmpty {
            users = users.filter { user in
                user.firstName.localizedCaseInsensitiveContains(searchText) ||
                user.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return users
    }
    
    var body: some View {
        VStack {
            // Заголовок и поиск
            VStack(spacing: 16) {
                Text("Коллеги")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Фильтр по должностям
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(positions, id: \.self) { position in
                            Button(action: {
                                selectedPosition = position
                            }) {
                                Text(position)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedPosition == position ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(selectedPosition == position ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                TextField("Поиск по имени", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Список коллег
            if userStore.users.isEmpty {
                Spacer()
                ProgressView("Загрузка пользователей...")
                Spacer()
            } else if filteredUsers.isEmpty {
                Spacer()
                Text("Пользователи не найдены")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredUsers) { user in
                            ColleagueCard(user: user)
                                .onTapGesture {
                                    startChatWithUser(user)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if userStore.users.isEmpty {
                userStore.fetchUsers()
            }
        }
    }
    
    private func startChatWithUser(_ user: User) {
        chatStore.createPrivateChat(userId: user.id) { chatId, error in
            if let chatId = chatId {
                chatStore.setChatWithColleague(chatId: chatId)
                
                // Уведомление о смене вкладки на чаты
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 1]
                )
            }
        }
    }
}

struct ColleagueCard: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 12) {
            // Аватар
            Text(String(user.firstName.prefix(1)) + String(user.lastName.prefix(1)))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(Color.blue)
                .clipShape(Circle())
            
            // Имя и должность
            VStack(spacing: 4) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(user.position)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Кнопки действий
            HStack(spacing: 20) {
                Button(action: {
                    // Позвонить
                }) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                        .frame(width: 30, height: 30)
                }
                
                Button(action: {
                    // Написать
                }) {
                    Image(systemName: "message.fill")
                        .foregroundColor(.blue)
                        .frame(width: 30, height: 30)
                }
                
                Button(action: {
                    // Email
                }) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.orange)
                        .frame(width: 30, height: 30)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ColleaguesView_Previews: PreviewProvider {
    static var previews: some View {
        ColleaguesView()
            .environmentObject(UserStore())
            .environmentObject(ChatStore(userStore: UserStore()))
    }
} 
