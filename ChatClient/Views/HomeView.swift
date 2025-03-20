import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var isLoadingPosts = false
    @State private var showCreatePost = false
    @State private var showMiniApps = false
    @State private var avatarImage: UIImage? = nil
    @State private var selectedTab = 0 // 0 - Новости, 1 - Статьи
    @State private var selectedNews: News?
    @State private var showEditProfile = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMiniApps: [MiniApp] = []
    
    private var theme: ThemeProtocol.Type {
        colorScheme == .dark ? Theme.DarkTheme.self : Theme.LightTheme.self
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Профиль пользователя
                    HStack(spacing: 16) {
                        // Аватар пользователя
                       
                            Button(action: {
                                withAnimation {
                                    showEditProfile.toggle()
                                }
                            }) {
                                if userStore.avatarId.isEmpty {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(theme.buttonsBackgroundColor)
                                } else {
                                    ProfileImage(avatarId: userStore.avatarId)
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())
                                }
                            }
                            .sheet(isPresented: $showEditProfile) {
                                EditProfileView()
                            }

                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userStore.fullName)
                                .font(FontTheme.title)
                                .foregroundColor(theme.textColor)
                            
                            Text("Администратор")
                                .font(FontTheme.caption)
                                .foregroundColor(theme.secondTextColor)
                        }
                        
                        Spacer()
                        
                        
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        // Статистика (БИО профиля)
                        HStack(spacing: 16) {
                          
                            
                            StatisticCard(
                                icon: "envelope",
                                title: "Почта",
                                count: "100+",
                                color: .blue,
                                theme: theme
                            )
                            
                            StatisticCard(
                                icon: "briefcase",
                                title: "Задачи",
                                count: "5",
                                color: .orange,
                                theme: theme
                            )
                            
                            StatisticCard(
                                
                                icon: "calendar",
                                title: "Календарь",
                                count: "5",
                                color: .green,
                                theme: theme
                            )
                            StatisticCard(
                                icon: "plus.circle.fill",
                                title: "Ещё",
                                count: " ",
                                color: .blue,
                                theme: theme
                            )
              
                            // Отображаем выбранные мини-приложения
//                            ForEach(selectedMiniApps) { app in
//                                MiniAppCard(app: app, isSelected: true) {
//                                    // Убираем приложение из списка выбранных
//                                    if let index = selectedMiniApps.firstIndex(where: { $0.id == app.id }) {
//                                        selectedMiniApps.remove(at: index)
//                                    }
//                                }
//
//                            }


                        }
                        .padding(.horizontal)
                        .padding(.vertical)
                    }
                 
                    
                   
                    
                  
                    
                    // Вкладки новостей и статей
                    HStack {
                        HStack {
                            Button(action: { selectedTab = 0 }) {
                                Text("Новости")
                                
                                    .font(FontTheme.header)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedTab == 0 ? theme.buttonsBackgroundColor : Color.clear)
                                    .foregroundColor(selectedTab == 0 ? Color.white : theme.secondTextColor)
                                    .cornerRadius(16)
                            }
                            
                            Button(action: { selectedTab = 1 }) {
                                Text("Статьи")
                                    .font(FontTheme.header)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedTab == 1 ? theme.buttonsBackgroundColor : Color.clear)
                                    .foregroundColor(selectedTab == 1 ? Color.white : theme.secondTextColor)
                                    .cornerRadius(16)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        Button(action: { showCreatePost = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.buttonsBackgroundColor)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Контент (Новости или Статьи)
                    TabView(selection: $selectedTab) {
                        // Экран новостей
                        ScrollView {
                            VStack(spacing: 20) {
                                if isLoadingPosts {
                                    ProgressView()
                                        .padding()
                                } else if chatStore.news.isEmpty {
                                    Text("Нет доступного контента")
                                        .foregroundColor(theme.secondTextColor)
                                        .padding()
                                } else {
                                    ForEach(chatStore.news) { news in
                                        NewsCard(news: news, theme: theme)
                                            .padding(.horizontal)
                                            .onTapGesture { selectedNews = news }
                                    }
                                }
                            }
                            .padding(.top) // Добавляем отступ сверху
                        }
                        .tag(0)
                        
                        // Экран статей
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(sampleArticles) { article in
                                    ArticleCard(article: article, theme: theme)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top) // Добавляем отступ сверху
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never)) // Отключаем индикатор страниц
                    .frame(height: UIScreen.main.bounds.height * 0.6) // Настраиваем высоту
                    
                }
            }
            .padding(.vertical, 60)
            .background(theme.backgroundColor)
            .edgesIgnoringSafeArea(.bottom)
            
            .onAppear {
                userStore.fetchData()
                Task { await loadNews() }
                if !userStore.avatarId.isEmpty {
                    loadAvatar()
                }
            }
            .refreshable {
               
            }
            .sheet(isPresented: $showMiniApps) {
                MiniAppsSelectionView(selectedMiniApps: $selectedMiniApps)
            }
            
            .sheet(isPresented: $showCreatePost) {
                CreatePostView()
            }
        
            
            .sheet(item: $selectedNews) { news in
                PostView(news: news)
                
            }
         
            
        }
      
    }

    // Модель для временных статей
    struct Article: Identifiable {
        let id = UUID()
        let title: String
        let content: String
    }

    // Тестовые статьи
    let sampleArticles = [
        Article(title: "Как улучшить продуктивность?", content: "Рассказываем о техниках тайм-менеджмента, которые работают в 2025 году."),
        Article(title: "SwiftUI или UIKit?", content: "Сравниваем два подхода к разработке интерфейсов для iOS."),
        Article(title: "10 полезных книг по программированию", content: "Список лучших книг, которые помогут стать профессионалом в кодинге.")
    ]
    
    struct MiniAppCard: View {
        let app: MiniApp
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: app.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(app.color)
                        .cornerRadius(12)
                    
                    Text(app.name)
                        .font(FontTheme.caption)
//                        .foregroundColor(theme.textColor)
                        .lineLimit(1)
                }
                .padding()
