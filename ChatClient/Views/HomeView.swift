import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var isLoadingPosts = false
    @State private var showCreatePost = false
    @State private var avatarImage: UIImage? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Приветствие и аватар
                HStack {
                    // Аватар пользователя
                    Group {
                        if let avatarImage = avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(colorScheme == .dark ? Theme.DarkTheme.secondaryTextColor : Theme.LightTheme.secondaryTextColor, lineWidth: 2))
                        } else {
                            // Заглушка, если аватар не загружен
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(colorScheme == .dark ? Theme.DarkTheme.secondaryTextColor : Theme.LightTheme.secondaryTextColor)
                        }
                    }
                    .padding(.trailing, 15)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Добро пожаловать,")
                            .font(.custom("Racama-U", size: 18))
                            .foregroundColor(colorScheme == .dark ? Theme.DarkTheme.secondTextColor : Theme.LightTheme.secondTextColor)
                        
                        Text(userStore.fullName)
                            .font(.custom("Racama-U", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? Theme.DarkTheme.textColor : Theme.LightTheme.textColor)
                    }
                    
                    Spacer()
                    

                }
                .padding(.horizontal)
                .padding(.top)
                
                // Статистика
                HStack(spacing: 16) {
                    StatisticCard(
                        icon: "message.fill",
                        title: "Сообщения",
                        count: "15",
                        color: .blue
                    )
                    
                    StatisticCard(
                        icon: "checkmark.circle.fill",
                        title: "Задачи",
                        count: "8",
                        color: .green
                    )
                    
                    StatisticCard(
                        icon: "folder.fill",
                        title: "Файлы",
                        count: "32",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Разделитель
                Divider()
                    .padding(.vertical)
                
                // Заголовок новостей
                HStack {
                    Text("Новости компании")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showCreatePost = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Новости
                if isLoadingPosts {
                    ProgressView()
                        .padding()
                } else if chatStore.news.isEmpty {
                    Text("Нет доступных новостей")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(chatStore.news) { news in
                        NewsCard(news: news)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
        .refreshable {
            await refreshData()
        }
        .background(colorScheme == .dark ? Theme.DarkTheme.backgroundColor : Theme.LightTheme.backgroundColor)
        .onAppear {
            Task {
                await loadNews()
            }
            // Если есть ID аватара, загружаем изображение
            if !userStore.avatarId.isEmpty {
                loadAvatar()
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
        }
    }
    
    private func refreshData() async {
        await userStore.refreshData()
        await loadNews()
    }
    
    private func loadNews() async {
        isLoadingPosts = true
        
        do {
            try await chatStore.fetchNews()
            isLoadingPosts = false
        } catch {
            print("Error loading news: \(error)")
            isLoadingPosts = false
        }
    }
    
    private func loadAvatar() {
        userStore.getImage(fileId: userStore.avatarId) { data in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.avatarImage = image
                }
            }
        }
    }
}

struct StatisticCard: View {
    let icon: String
    let title: String
    let count: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(count)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct NewsCard: View {
    let news: News
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(news.title)
                .font(.title3)
                .fontWeight(.bold)
            
            if let imageUrl = news.fileUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 200)
                .clipped()
            }
            
            Text(news.content)
                .font(.body)
                .lineLimit(3)
            
            Text(news.createdAt ?? "Дата неизвестна")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserStore())
            .environmentObject(ChatStore(userStore: UserStore()))
    }
} 
