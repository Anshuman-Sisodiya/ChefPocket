import SwiftUI

struct CookModeView: View {
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var languageManager = LanguageManager.shared
    
    // Whistle Counter State
    @State private var currentWhistles = 0
    @State private var targetWhistles = 3
    
    // Kitchen Timer State
    @State private var activeTimerSeconds = 0
    @State private var initialTimerSeconds = 0
    @State private var isTimerRunning = false
    @State private var timerName = ""
    @State private var timer: Timer? = nil
    
    // Countertop Reader State
    @State private var selectedRecipeId: UUID? = nil
    @State private var currentStepIndex = 0
    
    private var activeRecipe: Recipe? {
        if let id = selectedRecipeId {
            return store.recipes.first(where: { $0.id == id })
        }
        return store.recipes.first
    }
    
    private var cleanInstructions: [String] {
        guard let r = activeRecipe else { return ["Prepare ingredients and cook."] }
        let filtered = r.instructions.filter { step in
            let lower = step.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            return !lower.starts(with: "extracted from") &&
                   !lower.starts(with: "source:") &&
                   !lower.contains("youtube.com") &&
                   !lower.contains("youtu.be") &&
                   !lower.contains("instagram.com")
        }
        return filtered.isEmpty ? ["Prepare ingredients, cook with spices, and serve hot."] : filtered
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // SECTION 1: Whistle Counter Circular Ring
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label(languageManager.t("whistle_counter"), systemImage: "timer")
                                .font(.headline)
                            Spacer()
                            Picker("Target", selection: $targetWhistles) {
                                ForEach(1...8, id: \.self) { num in
                                    Text("\(num) Whistles").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.orange)
                        }
                        
                        HStack(spacing: 24) {
                            // Circular Progress Indicator
                            ZStack {
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 8)
                                    .frame(width: 84, height: 84)
                                
                                Circle()
                                    .trim(from: 0, to: min(CGFloat(currentWhistles) / CGFloat(targetWhistles), 1.0))
                                    .stroke(
                                        currentWhistles >= targetWhistles ? Color.green : Color.orange,
                                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 84, height: 84)
                                    .animation(.spring(), value: currentWhistles)
                                
                                VStack(spacing: 0) {
                                    Text("\(currentWhistles)")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundColor(currentWhistles >= targetWhistles ? .green : .primary)
                                    Text("of \(targetWhistles)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentWhistles >= targetWhistles ? languageManager.t("whistle_done") : languageManager.t("waiting_whistle"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(currentWhistles >= targetWhistles ? .green : .primary)
                                    .lineLimit(2)
                                
                                Text("Whistles count toward pressure cooking.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: recordWhistle) {
                                HStack(spacing: 8) {
                                    Image(systemName: "bell.and.waveform.fill")
                                    Text(languageManager.t("tap_whistle"))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(currentWhistles >= targetWhistles ? Color.green : Color.orange)
                                .cornerRadius(14)
                                .shadow(color: (currentWhistles >= targetWhistles ? Color.green : Color.orange).opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                            
                            Button(action: resetWhistles) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, height: 50)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(14)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    
                    // SECTION 2: Desi Kitchen Quick Timers
                    VStack(alignment: .leading, spacing: 14) {
                        Text(languageManager.t("desi_timers"))
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Active Countdown Banner if running
                        if activeTimerSeconds > 0 || isTimerRunning {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(timerName)
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.orange)
                                    Text(formatSeconds(activeTimerSeconds))
                                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Button(action: {
                                        if isTimerRunning { stopTimer() } else { resumeTimer() }
                                    }) {
                                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(Color.orange)
                                            .clipShape(Circle())
                                    }
                                    
                                    Button(action: resetTimer) {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 36, height: 36)
                                            .background(Color(.systemGray6))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.orange.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal)
                        }
                        
                        // Quick Presets Carousel
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                QuickTimerButton(title: "Tadka", subtitle: "45s", icon: "flame.fill", color: .red) {
                                    startTimer(name: "Tadka Splutter", seconds: 45)
                                }
                                QuickTimerButton(title: "Bhunao", subtitle: "7m", icon: "frying.pan.fill", color: .orange) {
                                    startTimer(name: "Onion Masala Bhunao", seconds: 420)
                                }
                                QuickTimerButton(title: "Dal Boil", subtitle: "10m", icon: "bowl.fill", color: .green) {
                                    startTimer(name: "Dal Simmer Boil", seconds: 600)
                                }
                                QuickTimerButton(title: "Dum", subtitle: "15m", icon: "sparkles", color: .blue) {
                                    startTimer(name: "Low Flame Dum", seconds: 900)
                                }
                                QuickTimerButton(title: "Chai Boil", subtitle: "3m", icon: "cup.and.saucer.fill", color: .brown) {
                                    startTimer(name: "Masala Chai Boil", seconds: 180)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // SECTION 3: Step-by-Step Countertop Cook Reader
                    if let recipe = activeRecipe {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text(languageManager.t("countertop_reader"))
                                    .font(.headline)
                                Spacer()
                                Menu {
                                    ForEach(store.recipes) { r in
                                        Button(r.title) {
                                            selectedRecipeId = r.id
                                            currentStepIndex = 0
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("Switch Recipe")
                                            .font(.caption)
                                            .bold()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 9))
                                    }
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                            
                            HStack(spacing: 8) {
                                FSSAIBadge(diet: recipe.diet, size: 12)
                                Text(recipe.title)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // High-legibility Step Card
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Text(String(format: languageManager.t("step_of"), currentStepIndex + 1, cleanInstructions.count))
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.orange)
                                    Spacer()
                                    // Step progress bar
                                    ProgressView(value: Double(currentStepIndex + 1), total: Double(max(cleanInstructions.count, 1)))
                                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                                        .frame(width: 80)
                                }
                                
                                Text(cleanInstructions[safe: currentStepIndex] ?? languageManager.t("finished_cooking"))
                                    .font(.system(size: 20, weight: .medium))
                                    .lineSpacing(6)
                                    .frame(minHeight: 90, alignment: .topLeading)
                                
                                // Step Navigators
                                HStack(spacing: 14) {
                                    Button(action: prevStep) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text(languageManager.t("prev_step"))
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(currentStepIndex == 0 ? .secondary : .primary)
                                        .cornerRadius(12)
                                    }
                                    .disabled(currentStepIndex == 0)
                                    
                                    Button(action: nextStep) {
                                        HStack {
                                            Text(currentStepIndex < cleanInstructions.count - 1 ? languageManager.t("next_step") : languageManager.t("finished_cooking"))
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color(.systemGray5), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(languageManager.t("cookmode_title"))
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true // Keep screen awake while cooking!
            }
            .onDisappear {
                UIApplication.shared.isIdleTimerDisabled = false
                timer?.invalidate()
            }
        }
    }
    
    private func recordWhistle() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        currentWhistles += 1
        if currentWhistles == targetWhistles {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
    
    private func resetWhistles() {
        currentWhistles = 0
    }
    
    private func startTimer(name: String, seconds: Int) {
        stopTimer()
        timerName = name
        initialTimerSeconds = seconds
        activeTimerSeconds = seconds
        isTimerRunning = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if activeTimerSeconds > 0 {
                activeTimerSeconds -= 1
            } else {
                stopTimer()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private func resumeTimer() {
        guard activeTimerSeconds > 0 else { return }
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if activeTimerSeconds > 0 {
                activeTimerSeconds -= 1
            } else {
                stopTimer()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
    
    private func resetTimer() {
        stopTimer()
        activeTimerSeconds = 0
        timerName = ""
    }
    
    private func formatSeconds(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func nextStep() {
        if currentStepIndex < cleanInstructions.count - 1 {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            currentStepIndex += 1
        }
    }
    
    private func prevStep() {
        if currentStepIndex > 0 {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            currentStepIndex -= 1
        }
    }
}

struct QuickTimerButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                    Text(subtitle)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                }
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.primary)
            }
            .frame(width: 105, height: 68)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
