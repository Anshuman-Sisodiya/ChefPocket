import SwiftUI

struct CookModeView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var currentWhistles = 0
    @State private var targetWhistles = 3
    @State private var activeTimerSeconds = 0
    @State private var isTimerRunning = false
    @State private var timerName = ""
    @State private var timer: Timer? = nil
    
    // Recipe walkthrough
    @State private var selectedRecipeId: UUID? = nil
    @State private var currentStepIndex = 0
    
    private var activeRecipe: Recipe? {
        if let id = selectedRecipeId {
            return store.recipes.first(where: { $0.id == id })
        }
        return store.recipes.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // SECTION 1: Pressure Cooker Whistle Counter
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Pressure Cooker Whistle Counter", systemImage: "timer")
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
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(currentWhistles) / \(targetWhistles)")
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(currentWhistles >= targetWhistles ? .green : .orange)
                                
                                Text(currentWhistles >= targetWhistles ? "Target reached! Turn off flame." : "Waiting for cooker whistle...")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(currentWhistles >= targetWhistles ? .green : .secondary)
                            }
                            
                            Spacer()
                            
                            // Whistle Tap Button
                            Button(action: recordWhistle) {
                                VStack(spacing: 4) {
                                    Image(systemName: "bell.and.waveform.fill")
                                        .font(.title2)
                                    Text("TAP WHISTLE")
                                        .font(.caption2)
                                        .bold()
                                }
                                .foregroundColor(.white)
                                .frame(width: 100, height: 75)
                                .background(currentWhistles >= targetWhistles ? Color.green : Color.orange)
                                .cornerRadius(16)
                                .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                            
                            Button(action: resetWhistles) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 75)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                    
                    // SECTION 2: Desi Kitchen Quick Timers
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Desi Kitchen Quick Timers")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isTimerRunning {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(timerName)
                                        .font(.subheadline)
                                        .bold()
                                    Text(formatSeconds(activeTimerSeconds))
                                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                Button("Stop", action: stopTimer)
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.1)))
                            .padding(.horizontal)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
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
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // SECTION 3: Step-by-Step Countertop Cook Reader
                    if let recipe = activeRecipe {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("👨‍🍳 Countertop Reader")
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
                                    Text("Switch Recipe")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            Text(recipe.title)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.secondary)
                            
                            // Step Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Step \(currentStepIndex + 1) of \(recipe.instructions.count)")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                
                                Text(recipe.instructions[safe: currentStepIndex] ?? "Complete!")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .lineSpacing(6)
                                    .frame(minHeight: 80, alignment: .topLeading)
                                
                                // Step Navigators
                                HStack(spacing: 16) {
                                    Button(action: prevStep) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Text("Previous")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray5))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)
                                    }
                                    .disabled(currentStepIndex == 0)
                                    
                                    Button(action: nextStep) {
                                        HStack {
                                            Text(currentStepIndex < recipe.instructions.count - 1 ? "Next Step" : "Finished!")
                                            Image(systemName: "chevron.right")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Cook Mode")
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
    }
    
    private func resetWhistles() {
        currentWhistles = 0
    }
    
    private func startTimer(name: String, seconds: Int) {
        stopTimer()
        timerName = name
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
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
    
    private func formatSeconds(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func nextStep() {
        if let recipe = activeRecipe, currentStepIndex < recipe.instructions.count - 1 {
            currentStepIndex += 1
        }
    }
    
    private func prevStep() {
        if currentStepIndex > 0 {
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
            .frame(width: 110, height: 70)
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)))
        }
        .buttonStyle(.plain)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
