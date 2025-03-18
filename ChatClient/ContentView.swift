//
//  ContentView.swift
//  ChatClient
//
//  Created by Станислав Горбунов on 18.03.2025.
//

//
//  ContentView.swift
//  ChatClient
//
//  Created by Станислав Горбунов on 17.03.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var selectedTab: Int = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        ZStack {
            // Фон для всего приложения в зависимости от темы
            (isDarkMode ? Theme.DarkTheme.backgroundColor : Theme.LightTheme.backgroundColor)
                .edgesIgnoringSafeArea(.all)
            
            if userStore.isAuthenticated {
                VStack(spacing: 0) {
                    // Верхний заголовок с блюром
                    HeaderView()
                        .background(.ultraThinMaterial)
                    
                    // Основной контент
                    ZStack {
                        switch selectedTab {
                        case 0:
                            HomeView()
                        case 1:
                            ChatInterfaceView()
                        case 2:
                            ColleaguesView()
                        case 3:
                            StorageView()
                        case 4:
                            MiniAppsView()
                        default:
                            HomeView()
                        }
                    }
                    
                    // Нижняя панель навигации с блюром
                    BottomSidebarView(selectedTab: $selectedTab)
                        .frame(height: 70)
                        .background(.ultraThinMaterial)
                }
                .onAppear {
                    userStore.fetchData()
                    chatStore.fetchChats()
                }
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

// Нижняя панель навигации
struct BottomSidebarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            BottomTabButton(
                icon: "house.fill",
                title: "Главная",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            BottomTabButton(
                icon: "message.fill",
                title: "Чаты",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            BottomTabButton(
                icon: "person.2.fill",
                title: "Коллеги",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            BottomTabButton(
                icon: "folder.fill",
                title: "Файлы",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
            
            BottomTabButton(
                icon: "square.grid.2x2.fill",
                title: "Приложения",
                isSelected: selectedTab == 4,
                action: { selectedTab = 4 }
            )
        }
        .padding(.bottom, 5)
    }
}

// Кнопка для нижней панели
struct BottomTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .blue.opacity(0.5))
                
                Text(title)
                    .font(.custom("Racama-U", size: 10))
                    .foregroundColor(isSelected ? .blue : .blue.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserStore())
        .environmentObject(ChatStore(userStore: UserStore()))
}
