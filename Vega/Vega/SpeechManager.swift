import Foundation
import Speech
import AVFoundation
import Combine
// MARK: - SpeechManager
@MainActor
final class SpeechManager: NSObject, ObservableObject {

    @Published var transcript:      String  = ""
    @Published var isListening:     Bool    = false
    @Published var isSpeaking:      Bool    = false
    @Published var permissionError: String? = nil

    private let speechRecognizer   = SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask:    SFSpeechRecognitionTask?
    private let audioEngine        = AVAudioEngine()

    private let synthesizer = AVSpeechSynthesizer()
    private var ttsDelegate: TTSDelegate?

    override init() {
        super.init()
        ttsDelegate = TTSDelegate(manager: self)
        synthesizer.delegate = ttsDelegate
    }

    // MARK: - STT: Start
    func startListening() {
        guard !isListening else { return }

        // 1. Verify recognizer exists and Spanish locale is supported
        guard let recognizer = speechRecognizer else {
            permissionError = "El reconocimiento de voz en español no está disponible en este dispositivo."
            return
        }

        // 2. Verify service is currently available (requires internet first time,
        //    then works partially offline on device)
        guard recognizer.isAvailable else {
            permissionError = "El reconocimiento de voz no está disponible ahora. Verifica tu conexión a internet."
            return
        }

        // 3. Request user permission
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch status {
                case .authorized:
                    self.beginRecognition()
                case .denied:
                    self.permissionError = "Activa el reconocimiento de voz en Ajustes > Privacidad y seguridad > Reconocimiento de voz."
                case .restricted:
                    self.permissionError = "Reconocimiento de voz restringido en este dispositivo."
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func beginRecognition() {
        stopListening()

        // Configure audio session for recording
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            permissionError = "No se pudo activar el micrófono: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        // Allow offline recognition when available on device (iOS 13+)
        recognitionRequest.requiresOnDeviceRecognition = false

        let inputNode = audioEngine.inputNode

        // Use native input format — outputFormat(forBus:) returns sampleRate=0
        // on simulator and causes an assert crash. inputFormat is always valid
        // on a real device with a microphone.
        let nativeFormat = inputNode.inputFormat(forBus: 0)

        guard nativeFormat.sampleRate > 0, nativeFormat.channelCount > 0 else {
            permissionError = "El micrófono no está disponible. Prueba en un dispositivo físico."
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            permissionError = "Error iniciando audio: \(error.localizedDescription)"
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stopListening()
                }
            }
        }

        isListening = true
    }

    // MARK: - STT: Stop
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask    = nil
        isListening        = false

        // Restore session for TTS playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - TTS: Speak
    func speak(_ text: String, rate: Float = 0.42) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance             = AVSpeechUtterance(string: text)
        utterance.voice           = bestSpanishVoice()
        utterance.rate            = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume          = 1.0
        utterance.preUtteranceDelay  = 0.1
        utterance.postUtteranceDelay = 0.2

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func speakStep(title: String, steps: [String]) {
        speak("\(title). \(steps.joined(separator: ". ")).", rate: 0.40)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .word)
        isSpeaking = false
    }

    func toggleSpeaking(text: String) {
        isSpeaking ? stopSpeaking() : speak(text)
    }

    // MARK: - Helpers
    private func bestSpanishVoice() -> AVSpeechSynthesisVoice? {
        // Prefer Mexican Spanish, fall back to any Spanish variant
        let preferred = ["es-MX", "es-ES", "es-US"]
        for locale in preferred {
            if let voice = AVSpeechSynthesisVoice(language: locale) { return voice }
        }
        return AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("es") }
    }
}

// MARK: - TTSDelegate
private final class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate {
    weak var manager: SpeechManager?
    init(manager: SpeechManager) { self.manager = manager }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.manager?.isSpeaking = false }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in self?.manager?.isSpeaking = false }
    }
}
