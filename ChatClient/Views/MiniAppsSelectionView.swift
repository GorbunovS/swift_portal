//
//  MiniAppsSelectionView.swift
//  ChatClient
//
//  Created by Станислав Горбунов on 18.03.2025.
//

import SwiftUI

struct MiniAppsSelectionView: View {
    @Binding var selectedMiniApps: [MiniApp]
    @State private var apps: [MiniApp] = []
    @State private var searchText = ""
    
    // Примерные данные для мини-приложений
    let sampleApps: [MiniApp] = [
        MiniApp(id: 1, name: "Калькулятор", description: "Простой калькулятор для быстрых вычислений", icon: "calculator", color: .blue),
        MiniApp(id: 2, name: "Заметки", description: "Создавайте и редактируйте заметки", icon: "note.text", color: .yellow),
        MiniApp(id: 3, name: "Погода", description: "Прогноз погоды на неделю", icon: "cloud.sun", color: .cyan),
        MiniApp(id: 4, name: "Календарь", description: "Планируйте свои встречи и события", icon: "calendar", color: .red),
        MiniApp(id: 5, name: "Переводчик", description: "Перевод текста на разные языки", icon: "globe", color: .green),
        MiniApp(id: 6, name: "Сканер QR", description: "Сканирование QR-кодов", icon: "qrcode", color: .purple)
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
        VStack(spacing: 16) {
            // Заголовок и поиск
            VStack(spacing: 16) {
                Text("Выберите мини-приложения")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Поиск
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Поиск приложений", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Список приложений
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(filteredApps) { app in
                        AppCard(app: app, isSelected: selectedMiniApps.contains(where: { $0.id == app.id })) {
                            if selectedMiniApps.contains(where: { $0.id == app.id }) {
                                selectedMiniApps.removeAll(where: { $0.id == app.id })
                            } else {
                                selectedMiniApps.append(app)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            apps = sampleApps
        }
    }
}

struct AppCard: View {
    let app: MiniApp
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Иконка
                Image(systemName: app.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(app.color)
                    .cornerRadius(16)
                    .overlay(
                        isSelected ? Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .padding(4) : nil
                    )
                
                // Название и описание
                Text(app.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(app.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
