import SwiftUI

struct MiniAppsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedMiniApps") private var selectedMiniAppsData: Data = Data()
    
    @State private var apps: [MiniApp] = []
    @State private var searchText = ""
    @State private var isSelectionMode = false
    @State private var selectedApps: Set<Int> = []
    @Binding var selectedMiniApps: [MiniApp]
    @State private var selectedApp: MiniApp?
    @State private var showWebView = false
    @State private var animateCard: Int? = nil
    
    private var theme: ThemeProtocol.Type {
        colorScheme == .dark ? Theme.DarkTheme.self : Theme.LightTheme.self
    }
    
    // Список всех доступных мини-приложений с URL
    let allMiniApps: [MiniApp] = [
        MiniApp(id: 1, name: "Почта", description: "Быстрый доступ к почте", icon: "envelope", color: .blue, count: "100+", route: "/mail", url: "https://mail.example.com"),
        MiniApp(id: 2, name: "Задачи", description: "Управление задачами", icon: "briefcase", color: .orange, count: "5", route: "/tasks", url: "https://tasks.example.com"),
        MiniApp(id: 3, name: "Календарь", description: "Планирование встреч", icon: "calendar", color: .green, count: "5", route: "/calendar", url: "https://calendar.example.com"),
        MiniApp(id: 4, name: "Чат с ИИ", description: "Общение с искусственным интеллектом", icon: "bubble.left.and.bubble.right", color: .purple, count: "", route: "/ai-chat", url: "https://ai-chat.example.com"),
        MiniApp(id: 5, name: "Дней до отпуска", description: "Счетчик дней до отпуска", icon: "airplane", color: .cyan, count: "23", route: "/vacation-countdown", url: "https://vacation.example.com"),
        MiniApp(id: 6, name: "Конструктор открытки", description: "Создание электронных открыток", icon: "gift", color: .pink, count: "", route: "/card-creator", url: "https://card-creator.example.com"),
        MiniApp(id: 7, name: "Календарь встреч", description: "Управление встречами", icon: "person.2", color: .indigo, count: "3", route: "/meetings", url: "https://meetings.example.com"),
        MiniApp(id: 8, name: "Бронирование", description: "Бронирование переговорных комнат", icon: "door.right.hand.open", color: .teal, count: "", route: "/room-booking", url: "https://room-booking.example.com"),
        MiniApp(id: 9, name: "Заметки", description: "Быстрые заметки", icon: "note.text", color: .yellow, count: "12", route: "/notes", url: "https://notes.example.com")
    ]
    
    var filteredApps: [MiniApp] {
        if searchText.isEmpty {
            return apps
        } else {
            return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) ||
                                $0.description.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 16) {
                // Заголовок
                Text("Мини-приложения")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 60) // Добавляем отступ сверху для учета HeaderView
                
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Поиск приложений", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Сетка приложений
                if filteredApps.isEmpty {
                    Spacer()
                    Text("Нет доступных приложений")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                            ForEach(filteredApps) { app in
                                MiniAppCard(
                                    app: app,
                                    isSelected: selectedApps.contains(app.id),
                                    isSelectionMode: isSelectionMode,
                                    theme: theme,
                                    isAnimating: animateCard == app.id
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        animateCard = app.id
                                    }
                                    
                                    // Добавляем небольшую задержку перед обработкой нажатия
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        handleTap(app)
                                        animateCard = nil
                                    }
                                }
                                .onLongPressGesture {
                                    if !isSelectionMode {
                                        // Вибрация при входе в режим выбора
                                        HapticManager.shared.notificationOccurred(type: .warning)
                                        
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            isSelectionMode = true
                                            selectedApps.insert(app.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.bottom, 70) // Добавляем отступ снизу для учета BottomSidebarView
                }
                
                if isSelectionMode {
                    HStack {
                        Button(action: {
                            // Вибрация при отмене
                            HapticManager.shared.impactOccurred(style: .light)
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSelectionMode = false
                                selectedApps.removeAll()
                            }
                        }) {
                            Text("Отмена")
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Вибрация при сохранении
                            HapticManager.shared.notificationOccurred()
                            
                            withAnimation {
                                saveSelection()
                            }
                        }) {
                            Text("Сохранить")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80) // Увеличиваем отступ для кнопок в режиме выбора
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(theme.backgroundColor)
        }
        .edgesIgnoringSafeArea(.all) // Игнорируем безопасную зону, но добавляем свои отступы
        .onAppear {
            // Загрузка приложений
            apps = allMiniApps
            
            // Загрузка выбранных приложений
            loadSelectedApps()
        }
        .fullScreenCover(item: $selectedApp) { app in
            MiniAppWebView(app: app)
        }
    }
    
    private func handleTap(_ app: MiniApp) {
        if isSelectionMode {
            // Вибрация при выборе/отмене выбора
            HapticManager.shared.selectionChanged()
            
            if selectedApps.contains(app.id) {
                selectedApps.remove(app.id)
            } else {
                selectedApps.insert(app.id)
            }
        } else {
            // Вибрация при открытии приложения
            HapticManager.shared.impactOccurred()
            
            // Открыть веб-приложение
            selectedApp = app
        }
    }
    
    private func saveSelection() {
        // Сохраняем выбранные приложения
        let selectedMiniAppsList = apps.filter { selectedApps.contains($0.id) }
        self.selectedMiniApps = selectedMiniAppsList
        
        // Сохраняем ID выбранных приложений в UserDefaults
        if let encodedData = try? JSONEncoder().encode(Array(selectedApps)) {
            selectedMiniAppsData = encodedData
        }
        
        // Закрываем экран выбора
        if isSelectionMode {
            isSelectionMode = false
        }
        dismiss()
    }
    
    private func loadSelectedApps() {
        // Загружаем ID выбранных приложений из UserDefaults
        if let decodedIds = try? JSONDecoder().decode([Int].self, from: selectedMiniAppsData) {
            selectedApps = Set(decodedIds)
            
            // Обновляем список выбранных приложений
            let selectedMiniAppsList = apps.filter { selectedApps.contains($0.id) }
            self.selectedMiniApps = selectedMiniAppsList
        } else {
            // По умолчанию выбираем первые 3 приложения, если ничего не выбрано
            if selectedMiniApps.isEmpty {
                selectedApps = Set(allMiniApps.prefix(3).map { $0.id })
                selectedMiniApps = Array(allMiniApps.prefix(3))
            } else {
                selectedApps = Set(selectedMiniApps.map { $0.id })
            }
        }
    }
}

struct MiniAppCard: View {
    let app: MiniApp
    let isSelected: Bool
    let isSelectionMode: Bool
    let theme: ThemeProtocol.Type
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: app.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(app.color)
                    .cornerRadius(12)
                
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                        .background(Color.white.clipShape(Circle()))
                        .offset(x: 5, y: -5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if !app.count.isEmpty {
                Text(app.count)
                    .font(FontTheme.title)
                    .fontWeight(.bold)
                    .foregroundColor(theme.textColor)
            } else {
                Spacer()
                    .frame(height: 20)
            }
            
            Text(app.name)
                .font(FontTheme.caption)
                .foregroundColor(theme.secondTextColor)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80, height: 120)
        .padding()
        .background(theme.cardsBackgroundColor)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(isSelected && isSelectionMode ? app.color : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isAnimating ? 0.9 : 1.0)
    }
}

struct MiniAppsView_Previews: PreviewProvider {
    static var previews: some View {
        MiniAppsView(selectedMiniApps: .constant([]))
    }
}
