import SwiftUI

struct NewsView: View {
    @EnvironmentObject var chatStore: ChatStore
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(chatStore.news) { news in
                        NewsRow(news: news)
                    }
//                    .refreshable {
//                        await loadNews()
//                    }
                }
            }
            .navigationTitle("Новости")
            .task {
                await loadNews()
            }
        }
    }
    
    private func loadNews() async {
        isLoading = true
        error = nil
        
        do {
            try await chatStore.fetchNews()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct NewsRow: View {
    let news: News
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.headline)
            
            if let imageUrl = news.fileUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 200)
                .clipped()
            }
            
            Text(news.content)
                .font(.body)
            
            Text(news.createdAt ?? "Дата неизвестна")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NewsView()
        .environmentObject(ChatStore(userStore: UserStore()))
} 
