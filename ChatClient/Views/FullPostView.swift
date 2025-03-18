import SwiftUI

// Импортируем модель Post
import struct ChatClient.Post

struct FullPostView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(post.title)
                        .font(FontTheme.title)
                        .foregroundColor(Theme.LightTheme.textColor)
                    
                    HStack {
                        Text(post.author)
                            .font(FontTheme.caption)
                            .foregroundColor(Theme.LightTheme.secondTextColor)
                        
                        Spacer()
                        
                        Text(post.date)
                            .font(FontTheme.caption)
                            .foregroundColor(Theme.LightTheme.secondTextColor)
                    }
                    
                    Text(post.text)
                        .font(FontTheme.body)
                        .foregroundColor(Theme.LightTheme.textColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .background(Theme.LightTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FullPostView(post: Post(
        id: 1,
        title: "Тестовый пост",
        text: "Это длинный текст поста, который может занимать несколько строк и содержать много информации. Здесь может быть любой текст, который нужно отобразить полностью.",
        author: "Автор",
        date: "01.01.2024"
    ))
} 
