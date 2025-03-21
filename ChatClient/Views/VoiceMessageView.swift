import SwiftUI
import AVFoundation

struct VoiceMessageView: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: {
                    if isPlaying {
                        pauseAudio()
                    } else {
                        playAudio()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(isFromCurrentUser ? .white : .blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Визуализация аудио (волны)
                    HStack(spacing: 2) {
                        ForEach(0..<30, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .frame(width: 3, height: min(20, max(4, Double(index % 15) * 1.5)))
                                .foregroundColor(
                                    isFromCurrentUser ? 
                                    (progress > Double(index) / 30 ? Color.white : Color.white.opacity(0.5)) :
                                    (progress > Double(index) / 30 ? Color.blue : Color.gray.opacity(0.5))
                                )
                        }
                    }
                    
                    // Время воспроизведения
                    Text(formatTime(duration * progress) + " / " + formatTime(duration))
                        .font(.caption)
                        .foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : .gray)
                }
            }
        }
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            stopAudio()
        }
    }
    
    private func loadAudio() {
        guard let fileUrl = message.fileUrl, let url = URL(string: fileUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error loading audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.prepareToPlay()
                    self.duration = self.audioPlayer?.duration ?? 0
                } catch {
                    print("Error creating audio player: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    private func playAudio() {
        guard let player = audioPlayer else { return }
        
        player.play()
        isPlaying = true
        
        // Создаем таймер для обновления прогресса
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                progress = player.currentTime / player.duration
                
                if !player.isPlaying {
                    stopAudio()
                }
            }
        }
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        progress = 0
        timer?.invalidate()
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

