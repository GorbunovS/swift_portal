import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var userStore: UserStore
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            // Домашняя страница
            SidebarButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 0]
                )
            }
            
            // Сообщения
            SidebarButton(
                icon: "message.fill",
                title: "Messages",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 1]
                )
            }
            
            // Задачи
            SidebarButton(
                icon: "checkmark.circle.fill",
                title: "Tasks",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 2]
                )
            }
            
            // Коллеги
            SidebarButton(
                icon: "person.2.fill",
                title: "Colleagues",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 3]
                )
            }
            
            // Хранилище
            SidebarButton(
                icon: "folder.fill",
                title: "Storage",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 4]
                )
            }
            
            // Мини-приложения
            SidebarButton(
                icon: "square.grid.2x2.fill",
                title: "Mini Apps",
                isSelected: selectedTab == 5
            ) {
                selectedTab = 5
                NotificationCenter.default.post(
                    name: NSNotification.Name("ChangeTab"),
                    object: nil,
                    userInfo: ["tab": 5]
                )
            }
            
            Spacer()
        }
        .frame(width: 80)
        .background(Color(.systemGray6))
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(10)
        }
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView()
            .environmentObject(UserStore())
    }
} 