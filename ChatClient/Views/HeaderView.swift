import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var userStore: UserStore
    @State private var showProfileMenu = false
    @State private var showEditProfile = false
    
    var body: some View {
        HStack {
            // Логотип приложения
            Image("logo_white")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .foregroundColor(.white)
                .padding(.leading, 16)
            
            Spacer()
            
            // Правая часть с уведомлениями и профилем
            HStack(spacing: 16) {
                // Иконка уведомлений
                Image(systemName: "bell")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.primary)
                
                // Профиль пользователя
                Button(action: {
                    withAnimation {
                        showProfileMenu.toggle()
                    }
                }) {
                    HStack {
                        if userStore.avatarId.isEmpty {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.blue)
                        } else {
                            // Здесь должна быть загрузка аватара
                            ProfileImage(avatarId: userStore.avatarId)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text(userStore.fullName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Online")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .popover(isPresented: $showProfileMenu, arrowEdge: .top) {
                    VStack(spacing: 10) {
                        Button(action: {
                            showProfileMenu = false
                            showEditProfile = true
                        }) {
                            Label("Edit Profile", systemImage: "person.crop.circle")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Divider()
                        
                        Button(action: {
                            userStore.logout()
                            showProfileMenu = false
                        }) {
                            Label("Logout", systemImage: "arrow.right.square")
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical)
                    .frame(width: 200)
                }
            }
            .padding(.trailing, 16)
        }
        .frame(height: 60)
        .background(Color(.systemGray6))
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
    }
}

struct ProfileImage: View {
    let avatarId: String
    @EnvironmentObject private var userStore: UserStore
    @State private var imageData: Data?
    
    var body: some View {
        Group {
            if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
            userStore.getImage(fileId: avatarId) { data in
                if let data = data {
                    DispatchQueue.main.async {
                        self.imageData = data
                    }
                }
            }
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
            .environmentObject(UserStore())
    }
} 