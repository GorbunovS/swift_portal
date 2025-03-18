import SwiftUI

// Импортируем модель Post
import struct ChatClient.Post

struct PostCard: View {
    let post: Post
    @State private var showingFullPost = false
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок
            Text(post.title)
                .font(FontTheme.header)
                .foregroundColor(Theme.LightTheme.textColor)
                .lineLimit(2)
            
            // Автор и дата
            HStack {
                Text(post.author)
                    .font(FontTheme.caption)
                    .foregroundColor(Theme.LightTheme.secondTextColor)
                
                Spacer()
                
                Text(post.date)
                    .font(FontTheme.caption)
                    .foregroundColor(Theme.LightTheme.secondTextColor)
            }
            
            // Текст поста
            Text(post.text)
                .font(FontTheme.body)
                .foregroundColor(Theme.LightTheme.textColor)
                .lineLimit(3)
        }
        .padding()
        .background(Theme.LightTheme.cardsBackgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onLongPressGesture(minimumDuration: 0.5) {
            showingFullPost = true
        }
        .sheet(isPresented: $showingFullPost) {
            FullPostView(post: post)
        }
    }
}

#Preview {
    PostCard(post: Post(
        id: 1,
        title: "Тестовый пост",
        text: "Это длинный текст поста, который может занимать несколько строк и содержать много информации. Здесь может быть любой текст, который нужно отобразить полностью.",
        author: "Автор",
        date: "01.01.2024"
    ))
    .padding()
    .background(Theme.LightTheme.backgroundColor)
} 
