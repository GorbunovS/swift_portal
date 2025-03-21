import SwiftUI

struct MiniApp: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let icon: String
    let color: Color
    let count: String
    let route: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, icon, count, route, url
        case colorR, colorG, colorB, colorA
    }
    
    init(id: Int, name: String, description: String, icon: String, color: Color, count: String, route: String, url: String) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.count = count
        self.route = route
        self.url = url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        icon = try container.decode(String.self, forKey: .icon)
        count = try container.decode(String.self, forKey: .count)
        route = try container.decode(String.self, forKey: .route)
        url = try container.decode(String.self, forKey: .url)
        
        let r = try container.decode(Double.self, forKey: .colorR)
        let g = try container.decode(Double.self, forKey: .colorG)
        let b = try container.decode(Double.self, forKey: .colorB)
        let a = try container.decode(Double.self, forKey: .colorA)
        
        color = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(icon, forKey: .icon)
        try container.encode(count, forKey: .count)
        try container.encode(route, forKey: .route)
        try container.encode(url, forKey: .url)
        
        // Преобразование Color в компоненты для сохранения
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        
        try container.encode(r, forKey: .colorR)
        try container.encode(g, forKey: .colorG)
        try container.encode(b, forKey: .colorB)
        try container.encode(a, forKey: .colorA)
    }
}
