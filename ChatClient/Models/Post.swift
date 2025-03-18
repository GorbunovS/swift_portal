import Foundation

struct Post: Identifiable, Codable {
    let id: Int
    let title: String
    let text: String
    let author: String
    let date: String
} 