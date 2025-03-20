import Foundation
import Combine
import UIKit

class UserStore: ObservableObject {
    @Published var user: User?
    @Published var token: String?
    @Published var avatarImage: UIImage? = nil
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var avatarId: String = ""
    @Published var users: [User] = []
    @Published var news: [NewsItem] = []
    
    // Используем более гибкий подход, впоследствии это можно заменить на чтение из конфигурационного файла
    #if DEBUG
    private let baseURL = "http://192.168.1.67:5005"
    private let apiURL = "http://192.168.1.67:5005/api"
    #else
    private let baseURL = "https://api.example.com"
    private let apiURL = "https://api.example.com/api"
    #endif
    
    private let userDefaults = UserDefaults.standard
    
    // Вычисляемое свойство для проверки аутентификации
    var isUserAuthenticated: Bool {
        return token != nil && !(token!.isEmpty)
    }
    
    var fullName: String {
        return "\(lastName) \(firstName)"
    }
    
    init() {
        // Восстанавливаем данные при инициализации
        restoreUserData()
    }
    
    private func restoreUserData() {
        // Восстанавливаем токен
        if let savedToken = userDefaults.string(forKey: "token") {
            self.token = savedToken
            self.isAuthenticated = true
        }
        
        // Восстанавливаем данные пользователя
        if let userData = userDefaults.data(forKey: "userData"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData) {
            self.user = decodedUser
            self.firstName = decodedUser.firstName
            self.lastName = decodedUser.lastName
            // Restore user ID
            userDefaults.set(decodedUser.id, forKey: "userId")
        }
        
        // Восстанавливаем avatarId
        if let savedAvatarId = userDefaults.string(forKey: "avatarId") {
            self.avatarId = savedAvatarId
        }
        
        // Если есть токен, загружаем данные
        if self.isAuthenticated {
            self.fetchData()
        }
    }
    
    private func saveUserData() {
        // Сохраняем токен
        if let token = self.token {
            userDefaults.set(token, forKey: "token")
        }
        
        // Сохраняем данные пользователя
        if let user = self.user,
           let encodedUser = try? JSONEncoder().encode(user) {
            userDefaults.set(encodedUser, forKey: "userData")
        }
        
        // Сохраняем avatarId
        userDefaults.set(self.avatarId, forKey: "avatarId")
        
        // Синхронизируем изменения
        userDefaults.synchronize()
    }
    
    func fetchData() {
        fetchNews()
        fetchUsers()
    }
    
    func refreshData() async {
        print("Starting data refresh")
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // Создаем группу для параллельного выполнения запросов
        let group = DispatchGroup()
        
        // Обновляем новости
        group.enter()
        fetchNews()
        group.leave()
        
        // Обновляем список пользователей
        group.enter()
        fetchUsers()
        group.leave()
        
        // Ждем завершения всех запросов
        group.wait()
        
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    func fetchNews() {
        guard let url = URL(string: "\(apiURL)/news") else { return }
        
        var request = URLRequest(url: url)
        request.setValue(" \(token ?? "")", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let decodedNews = try? JSONDecoder().decode([NewsItem].self, from: data) {
                    DispatchQueue.main.async {
                        self.news = decodedNews
                    }
                }
            }
        }.resume()
    }
    
