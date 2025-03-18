import Foundation
import Combine

class StorageStore: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let userStore: UserStore
    private let baseURL: String
    
    init(userStore: UserStore) {
        self.userStore = userStore
        #if DEBUG
        self.baseURL = "http://192.168.1.67:5005"
        #else
        self.baseURL = "https://api.example.com"
        #endif
    }
    
    func fetchFiles() async throws {
        guard let token = userStore.token else {
            throw StorageError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/files/list")!
        var request = URLRequest(url: url)
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.serverError
        }
        
        let filesResponse = try JSONDecoder().decode(FilesResponse.self, from: data)
        DispatchQueue.main.async {
            self.files = filesResponse.files
        }
    }
    
    func uploadFile(fileData: Data, fileName: String) async throws {
        guard let token = userStore.token else {
            throw StorageError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/files/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Добавляем файл
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        bodyData.append(fileData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        // Добавляем имя файла
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append(fileName.data(using: .utf8)!)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw StorageError.uploadFailed
        }
        
        // Обновляем список файлов
        try await fetchFiles()
    }
    
    func deleteFile(fileId: String) async throws {
        guard let token = userStore.token else {
            throw StorageError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/files/\(fileId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.deleteFailed
        }
        
        // Обновляем список файлов
        try await fetchFiles()
    }
    
    func downloadFile(fileId: String) async throws -> Data {
        guard let token = userStore.token else {
            throw StorageError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/api/files/\(fileId)/download")!
        var request = URLRequest(url: url)
        request.setValue(" \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.downloadFailed
        }
        
        return data
    }
}

enum StorageError: Error {
    case unauthorized
    case serverError
    case uploadFailed
    case deleteFailed
    case downloadFailed
}

struct FileItem: Codable, Identifiable {
    let id: String
    let name: String
    let size: Int
    let createdAt: Date
    let mimeType: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case size
        case createdAt = "created_at"
        case mimeType = "mime_type"
        case url
    }
}

struct FilesResponse: Codable {
    let files: [FileItem]
} 
