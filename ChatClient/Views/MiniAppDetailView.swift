import SwiftUI

struct MiniAppDetailView: View {
    let app: MiniApp
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private var theme: ThemeProtocol.Type {
        colorScheme == .dark ? Theme.DarkTheme.self : Theme.LightTheme.self
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Заголовок приложения
                HStack {
                    Image(systemName: app.icon)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(app.color)
                        .cornerRadius(20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(theme.textColor)
                        
                        Text(app.description)
                            .font(.subheadline)
                            .foregroundColor(theme.secondTextColor)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(theme.cardsBackgroundColor)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Заглушка для контента приложения
                VStack {
                    Spacer()
                    
                    Text("Содержимое приложения \"\(app.name)\"")
                        .font(.headline)
                        .foregroundColor(theme.secondTextColor)
                    
                    Text("Маршрут: \(app.route)")
                        .font(.subheadline)
                        .foregroundColor(theme.secondTextColor)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.backgroundColor.opacity(0.5))
                .cornerRadius(15)
                .padding()
                
                Spacer()
            }
            .navigationTitle(app.name)
            .navigationBarItems(trailing: Button("Закрыть") {
                dismiss()
            })
        }
    }
}

struct MiniAppDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleApp = MiniApp(
            id: 1,
            name: "Календарь",
            description: "Управление встречами и событиями",
            icon: "calendar",
            color: .blue,
            count: "5",
            route: "/calendar",
            url: "https://vk.com"
        )
        
        MiniAppDetailView(app: sampleApp)
    }
}