    func fetchUsers() {
        guard let url = URL(string: "\(apiURL)/user/list_users") else { return }
        
        var request = URLRequest(url: url)
        request.setValue(" \(token ?? "")", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let decodedUsers = try? JSONDecoder().decode([User].self, from: data) {
                    DispatchQueue.main.async {
                        self.users = decodedUsers
                    }
                }
            }
        }.resume()
    }
    
    func login(userLogin: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // Используем правильный URL и параметры согласно коду сервера
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            completion(false, "Invalid URL")
            return
        }
        
        print("Using login URL: \(url.absoluteString)")
        
        // Используем правильные названия параметров: user_login и password
        let parameters: [String: String] = ["user_login": userLogin, "password": password]
        
        print("Login parameters: \(parameters)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(false, "Failed to serialize request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                completion(false, error?.localizedDescription ?? "No data received")
                return
            }
            
            // Отладочный вывод
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Login response: \(jsonString)")
            }
            
            self?.processServerLoginResponse(data: data, userLogin: userLogin, completion: completion)
        }.resume()
    }
    
    private func processServerLoginResponse(data: Data, userLogin: String, completion: @escaping (Bool, String?) -> Void) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            print("JSON structure: \(jsonObject)")
            
            if let json = jsonObject as? [String: Any] {
                print("JSON keys: \(json.keys)")
                
                if let error = json["error"] as? String {
                    print("Server error: \(error)")
                    completion(false, "Server error: \(error)")
                    return
                }
                
                if let accessToken = json["access_token"] as? String,
                   let userId = json["user_id"] as? Int,
                   let firstName = json["first_name"] as? String,
                   let lastName = json["last_name"] as? String {
                    
                    print("Login successful!")
                    
                    DispatchQueue.main.async {
                        self.token = accessToken
                        // Initialize user with empty position if not provided
                        let position = json["position"] as? String ?? ""
                        self.user = User(id: userId, firstName: firstName, lastName: lastName, email: userLogin, position: position)
                        self.firstName = firstName
                        self.lastName = lastName
                        self.isAuthenticated = true
                        
                        if let avatarId = json["avatar_id"] as? String {
                            self.avatarId = avatarId
                        }
                        
                        // Save user ID to UserDefaults
                        self.userDefaults.set(userId, forKey: "userId")
                        
                        // Сохраняем все данные
                        self.saveUserData()
                        
                        // Настраиваем WebSocket после успешного входа
                        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogin"), object: nil)
                        
                        completion(true, nil)
                    }
                } else {
                    print("Missing required fields in response")
                    completion(false, "Invalid server response: missing required fields")
                }
            } else {
                print("JSON is not a dictionary")
                completion(false, "Invalid response format (not a dictionary)")
            }
        } catch {
            print("Parse error details: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
            }
            completion(false, "Failed to parse response: \(error.localizedDescription)")
        }
    }
    
    func logout() {
        self.user = nil
        self.token = nil
        self.firstName = ""
        self.lastName = ""
        self.avatarId = ""
        self.isAuthenticated = false
        self.users = []
        self.news = []
        
        // Очищаем UserDefaults
        userDefaults.removeObject(forKey: "token")
        userDefaults.removeObject(forKey: "userData")
        userDefaults.removeObject(forKey: "avatarId")
        userDefaults.removeObject(forKey: "userId")
        
        // Синхронизируем изменения
        userDefaults.synchronize()
    }
    
    func getImage(fileId: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: "\(apiURL)/files/\(fileId)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("\(token ?? "")", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            completion(data)
        }.resume()
    }
    
    func getUserAvatar(avatarId: String, completion: @escaping (UIImage?) -> Void) {
        print("Fetching user avatar with ID: \(avatarId)")
        
        getImage(fileId: avatarId) { data in
            if let imageData = data, let image = UIImage(data: imageData) {
                print("Successfully loaded avatar image")
                DispatchQueue.main.async {
                    self.avatarImage = image
                    completion(image)
                }
            } else {
                print("Failed to load avatar image")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func updateProfile(profileData: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        print("Starting profile update with data: \(profileData)")
        
        guard let url = URL(string: "\(apiURL)/user/update_profile") else {
            print("Error: Invalid URL for profile update")
            completion(false, "Invalid URL")
            return
        }
        
        print("Using URL for profile update: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(" \(token ?? "")", forHTTPHeaderField: "Authorization")
        
        print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: profileData)
            print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "empty")")
        } catch {
            print("Error serializing request: \(error)")
            completion(false, "Failed to serialize request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error during profile update: \(error)")
                completion(false, error.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Profile update response status code: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("No data received from server")
                completion(false, "No data received")
                return
            }
            
            // Print raw response data
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw server response: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Parsed JSON response: \(json)")
                    
                    if let message = json["message"] as? String, message == "Profile updated successfully" {
                        print("Profile update successful")
                        
                        // Update local user data if needed
                        if let firstName = profileData["first_name"] as? String {
                            print("Updating first name to: \(firstName)")
                            DispatchQueue.main.async {
                                self?.firstName = firstName
                                self?.userDefaults.set(firstName, forKey: "first_name")
                            }
                        }
                        
                        if let lastName = profileData["last_name"] as? String {
                            print("Updating last name to: \(lastName)")
                            DispatchQueue.main.async {
                                self?.lastName = lastName
                                self?.userDefaults.set(lastName, forKey: "last_name")
                            }
                        }
                        
                        completion(true, nil)
                    } else {
                        print("Profile update failed: unexpected response format")
                        if let errorMessage = json["error"] as? String {
                            print("Server error message: \(errorMessage)")
                            completion(false, errorMessage)
                        } else {
                            completion(false, "Profile update failed")
                        }
                    }
                } else {
                    print("Failed to parse response as JSON dictionary")
                    completion(false, "Invalid response format")
                }
            } catch {
                print("Error parsing response: \(error)")
                completion(false, "Failed to parse response: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func updateProfile(firstName: String, lastName: String) async throws {
        print("Starting async profile update with firstName: \(firstName), lastName: \(lastName)")
        
        guard let token = token else {
            print("Error: No token available for profile update")
            throw UserError.unauthorized
        }
        
        let url = URL(string: "\(apiURL)/user/update_profile")!
        print("Using URL for profile update: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "first_name": firstName,
            "last_name": lastName
        ]
        
        print("Request body: \(body)")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            print("Request headers: \(request.allHTTPHeaderFields ?? [:])")
        } catch {
            print("Error encoding request body: \(error)")
            throw error
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Profile update response status code: \(httpResponse.statusCode)")
            print("Response headers: \(httpResponse.allHeaderFields)")
        }
        
        // Print raw response data
        if let responseString = String(data: data, encoding: .utf8) {
            print("Raw server response: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Profile update failed: Invalid response status code")
            throw UserError.updateFailed
        }
        
        // Обновляем локальные данные
        print("Updating local user data")
        DispatchQueue.main.async {
            self.firstName = firstName
            self.lastName = lastName
            if var updatedUser = self.user {
                updatedUser.firstName = firstName
                updatedUser.lastName = lastName
                self.user = updatedUser
                print("Local user data updated successfully")
            } else {
                print("Warning: Could not update local user data - user is nil")
            }
        }
    }
    
    func uploadAvatar(imageData: Data) async throws {
        guard let token = token else {
            throw UserError.unauthorized
        }
        
        let url = URL(string: "\(apiURL)/user/upload_avatar")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Добавляем изображение
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UserError.uploadFailed
        }
        
        let avatarResponse = try JSONDecoder().decode(AvatarResponse.self, from: data)
        
        // Обновляем локальные данные
        DispatchQueue.main.async {
            self.avatarId = avatarResponse.avatarId
            if let image = UIImage(data: imageData) {
                self.avatarImage = image
            }
        }
    }
    


    func getImage(fileId: String) async throws -> URL? {


        let url = URL(string: "\(apiURL)/api/file/get_file/\(fileId)")!
        var request = URLRequest(url: url)
        request.setValue("\(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            

            
            // Создаём временный URL для файла
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileId).jpg")
            
            try data.write(to: tempURL) // Сохраняем blob в файл
            return tempURL // Возвращаем локальный URL
        } catch {
            if (error as? URLError)?.code == .notConnectedToInternet {
                print("Ошибка сети при загрузке изображения")
                return nil
            }
            throw error
        }
    }
    
    func downloadAvatar(avatarId: String) async throws -> UIImage? {
        guard let token = token else {
            throw UserError.unauthorized
        }
        
        let url = URL(string: "\(apiURL)/user/avatar/\(avatarId)")!
        var request = URLRequest(url: url)
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw UserError.downloadFailed
        }
        
        return UIImage(data: data)
    }
}

struct User: Codable, Identifiable {
    let id: Int
    var firstName: String
    var lastName: String
    let email: String
    let position: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case position
    }
}

struct NewsItem: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let createdAt: Date
    let userId: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case createdAt = "created_at"
        case userId = "user_id"
    }
}

enum UserError: Error {
    case unauthorized
    case updateFailed
    case uploadFailed
    case downloadFailed
}

struct AvatarResponse: Codable {
    let avatarId: String
    
    enum CodingKeys: String, CodingKey {
        case avatarId = "avatar_id"
    }
} 

