import SwiftUI

struct PostView: View {
    let news: News
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(news.title)
                    .font(FontTheme.title)
                    .fontWeight(.bold)
              
                
                if let imageUrl = news.fileUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                Text(news.content)
                    .font(FontTheme.body)
                   
                
                Text(news.createdAt ?? "Дата неизвестна")
                    .font(FontTheme.caption)
                  
            }
            .padding()
        }
        .navigationBarTitle("Новость", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(Theme.LightTheme.textColor)
        })
        
    }
}
