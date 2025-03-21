import SwiftUI

struct MessageView: View {
    let message: Message
    let chatId: Int
    @ObservedObject var chatStore: ChatStore
    @State private var isEditing = false
    @State private var editedContent = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                
                // Сообщение от текущего пользователя
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading, 60)
            } else {
                // Сообщение от другого пользователя
                VStack(alignment: .leading, spacing: 4) {
                    Text(senderName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(message.content)
                        .padding()
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 60)
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    private var senderName: String {
        if let user = chatStore.users.first(where: { $0.id == message.userId }) {
            return "\(user.firstName) \(user.lastName)"
        } else {
            return "Неизвестный пользователь"
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.createdAt)
    }
} 
