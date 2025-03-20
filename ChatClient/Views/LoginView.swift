import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var userStore: UserStore
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                // Логотип и заголовок
                VStack(spacing: 8) {
                    Image("logo_white")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .foregroundColor(.white)
                    
                    Text("Войдите в свой аккаунт")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 40)
                
                // Форма входа
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Пароль", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if showError {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text("Войти")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Регистрация (заглушка)
                HStack {
                    Text("Нет аккаунта?")
                        .foregroundColor(.gray)
                    
                    Button("Зарегистрироваться") {
                        // Функционал регистрации
                    }
                    .foregroundColor(.blue)
                }
                .padding(.bottom, 20)
            }
            .padding()
            .frame(maxWidth: 400)
        }
    }
    
    private func login() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Введите email и пароль"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        userStore.login(userLogin: email, password: password) { success, error in
            isLoading = false
            
            if !success {
                self.errorMessage = error ?? "Произошла ошибка при входе"
                print("Login error: \(self.errorMessage)")
                self.showError = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(UserStore())
    }
} 
