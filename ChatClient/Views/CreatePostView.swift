import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var chatStore: ChatStore
    @EnvironmentObject var userStore: UserStore
    @State private var title = ""
    @State private var content = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Заголовок")) {
                    TextField("Введите заголовок", text: $title)
                }
                
                Section(header: Text("Содержание")) {
                    TextEditor(text: $content)
                        .frame(height: 200)
                }
                
                Section(header: Text("Изображение")) {
                    PhotosPicker(selection: $selectedImage,
                               matching: .images) {
                        if let imageData = imageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            Label("Выберите изображение", systemImage: "photo")
                        }
                    }
                }
            }
            .navigationTitle("Новый пост")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Опубликовать") {
                        Task {
                            await createPost()
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty || imageData == nil || isLoading)
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .alert("Ошибка", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createPost() async {
        isLoading = true
        
        do {
            // Сначала загружаем изображение
            let fileId = try await chatStore.uploadImage(imageData!)
            
            // Создаем пост
            let post = Post(
                id: 0, // ID будет назначен сервером
                title: title,
                text: content,
                author: userStore.fullName,
                date: Date().formatted()
            )
            
            try await chatStore.createPost(post: post, fileId: fileId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

#Preview {
    CreatePostView()
        .environmentObject(ChatStore(userStore: UserStore()))
} 