//                .background(theme.cardsBackgroundColor)
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
            }
        }
    }

    // Карточка статьи
    struct ArticleCard: View {
        let article: Article
        let theme: ThemeProtocol.Type
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(article.title)
                    .font(FontTheme.header)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
                
                Text(article.content)
                    .font(FontTheme.body)
                    .foregroundColor(theme.textColor)
                    .lineLimit(3)
                
                Text("Читать полностью")
                    .font(FontTheme.caption)
                    .foregroundColor(theme.buttonsBackgroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(theme.cardsBackgroundColor)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
        }
    }
    private func refreshData() async {
        isLoadingPosts = true
        await userStore.refreshData()
        do {
            try await chatStore.fetchNews()
        } catch {
            print("Ошибка обновления данных: \(error)")
        }
        isLoadingPosts = false
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
    let theme: ThemeProtocol.Type
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(count)
                .font(FontTheme.title)
                .fontWeight(.bold)
                .foregroundColor(theme.textColor)
            
            Text(title)
                .font(FontTheme.caption)
                .foregroundColor(theme.secondTextColor)
        }
        .frame(width: 70)
        .padding()
        .background(theme.cardsBackgroundColor)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
    }
}

struct NewsCard: View {
    let news: News
    let theme: ThemeProtocol.Type
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(news.title)
                .font(FontTheme.header)
                .fontWeight(.bold)
                .foregroundColor(theme.textColor)
            
            if let imageUrl = news.fileUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure, .empty:
                        PlaceholderView()
                    default:
                        ProgressView()
                            .frame(height: 200)
                    }
                }
            } else {
                PlaceholderView()
            }


            
            Text(news.content)
                .font(FontTheme.body)
                .foregroundColor(theme.textColor)
                .lineLimit(3)
            
            Text("Читать полностью")
                .font(.custom("Racama-U", size: 12))
                .foregroundColor(theme.buttonsBackgroundColor)
            
            Text(news.createdAt ?? "Дата неизвестна")
                .font(FontTheme.small)
                .foregroundColor(theme.secondTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.cardsBackgroundColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
    }
}

// Компонент-заглушка
struct PlaceholderView: View {
    var body: some View {
        ZStack {
            
            Color.gray.opacity(0.3) // Серый фон
                .cornerRadius(12)
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.gray)
                
        }
        .frame(height: 200)
        .clipped()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserStore())
            .environmentObject(ChatStore(userStore: UserStore()))
    }
}
