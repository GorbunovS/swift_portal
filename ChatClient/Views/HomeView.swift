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
    @State private var loginMessage: String?
    @State private var showEditProfile = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMiniApps: [MiniApp] = []
    @State private var animatingAppId: Int? = nil
    
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
                            HapticManager.shared.impactOccurred(style: .light)
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
                        // Мини-приложения
                        HStack(spacing: 16) {
                            // Отображаем выбранные мини-приложения
                            ForEach(selectedMiniApps) { app in
                                MiniAppCard(
                                    app: app,
                                    isSelected: false,
                                    isSelectionMode: false,
                                    theme: theme,
                                    isAnimating: animatingAppId == app.id
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        animatingAppId = app.id
                                    }
                                    
                                    // Добавляем небольшую задержку перед обработкой нажатия
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        openMiniApp(app)
                                        animatingAppId = nil
                                    }
                                }
                            }
                            
                            // Кнопка "Ещё"
                            Button(action: {
                                HapticManager.shared.impactOccurred()
                                withAnimation {
                                    showMiniApps = true
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(.blue)
                                        .cornerRadius(12)
                                    
                                    Text(" ")
                                        .font(FontTheme.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(theme.textColor)
                                    
                                    Text("Ещё")
                                        .font(FontTheme.caption)
                                        .foregroundColor(theme.secondTextColor)
                                }
                                .frame(width: 80, height: 120)
                                .padding()
                                .background(theme.cardsBackgroundColor)
                                .cornerRadius(25)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
                            }
                            .buttonStyle(BouncyButtonStyle())
                        }
                        .padding(.horizontal)
                        .padding(.vertical)
                    }
                    
                    // Вкладки новостей и статей
                    HStack {
                        HStack {
                            Button(action: {
                                if selectedTab != 0 {
                                    HapticManager.shared.selectionChanged()
                                    withAnimation {
                                        selectedTab = 0
                                    }
                                }
                            }) {
                                Text("Новости")
                                    .font(FontTheme.header)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedTab == 0 ? theme.buttonsBackgroundColor : Color.clear)
                                    .foregroundColor(selectedTab == 0 ? Color.white : theme.secondTextColor)
                                    .cornerRadius(16)
                            }
                            
                            Button(action: {
                                if selectedTab != 1 {
                                    HapticManager.shared.selectionChanged()
                                    withAnimation {
                                        selectedTab = 1
                                    }
                                }
                            }) {
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
                        
                        Button(action: {
                            HapticManager.shared.impactOccurred()
                            showCreatePost = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.buttonsBackgroundColor)
                                .font(.title2)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Контент (Новости или Статьи)
                    TabView(selection: $selectedTab) {
                        // Экран новостей
                        ScrollView {
                            VStack(spacing: 20) {
                                if userStore.isLoading {
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
                                            .onTapGesture {
                                                HapticManager.shared.impactOccurred()
                                                selectedNews = news
                                            }
                                    }
                                }
                            }
                            .padding(.top)
                        }
                        .tag(0)
                        
                        // Экран статей
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(sampleArticles) { article in
                                    ArticleCard(article: article, theme: theme)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            HapticManager.shared.impactOccurred(style: .light)
                                        }
                                }
                            }
                            .padding(.top)
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                }
            }

            .padding(.vertical, 60)
            .background(theme.backgroundColor)
            .edgesIgnoringSafeArea(.bottom)
            
            .onAppear {
                Task { await loadNews() }
                
                // If we have an avatar ID but no avatar image, load it
                if !userStore.avatarId.isEmpty && userStore.avatarImage == nil {
                    loadAvatar()
                }
                
                // Загружаем выбранные мини-приложения
                loadSelectedMiniApps()
                
                // Print user data for debugging
                print("User data on appear - Name: \(userStore.firstName) \(userStore.lastName)")
                print("Avatar ID: \(userStore.avatarId)")
                print("Is authenticated: \(userStore.isAuthenticated)")
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
            
            .refreshable {
                HapticManager.shared.impactOccurred()
                print("имя: \(userStore.firstName)")
                print("фамилия: \(userStore.lastName)")
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
    
    private func loadSelectedMiniApps() {
        // Загружаем ID выбранных приложений из UserDefaults
        if let selectedMiniAppsData = UserDefaults.standard.data(forKey: "selectedMiniApps"),
           let decodedIds = try? JSONDecoder().decode([Int].self, from: selectedMiniAppsData) {
            
            // Получаем список всех доступных мини-приложений
            let allMiniApps = MiniAppsView(selectedMiniApps: $selectedMiniApps).allMiniApps
            
            // Фильтруем только выбранные приложения
            selectedMiniApps = allMiniApps.filter { decodedIds.contains($0.id) }
        } else {
            // По умолчанию выбираем первые 3 приложения, если ничего не выбрано
            let allMiniApps = MiniAppsView(selectedMiniApps: $selectedMiniApps).allMiniApps
            selectedMiniApps = Array(allMiniApps.prefix(3))
        }
    }
    
    private func openMiniApp(_ app: MiniApp) {
        // Вибрация при открытии приложения
        HapticManager.shared.impactOccurred()
        
        // Открываем веб-приложение
        if let url = URL(string: app.url) {
            let webView = MiniAppWebView(app: app)
        
            // Создаем UIHostingController для отображения SwiftUI View
            let hostingController = UIHostingController(rootView: webView)
        
            // Получаем текущий UIViewController для отображения
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(hostingController, animated: true)
            }
        } else {
            // Показываем ошибку, если URL неверный
            HapticManager.shared.notificationOccurred(type: .error)
            
            let alertTitle = "Ошибка"
            let alertMessage = "Не удалось открыть приложение \(app.name). Неверный URL."
        
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alertController, animated: true)
            }
        }
    }
}

// Стиль кнопки с анимацией нажатия
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
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
        .contentShape(Rectangle())
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
