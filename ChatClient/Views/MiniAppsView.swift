import SwiftUI

struct MiniAppsView: View {
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
                Text("Мини-приложения")
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
            
            // Сетка приложений
            if filteredApps.isEmpty {
                Spacer()
                Text("Нет доступных приложений")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(filteredApps) { app in
                            AppCard(app: app, isSelected: false) {
                                // Действие при нажатии на карточку
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Загрузка приложений (в реальном приложении это был бы запрос к API)
            apps = sampleApps
        }
    }
}

struct MiniApp: Identifiable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let color: Color
}

struct MiniAppsView_Previews: PreviewProvider {
    static var previews: some View {
        MiniAppsView()
    }
}
