import SwiftUI
import SwiftData
 
struct CrisisModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [ChildProfile]
 
    @StateObject private var speech = SpeechManager()
 
    @State private var inputText     = ""
    @State private var detectedType: MeltdownType?
    @State private var currentStep   = 0
    @State private var phase: Phase  = .input
    @State private var autoSpeak     = false
 
    enum Phase { case input, steps, done }
 
    private var profile: ChildProfile? { profiles.first }
    private var crisisSteps: [(title: String, steps: [String])] {
        SuggestionService.shared.crisisSteps(for: detectedType ?? .sobreestimulacion)
    }
 
    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .input: inputPhase
                case .steps: stepsPhase
                case .done:  donePhase
                }
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { closeButton }
            .onDisappear {
                speech.stopListening()
                speech.stopSpeaking()
            }
            .alert("Permiso de micrófono", isPresented: .constant(speech.permissionError != nil)) {
                Button("Entendido") { speech.permissionError = nil }
            } message: {
                Text(speech.permissionError ?? "")
            }
        }
    }
 
    // MARK: - Toolbar
    private var closeButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cerrar") {
                speech.stopListening()
                speech.stopSpeaking()
                dismiss()
            }
            .foregroundColor(Theme.primary)
        }
    }
 
    // MARK: ─── PHASE 1: Input ───────────────────────────────────────────────
    private var inputPhase: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
 
                VStack(alignment: .leading, spacing: 6) {
                    Text("Modo Crisis")
                        .font(Theme.titleFont()).foregroundColor(Theme.textPrimary)
                    Text("Describe lo que está pasando o dicta por voz")
                        .font(Theme.bodyFont()).foregroundColor(Theme.textSecondary)
                }
 
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $inputText)
                        .font(Theme.bodyFont())
                        .frame(minHeight: 110)
                        .padding(12)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerM).stroke(
                            speech.isListening ? Theme.danger : Theme.border,
                            lineWidth: speech.isListening ? 2 : 1))
 
                    if inputText.isEmpty && !speech.isListening {
                        Text("Ej: mucho ruido, empezó a llorar y se tapaba los oídos...")
                            .font(Theme.bodyFont())
                            .foregroundColor(Theme.textTertiary)
                            .padding(20)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: speech.transcript) { _, new in
                    if !new.isEmpty { inputText = new }
                }
 
                MicButton(isListening: speech.isListening) {
                    if speech.isListening {
                        speech.stopListening()
                    } else {
                        speech.transcript = ""
                        speech.startListening()
                    }
                }
 
                VStack(alignment: .leading, spacing: 10) {
                    Text("O selecciona el tipo directamente:")
                        .font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
 
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(MeltdownType.allCases) { type in
                            Button {
                                speech.stopListening()
                                detectedType = type
                                withAnimation { phase = .steps }
                                if autoSpeak { speakCurrentStep() }
                            } label: {
                                HStack(spacing: 6) {
//                                    Text(type.icon)
                                    Image(systemName: type.icon)
                                        .foregroundColor(Theme.color(for: type))
                                    Text(type.displayName)
                                        .font(Theme.bodyFont(14)).foregroundColor(Theme.textPrimary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))
                                .overlay(RoundedRectangle(cornerRadius: Theme.cornerS)
                                    .stroke(Theme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
 
                Toggle(isOn: $autoSpeak) {
                    Label("Leer pasos en voz alta", systemImage: "speaker.wave.2.fill")
                        .font(Theme.bodyFont(14)).foregroundColor(Theme.textPrimary)
                }
                .tint(Theme.primary)
                .padding(.vertical, 4)
 
                Spacer(minLength: 12)
 
                PrimaryButton(title: "Analizar y ver pasos", icon: "wand.and.sparkles") {
                    speech.stopListening()
                    let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    detectedType = text.isEmpty
                        ? .sobreestimulacion
                        : MLService.shared.classify(text: text)
                    withAnimation { phase = .steps }
                    if autoSpeak { speakCurrentStep() }
                }
 
                Spacer(minLength: Theme.spacingL)
            }
            .padding(Theme.spacingM)
        }
    }
 
    // MARK: ─── PHASE 2: Steps ───────────────────────────────────────────────
    private var stepsPhase: some View {
        VStack(alignment: .leading, spacing: 0) {
 
            VStack(alignment: .leading, spacing: 4) {
                Text("Modo Crisis").font(Theme.titleFont()).foregroundColor(Theme.textPrimary)
                Text("Sigue estos pasos con calma y suavidad")
                    .font(Theme.bodyFont()).foregroundColor(Theme.textSecondary)
            }
            .padding(Theme.spacingM)
 
            HStack(spacing: 12) {
                if let type = detectedType { TypeBadge(type: type) }
                Spacer()
                Button {
                    autoSpeak.toggle()
                    if autoSpeak { speakCurrentStep() } else { speech.stopSpeaking() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: autoSpeak ? "speaker.wave.2.fill" : "speaker.slash")
                            .font(.system(size: 14))
                        Text(autoSpeak ? "Voz activa" : "Voz desactivada")
                            .font(Theme.captionFont(12))
                    }
                    .foregroundColor(autoSpeak ? Theme.primary : Theme.textSecondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(autoSpeak ? Theme.primaryLight : Theme.surface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.spacingM)
 
            HStack(spacing: 6) {
                ForEach(0..<crisisSteps.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(i <= currentStep ? Theme.blue : Theme.blueligth)
                        .frame(height: 6)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .padding(Theme.spacingM)
 
            Text("Paso \(currentStep + 1) de \(crisisSteps.count)")
                .font(Theme.captionFont()).foregroundColor(Theme.textSecondary)
                .padding(.horizontal, Theme.spacingM)
 
            ScrollView {
                VStack(spacing: Theme.spacingM) {
 
                    let step = crisisSteps[currentStep]
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            Text(step.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                            SpeakButton(isSpeaking: speech.isSpeaking) {
                                speech.isSpeaking ? speech.stopSpeaking() : speakCurrentStep()
                            }
                        }
 
                        VStack(spacing: 10) {
                            ForEach(step.steps, id: \.self) { instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle().fill(Theme.blue).frame(width: 8, height: 8).padding(.top, 6)
                                    Text(instruction)
                                        .font(Theme.bodyFont()).foregroundColor(Theme.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerS))
                            }
                        }
 
                        Button {
                            withAnimation {
                                if currentStep < crisisSteps.count - 1 {
                                    currentStep += 1
                                    if autoSpeak { speakCurrentStep() }
                                } else {
                                    speech.stopSpeaking()
                                    phase = .done
                                }
                            }
                        } label: {
                            HStack {
                                Text(currentStep < crisisSteps.count - 1 ? "Siguiente paso" : "Finalizar")
                                    .font(Theme.headlineFont())
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(Theme.blue)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
                        }
                    }
                    .padding(Theme.spacingM)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerL))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerL).stroke(Theme.border, lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
 
                    if currentStep > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completado:").font(Theme.headlineFont(15)).foregroundColor(Theme.textPrimary)
                            ForEach(0..<currentStep, id: \.self) { i in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.blue)
                                    Text(crisisSteps[i].title)
                                        .font(Theme.bodyFont(14)).foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                        .padding(Theme.spacingM).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.blueligth)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
                    }
                }
                .padding(Theme.spacingM)
            }
        }
        .onAppear { if autoSpeak { speakCurrentStep() } }
    }
 
    // MARK: ─── PHASE 3: Done ────────────────────────────────────────────────
    private var donePhase: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()
            VStack(spacing: 16) {
                Circle().fill(Theme.successLight).frame(width: 90, height: 90)
                    .overlay(Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44)).foregroundColor(Theme.success))
 
                Text("Bien hecho").font(Theme.titleFont(26)).foregroundColor(Theme.textPrimary)
 
                Text("¿Quieres registrar este episodio para hacer seguimiento?")
                    .font(Theme.bodyFont()).foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .onAppear {
                speech.speak("Bien hecho. Seguiste todos los pasos.")
            }
 
            Spacer()
 
            VStack(spacing: 12) {
                PrimaryButton(title: "Registrar episodio", icon: "plus") {
                    saveCrisisEvent()
                    dismiss()
                }
                SecondaryButton(title: "Cerrar sin registrar") {
                    dismiss()
                }
            }
            .padding(Theme.spacingM)
        }
        .background(Color.white)
    }
 
    // MARK: - Save crisis event
    private func saveCrisisEvent() {
        let type = detectedType ?? .sobreestimulacion
        let event = MeltdownEvent(
            date: .now,
            triggers: [],
            behaviors: [],
            calmingStrategies: [],
            type: type,
            intensity: .moderado,
            durationMinutes: 10,
            notes: inputText.trimmingCharacters(in: .whitespacesAndNewlines),
            childProfileID: profile?.id
        )
        context.insert(event)
        do {
            try context.save()
            print("[Vera] ✅ Crisis guardada: \(type.displayName) — \(Date.now)")
        } catch {
            print("[Vera] ❌ Error al guardar crisis: \(error)")
        }
    }
 
    // MARK: - Helpers
    private func speakCurrentStep() {
        guard currentStep < crisisSteps.count else { return }
        let step = crisisSteps[currentStep]
        speech.speakStep(title: step.title, steps: step.steps)
    }
}
 
// MARK: - MicButton
private struct MicButton: View {
    let isListening: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isListening ? Theme.danger : Theme.primaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isListening ? .white : Theme.primary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(isListening ? "Escuchando…" : "Dictar por voz")
                        .font(Theme.headlineFont(15))
                        .foregroundColor(isListening ? Theme.danger : Theme.textPrimary)
                    Text(isListening ? "Toca para detener" : "Describe la situación en voz alta")
                        .font(Theme.captionFont(12))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(isListening ? Color(hex: "#FEF2F2") : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerM))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerM)
                .stroke(isListening ? Theme.danger : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
 
// MARK: - SpeakButton
private struct SpeakButton: View {
    let isSpeaking: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            Image(systemName: isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 18))
                .foregroundColor(isSpeaking ? Theme.textSecondary : Theme.blue)
                .frame(width: 36, height: 36)
                .background(isSpeaking ? Theme.surface : Theme.blueligth)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CrisisModeView()
}
