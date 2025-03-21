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
import UIKit

struct ContentView: View {
    @EnvironmentObject private var userStore: UserStore
    @EnvironmentObject private var chatStore: ChatStore
    @State private var selectedTab: Int = 0
    @State private var isChatOpen: Bool = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMiniApps: [MiniApp] = []
    
    private var theme: ThemeProtocol.Type {
        colorScheme == .dark ? Theme.DarkTheme.self : Theme.LightTheme.self
    }
    
    var body: some View {
            ZStack {
                // Фон для всего приложения в зависимости от темы
                (isDarkMode ? Theme.DarkTheme.backgroundColor : Theme.LightTheme.backgroundColor)
                    .edgesIgnoringSafeArea(.all)
                
                if userStore.isAuthenticated {
                    GeometryReader { geometry in
                        // Основной контент с отступами
                        ZStack {
                            switch selectedTab {
                            case 0:
                                HomeView()

                            case 1:
                                ChatInterfaceView(isChatOpen: $isChatOpen)
                                
                            case 2:
                                ColleaguesView()
                             
                            case 3:
                                StorageView()
                                
                            case 4:
                                MiniAppsView(selectedMiniApps: $selectedMiniApps)
                              
                            default:
                                HomeView()
                               
                            }
                        }
                        .onAppear {
                            userStore.fetchData()
                        }
                        
                        // Верхний заголовок с блюром
                                      if !isChatOpen {
                                          VStack {
                                              HeaderView()
                                                  .background(.ultraThinMaterial)
                                              Spacer()
                                          }
                                      }
                                      
                                      // Нижняя панель навигации с блюром
                                      if !isChatOpen {
                                          VStack {
                                              Spacer()
                                              BottomSidebarView(selectedTab: $selectedTab)
                                                  .background(.ultraThinMaterial)
                                          }
                                      }
                                  }
                } else {
                    LoginView()
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                // Проверяем авторизацию при запуске приложения
                if userStore.isAuthenticated {
                    userStore.fetchData()
                }
                
                // Загружаем выбранные мини-приложения при запуске
                loadSelectedMiniApps()
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
        .padding( 10)
        
        
    }
    
    
}

// Кнопка для нижней панели
struct BottomTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    private var theme: ThemeProtocol.Type {
        colorScheme == .dark ? Theme.DarkTheme.self : Theme.LightTheme.self
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? theme.buttonsBackgroundColor : theme.buttonsBackgroundColor.opacity(0.5))
                
                Text(title)
                    .font(.custom("Racama-U", size: 10))
                    .foregroundColor(isSelected ? theme.buttonsBackgroundColor : theme.buttonsBackgroundColor.opacity(0.5))
            }
        
        }
        .frame(maxWidth: .infinity)
    
    }
}

#Preview {
    ContentView()
        .environmentObject(UserStore())
        .environmentObject(ChatStore(userStore: UserStore()))
}
