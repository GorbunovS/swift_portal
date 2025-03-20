import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject private var userStore: UserStore
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var imageData: Data?
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var avatarImage: Image?
    
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Фотография профиля")) {
                    VStack {
                        if let avatarImage = avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else if !userStore.avatarId.isEmpty {
                            ProfileImage(avatarId: userStore.avatarId)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                        }
                        
                        Button("Изменить фото") {
                            showingImagePicker = true
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Личная информация")) {
                    TextField("Имя", text: $firstName)
                    TextField("Фамилия", text: $lastName)
                }
                
                Section(header: Text("Настройки")) {
                    Toggle("Тёмная тема", isOn: $isDarkMode)
                }
                
                Section(header: Text("Изменение пароля")) {
                    SecureField("Текущий пароль", text: $currentPassword)
                    SecureField("Новый пароль", text: $newPassword)
                    SecureField("Подтвердите пароль", text: $confirmPassword)
                }
                
                Section {
                    Button(action: updateProfile) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Сохранить изменения")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isLoading)
                }
                
                Button(action: userStore.logout) {
                    Text("Выйти из профиля")
                }
                
                if showSuccess {
                    Section {
                        Text("Профиль успешно обновлен")
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Редактирование профиля")
            .navigationBarItems(trailing: Button("Закрыть") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingImagePicker) {
                PHPickerView(image: $inputImage)
            }
            .onChange(of: inputImage) { oldImage, newImage in
                if let image = newImage {
                    loadImage()
                }
            }
            .onAppear {
                firstName = userStore.firstName
                lastName = userStore.lastName
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        avatarImage = Image(uiImage: inputImage)
        imageData = inputImage.jpegData(compressionQuality: 0.8)
    }
    
    private func updateProfile() {
        isLoading = true
        showSuccess = false
        showError = false
        
        // Проверка данных
        if newPassword != confirmPassword {
            errorMessage = "Пароли не совпадают"
            showError = true
            isLoading = false
            return
        }
        
        var profileData: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName
        ]
        
        if !newPassword.isEmpty {
            guard !currentPassword.isEmpty else {
                errorMessage = "Введите текущий пароль"
                showError = true
                isLoading = false
                return
            }
            
            profileData["current_password"] = currentPassword
            profileData["new_password"] = newPassword
        }
        
        // Загрузка аватара, если есть
        if let imageData = imageData {
            // Здесь должен быть код для загрузки изображения на сервер
            // В реальном приложении это будет отдельный запрос
        }
        
        userStore.updateProfile(profileData: profileData) { success, error in
            isLoading = false
            
            if success {
                showSuccess = true
                
                // Очистить поля пароля после успешного обновления
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
            } else {
                errorMessage = error ?? "Произошла ошибка при обновлении профиля"
                showError = true
            }
        }
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView()
            .environmentObject(UserStore())
    }
} 
