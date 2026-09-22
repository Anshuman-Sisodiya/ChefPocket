import SwiftUI
import AuthenticationServices

// MARK: - User Profile & Settings View
struct UserProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var syncService = CloudSyncService.shared
    @ObservedObject var updateManager = UpdateManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var systemColorScheme
    
    @State private var name: String = ""
    @State private var dietaryPreference: DietType = .all
    @State private var apiKey: String = ""
    @State private var showingSaveAlert = false
    @State private var showingLogoutConfirm = false
    @State private var showingExportSheet = false
    @State private var exportURL: URL? = nil
    @State private var showingImportPicker = false
    @State private var showingImportAlert = false
    @State private var showingLanguageSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: User Account Header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 54, height: 54)
                            Text(avatarInitials)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(auth.currentUser?.name ?? "Guest Chef")
                                    .font(.headline)
                                if auth.currentUser?.isGoogleAccount == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                } else if auth.currentUser?.isAppleAccount == true {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.primary)
                                        .font(.caption)
                                }
                            }
                            Text(auth.currentUser?.email ?? "Not logged in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if auth.currentUser?.isGoogleAccount == true {
                                Text("Google Account Linked")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            } else if auth.currentUser?.isAppleAccount == true {
                                Text("Apple Account Linked")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Section 2: Software Updates (GitHub Releases)
                Section(header: Text("App Updates"), footer: Text("ChefPocket connects to GitHub Releases to provide latest feature builds.")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Version")
                                .font(.subheadline)
                            Text("v\(updateManager.currentVersion)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if updateManager.isChecking {
                            ProgressView()
                        } else {
                            Button("Check for Updates") {
                                updateManager.checkForUpdates(silent: false)
                            }
                            .font(.caption)
                            .bold()
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    if updateManager.isUpdateAvailable {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("New Version Available: v\(updateManager.latestVersion)")
                                    .font(.subheadline)
                                    .bold()
                            }
                            
                            HStack(spacing: 12) {
                                Button("Update via AltStore") {
                                    updateManager.installWithAltStore()
                                }
                                .font(.caption)
                                .bold()
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                
                                Button("Direct IPA Download") {
                                    updateManager.openDirectDownload()
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.vertical, 4)
                    } else if let msg = updateManager.errorMessage {
                        Text(msg)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section 3: Cloud Sync & Cross-Device Backup
                Section(header: Text(languageManager.t("cloud_sync")), footer: Text("All your custom recipes, favorites, and groceries sync automatically with your account.")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(syncService.syncStatus)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let last = syncService.lastSyncDate {
                                Text("Last synced: \(last.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        if syncService.isSyncing {
                            ProgressView()
                        } else {
                            Button(languageManager.t("sync_now")) {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                syncService.syncKitchenData(store: store, auth: auth)
                            }
                            .font(.caption)
                            .bold()
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    
                    if !syncService.syncSummary.isEmpty {
                        Text(syncService.syncSummary)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: exportKitchenBackup) {
                        Label("Export Kitchen Backup (.chefpocket)", systemImage: "square.and.arrow.up")
                            .font(.subheadline)
                    }
                }
                
                // Section 4: Appearance & Theme
                Section(header: Text(languageManager.t("theme")), footer: Text("ChefPocket syncs your interface appearance to your preference.")) {
                    Picker("Theme", selection: $themeManager.appTheme) {
                        Text(languageManager.t("theme_system")).tag("system")
                        Text(languageManager.t("theme_light")).tag("light")
                        Text(languageManager.t("theme_dark")).tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: themeManager.appTheme) { _ in
                        themeManager.syncAppIcon(systemIsDark: systemColorScheme == .dark)
                    }
                    
                    // Visual App Icon Preview Cards
                    HStack(spacing: 20) {
                        // Light Icon Preview
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [Color.orange.opacity(0.85), Color.red.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 58, height: 58)
                                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            Text("Amber Classic")
                                .font(.caption2)
                                .fontWeight(.medium)
                            if themeManager.appTheme != "dark" {
                                Text("Active")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            themeManager.appTheme = "light"
                            themeManager.setIconManually(useDark: false)
                        }
                        
                        // Dark Icon Preview
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(colors: [Color.black, Color(white: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 58, height: 58)
                                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                            }
                            Text("Obsidian Dark")
                                .font(.caption2)
                                .fontWeight(.medium)
                            if themeManager.appTheme == "dark" {
                                Text("Active")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            themeManager.appTheme = "dark"
                            themeManager.setIconManually(useDark: true)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if let status = themeManager.iconStatusMessage {
                        Text(status)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section 5: App Language
                Section(header: Text(languageManager.t("language")), footer: Text("Select your preferred language for all recipes, filters, and cooking guides.")) {
                    Picker("Language", selection: $languageManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text("\(lang.flag)  \(lang.displayName)")
                                .tag(lang)
                        }
                    }
                    
                    Button(action: { showingLanguageSheet = true }) {
                        HStack {
                            Text("Browse All Languages")
                                .font(.subheadline)
                            Spacer()
                            Text(languageManager.currentLanguage.shortName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Section 6: Profile Details
                Section(header: Text("Culinary Profile")) {
                    TextField("Full Name", text: $name)
                    
                    Picker("Dietary Preference", selection: $dietaryPreference) {
                        Text("All Dishes").tag(DietType.all)
                        Text("Pure Vegetarian").tag(DietType.veg)
                        Text("Non-Vegetarian").tag(DietType.nonVeg)
                    }
                }
                
                // Section 7: AI Video Extractor Settings
                Section(header: Text("AI Video Recipe Extractor"), footer: Text("Configure an optional custom Google Gemini API Key for high-frequency video extractions.")) {
                    SecureField("Google Gemini API Key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                // Section 8: Save & Log Out
                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                }
                
                Section {
                    Button(role: .destructive, action: { showingLogoutConfirm = true }) {
                        HStack {
                            Spacer()
                            Text(languageManager.t("logout"))
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(languageManager.t("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguageSelectionSheet(isPresented: $showingLanguageSheet)
            }
            .onAppear {
                name = auth.currentUser?.name ?? ""
                dietaryPreference = auth.currentUser?.dietaryPreference ?? store.selectedDiet
                apiKey = auth.currentUser?.geminiApiKey ?? ""
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareActivityView(activityItems: [url])
                }
            }
            .alert("Profile Updated", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your culinary preferences and settings have been saved.")
            }
            .confirmationDialog("Log Out", isPresented: $showingLogoutConfirm, titleVisibility: .visible) {
                Button("Log Out", role: .destructive) {
                    auth.logout()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to log out of your ChefPocket account?")
            }
        }
    }
    
    private var avatarInitials: String {
        guard let name = auth.currentUser?.name, !name.isEmpty else { return "CP" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    private func saveChanges() {
        auth.updateProfile(name: name, diet: dietaryPreference, apiKey: apiKey)
        store.selectedDiet = dietaryPreference
        showingSaveAlert = true
    }
    
    private func exportKitchenBackup() {
        let email = auth.currentUser?.email ?? "guest"
        if let url = syncService.exportBackup(store: store, email: email) {
            exportURL = url
            showingExportSheet = true
        }
    }
}

// MARK: - Dedicated Language Selection Sheet
struct LanguageSelectionSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationStack {
            List(AppLanguage.allCases) { lang in
                Button(action: {
                    languageManager.currentLanguage = lang
                    isPresented = false
                }) {
                    HStack(spacing: 14) {
                        Text(lang.flag)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(lang.shortName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if languageManager.currentLanguage == lang {
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
    }
}

// MARK: - Login & Sign Up Modal
struct AuthModalView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedDiet: DietType = .all
    @State private var errorMessage: String? = nil
    @State private var showingGoogleEmailPrompt = false
    @State private var googleEmailInput = ""
    @State private var googleNameInput = ""
    @State private var showingInstantProfileModal = false
    @State private var instantChefName = ""
    @State private var instantChefDiet: DietType = .all
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Top App Hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 72, height: 72)
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)
                        
                        Text("ChefPocket Kitchen")
                            .font(.title)
                            .bold()
                        
                        Text("Sync your custom recipes, favorite dishes, and grocery lists across all your devices.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Quick Action: Instant Kitchen Profile (No Server Needed)
                    Button(action: { showingInstantProfileModal = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("1-Tap Instant Chef Profile")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                    
                    // Official Sign In Options
                    VStack(spacing: 12) {
                        // 1. Google Sign-In (Direct Verified Linkage)
                        Button(action: { showingGoogleEmailPrompt = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "g.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.red)
                                Text("Sign in with Google Account")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color(.systemGray4), lineWidth: 1.5)
                                    )
                            )
                        }
                        .padding(.horizontal)
                        
                        // 2. Sign In With Apple (Native Biometric)
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                if auth.handleAppleSignIn(result: result) {
                                    CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                                    dismiss()
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(14)
                        .padding(.horizontal)
                        
                        HStack {
                            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                            Text("or with email")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    // Segmented Mode
                    Picker("Auth Mode", selection: $isSignUp) {
                        Text("Log In").tag(false)
                        Text("Create Account").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Form Fields
                    VStack(spacing: 14) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("e.g. Anshuman", text: $name)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            TextField("name@example.com", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Dietary Preference")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                Picker("Diet", selection: $selectedDiet) {
                                    Text("All Dishes").tag(DietType.all)
                                    Text("Pure Vegetarian").tag(DietType.veg)
                                    Text("Non-Vegetarian").tag(DietType.nonVeg)
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        
                        if let err = errorMessage ?? auth.authErrorMessage {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: handleAuth) {
                            Text(isSignUp ? "Create Free Account" : "Log In")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button("Continue as Guest") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Sign in with Google Account", isPresented: $showingGoogleEmailPrompt) {
                TextField("Google Email (e.g. chef@gmail.com)", text: $googleEmailInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Your Full Name (optional)", text: $googleNameInput)
                Button("Link Google Account") {
                    if auth.loginWithVerifiedGoogleAccount(email: googleEmailInput, name: googleNameInput) {
                        CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter your Google Account email to sync your custom recipes, favorites, and groceries safely on device.")
            }
            .sheet(isPresented: $showingInstantProfileModal) {
                NavigationStack {
                    Form {
                        Section(header: Text("Chef Profile Details"), footer: Text("Instant local profile for meal planning and kitchen organization without password setup.")) {
                            TextField("Your Name (e.g. Anshuman)", text: $instantChefName)
                            
                            Picker("Dietary Preference", selection: $instantChefDiet) {
                                Text("All Dishes").tag(DietType.all)
                                Text("Pure Vegetarian").tag(DietType.veg)
                                Text("Non-Vegetarian").tag(DietType.nonVeg)
                            }
                        }
                        
                        Section {
                            Button("Start Cooking") {
                                _ = auth.createInstantChefProfile(name: instantChefName, diet: instantChefDiet)
                                store.selectedDiet = instantChefDiet
                                CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                                showingInstantProfileModal = false
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundColor(.orange)
                        }
                    }
                    .navigationTitle("Instant Chef Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingInstantProfileModal = false }
                        }
                    }
                }
            }
        }
    }
    
    private func handleAuth() {
        errorMessage = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        if isSignUp {
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please enter your name."
                return
            }
            let success = auth.signUp(name: name, email: cleanEmail, password: password, diet: selectedDiet)
            if success {
                CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                dismiss()
            } else {
                errorMessage = auth.authErrorMessage ?? "Could not create account. Please check your details."
            }
        } else {
            let success = auth.login(email: cleanEmail, password: password)
            if success {
                CloudSyncService.shared.syncKitchenData(store: store, auth: auth)
                dismiss()
            } else {
                errorMessage = auth.authErrorMessage ?? "Invalid credentials. Please try again."
            }
        }
    }
}
