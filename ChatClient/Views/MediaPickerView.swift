import SwiftUI
import PhotosUI
import AVFoundation

struct MediaPickerView: View {
    @Binding var selectedMedia: [MediaAttachment]
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    @State private var showVoiceRecorder = false
    @State private var isRecording = false
    @State private var recordingSession: AVAudioSession?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var pickerType: PickerType = .none
    
    enum PickerType {
        case none
        case image
        case document
        case voice
    }
    
    var body: some View {
        VStack {
            if !selectedMedia.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedMedia) { media in
                            MediaPreviewItem(media: media) {
                                if let index = selectedMedia.firstIndex(where: { $0.id == media.id }) {
                                    selectedMedia.remove(at: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
            }
            
            // Показываем соответствующий пикер в зависимости от выбранного типа
            if pickerType == .image {
                ImagePickerView(selectedMedia: $selectedMedia, onClose: { pickerType = .none })
            } else if pickerType == .document {
                DocumentPickerView(selectedMedia: $selectedMedia, onClose: { pickerType = .none })
            } else if pickerType == .voice {
                VoiceRecorderView(selectedMedia: $selectedMedia, onClose: { pickerType = .none })
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedMedia: $selectedMedia)
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedMedia: $selectedMedia)
        }
    }
}

struct MediaPickerOverlay: View {
    @Binding var pickerType: MediaPickerView.PickerType
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                pickerType = .image
            }) {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Фото")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Button(action: {
                pickerType = .document
            }) {
                VStack {
                    Image(systemName: "doc")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Файл")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Button(action: {
                pickerType = .voice
            }) {
                VStack {
                    Image(systemName: "mic")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Голос")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct MediaPreviewItem: View {
    let media: MediaAttachment
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                if media.isImage {
                    if let uiImage = UIImage(data: media.data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    }
                } else if media.isAudio {
                    VStack {
                        Image(systemName: "waveform")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text(media.fileName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                } else {
                    VStack {
                        Image(systemName: "doc")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text(media.fileName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Показываем прогресс загрузки
                if case .uploading(let progress) = media.uploadState {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 80)
                } else if case .failed = media.uploadState {
                    Text("Ошибка")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
}

struct ImagePickerView: View {
    @Binding var selectedMedia: [MediaAttachment]
    let onClose: () -> Void
    @State private var showPhotoLibrary = false
    @State private var showCamera = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Выберите изображение")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: {
                    showCamera = true
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("Камера")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showPhotoLibrary = true
                }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                        Text("Галерея")
                            .font(.caption)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(selectedMedia: $selectedMedia, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedMedia: $selectedMedia, sourceType: .camera)
        }
    }
}

struct DocumentPickerView: View {
    @Binding var selectedMedia: [MediaAttachment]
    let onClose: () -> Void
    @State private var showDocumentPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Выберите файл")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            Button(action: {
                showDocumentPicker = true
            }) {
                VStack {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    Text("Выбрать файл")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(selectedMedia: $selectedMedia)
        }
    }
}

struct VoiceRecorderView: View {
    @Binding var selectedMedia: [MediaAttachment]
    let onClose: () -> Void
    
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var recordingSession: AVAudioSession?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(isRecording ? "Запись..." : "Голосовое сообщение")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            // Визуализация записи (упрощенная)
            HStack(spacing: 2) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 3, height: isRecording ? min(20, max(4, Double(index % 15) * 1.5)) : 4)
                        .foregroundColor(isRecording ? .blue : .gray.opacity(0.5))
                        .animation(.easeInOut(duration: 0.5), value: isRecording)
                }
            }
            .padding()
            
            // Время записи
            Text(formatTime(recordingTime))
                .font(.title2)
                .monospacedDigit()
            
            HStack(spacing: 40) {
                // Кнопка отмены
                Button(action: {
                    if isRecording {
                        stopRecording(save: false)
                    }
                    onClose()
                }) {
                    Text("Отмена")
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Кнопка записи/остановки
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 70, height: 70)
                        
                        if isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Кнопка сохранения
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        saveRecording()
                    }
                }) {
                    Text("Готово")
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .disabled(recordingURL == nil)
            }
            .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 5)
        .onAppear {
            setupAudioSession()
        }
        .onDisappear {
            if isRecording {
                stopRecording(save: false)
            }
        }
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            
            recordingSession?.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        // Показать сообщение о необходимости разрешения
                        print("Microphone access denied")
                    }
                }
            }
        } catch {
            print("Failed to set up recording session: \(error.localizedDescription)")
        }
    }
    
    private func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        recordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // Запускаем таймер для отслеживания времени записи
            recordingTime = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingTime += 0.1
            }
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording(save: Bool = true) {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        
        if !save {
            // Удаляем файл записи, если не нужно сохранять
            if let url = recordingURL {
                try? FileManager.default.removeItem(at: url)
                recordingURL = nil
            }
        }
    }
    
    private func saveRecording() {
        guard let url = recordingURL else { return }
        
        do {
            let audioData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            
            let media = MediaAttachment(
                type: .voice,
                data: audioData,
                fileName: fileName,
                fileSize: audioData.count
            )
            
            selectedMedia.append(media)
            onClose()
        } catch {
            print("Error saving recording: \(error.localizedDescription)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time - floor(time)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedMedia: [MediaAttachment]
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(selectedMedia: Binding<[MediaAttachment]>, sourceType: UIImagePickerController.SourceType = .photoLibrary) {
        self._selectedMedia = selectedMedia
        self.sourceType = sourceType
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            if let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 0.7) {
                let fileName = "image_\(Int(Date().timeIntervalSince1970)).jpg"
                
                DispatchQueue.main.async {
                    let media = MediaAttachment(
                        type: .image,
                        data: imageData,
                        fileName: fileName,
                        fileSize: imageData.count
                    )
                    self.parent.selectedMedia.append(media)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedMedia: [MediaAttachment]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            for url in urls {
                do {
                    let data = try Data(contentsOf: url)
                    let fileName = url.lastPathComponent
                    let fileSize = data.count
                    
                    let media = MediaAttachment(
                        type: .file,
                        data: data,
                        fileName: fileName,
                        fileSize: fileSize
                    )
                    
                    DispatchQueue.main.async {
                        self.parent.selectedMedia.append(media)
                    }
                } catch {
                    print("Error loading document: \(error.localizedDescription)")
                }
            }
        }
    }
}

