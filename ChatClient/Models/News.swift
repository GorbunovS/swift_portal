struct News: Identifiable, Codable {
    let id: Int
    let title: String
    let content: String
    let fileUrl: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case fileUrl = "file_url"
        case createdAt = "created_at"
    }
} 
