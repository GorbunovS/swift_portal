import SwiftUI

@main
struct ChatClientApp: App {
    @StateObject private var userStore = UserStore()
    @StateObject private var chatStore: ChatStore
    
    init() {
        let userStore = UserStore()
        _userStore = StateObject(wrappedValue: userStore)
        _chatStore = StateObject(wrappedValue: ChatStore(userStore: userStore))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userStore)
                .environmentObject(chatStore)
        }
    }
} 
