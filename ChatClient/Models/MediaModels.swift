import Foundation
import SwiftUI

// Модель для типов сообщений
enum MessageType: String, Codable {
    case text
    case image
    case file
    case voice
    case forwarded
}

// Модель для действий с сообщениями
enum MessageAction {
    case reply
    case forward
    case edit
    case delete
    case copy
}

// Модель для состояния загрузки медиа
enum MediaUploadState {
    case idle
    case uploading(progress: Float)
    case success(fileId: String)
    case failed(error: String)
}

// Модель для медиа-вложения
struct MediaAttachment: Identifiable {
    let id = UUID()
    let type: MessageType
    let data: Data
    let fileName: String
    let fileSize: Int
    var uploadState: MediaUploadState = .idle
    
    var fileExtension: String {
        return URL(fileURLWithPath: fileName).pathExtension
    }
    
    var isImage: Bool {
        return ["jpg", "jpeg", "png", "gif"].contains(fileExtension.lowercased())
    }
    
    var isAudio: Bool {
        return ["mp3", "wav", "m4a"].contains(fileExtension.lowercased())
    }
    
    var sizeString: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

// Расширение для Message для удобства работы
extension Message {
    var messageType: MessageType {
        if fileId != nil {
            if let fileUrl = fileUrl {
                if fileUrl.lowercased().contains(".jpg") ||
                   fileUrl.lowercased().contains(".jpeg") ||
                   fileUrl.lowercased().contains(".png") {
                    return .image
                } else if fileUrl.lowercased().contains(".mp3") ||
                          fileUrl.lowercased().contains(".wav") ||
                          fileUrl.lowercased().contains(".m4a") {
                    return .voice
                } else {
                    return .file
                }
            }
            return .file
        } else if content.hasPrefix("#Переслано от") {
            return .forwarded
        }
        return .text
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: createdAt)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: createdAt)
    }
    
    var fileName: String? {
        guard let fileUrl = fileUrl else { return nil }
        return URL(string: fileUrl)?.lastPathComponent
    }
}

// Делаем Message соответствующим протоколу Equatable
extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        // Сравниваем по ID, если он есть
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId == rhsId
        }
        
        // Если ID нет, сравниваем по содержимому и времени создания
        return lhs.content == rhs.content &&
               lhs.createdAt == rhs.createdAt &&
               lhs.userId == rhs.userId
    }
}

