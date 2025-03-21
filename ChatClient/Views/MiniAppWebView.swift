import SwiftUI

struct MiniAppWebView: View {
    let app: MiniApp
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = true
    @State private var showCloseConfirmation = false
    
    private var theme: ThemeProtocol.Type {
        colorScheme == .dark ? Theme.DarkTheme.self : Theme.LightTheme.self
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Button(action: {
                    HapticManager.shared.impactOccurred(style: .light)
                    showCloseConfirmation = true
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(theme.textColor)
                        .padding(8)
                        .background(theme.cardsBackgroundColor.opacity(0.8))
                        .clipShape(Circle())
                }
                .buttonStyle(BouncyButtonStyle())
                
                Spacer()
                
                Text(app.name)
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                
                Spacer()
                
                Image(systemName: app.icon)
                    .font(.title3)
                    .foregroundColor(app.color)
                    .padding(8)
                    .background(theme.cardsBackgroundColor.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding()
            .background(theme.cardsBackgroundColor)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Индикатор загрузки
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .transition(.opacity)
            }
            
            // Веб-контент
            if let url = URL(string: app.url) {
                WebView(url: url, isLoading: $isLoading)
                    .transition(.opacity)
            } else {
                Text("Неверный URL")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: $showCloseConfirmation) {
            Alert(
                title: Text("Закрыть приложение?"),
                message: Text("Вы уверены, что хотите закрыть \(app.name)?"),
                primaryButton: .default(Text("Отмена")),
                secondaryButton: .destructive(Text("Закрыть")) {
                    HapticManager.shared.impactOccurred()
                    dismiss()
                }
            )
        }
        .onAppear {
            // Вибрация при открытии приложения
            HapticManager.shared.notificationOccurred(type: .success)
        }
    }
}
