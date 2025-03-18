import SwiftUI
import PhotosUI

struct MessageActionsView: View {
    let message: Message
    let chatId: Int
    @ObservedObject var chatStore: ChatStore
    @Binding var isEditing: Bool
    @Binding var editedContent: String
    @State private var showingFilePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                TextField("Edit message", text: $editedContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    Task {
                        do {
                            if let messageId = message.id {
                                try await chatStore.editMessage(messageId: messageId, newContent: editedContent)
                                isEditing = false
                            } else {
                                errorMessage = "Cannot edit message: Invalid message ID"
                                showingError = true
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    isEditing = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            } else {
                Button(action: {
                    editedContent = message.content
                    isEditing = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    Task {
                        do {
                            if let messageId = message.id {
                                try await chatStore.deleteMessage(messageId: messageId)
                            } else {
                                errorMessage = "Cannot delete message: Invalid message ID"
                                showingError = true
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                
                PhotosPicker(selection: $selectedItem,
                           matching: .any(of: [.images, .videos])) {
                    Image(systemName: "paperclip")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    do {
                        let fileName = newItem?.itemIdentifier ?? "file"
                        let fileId = try await chatStore.uploadFile(data, fileName: fileName, chatId: chatId)
                        try await chatStore.sendFile(fileId: fileId, chatId: chatId)
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        }
    }
} 