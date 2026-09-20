import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showingImportSheet = false
    @State private var detectedClipboardURL: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                // Clipboard Detection Banner
                if let detectedURL = detectedClipboardURL {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Link Found in Clipboard")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(detectedURL)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Button("Import") {
                                withAnimation {
                                    store.addFromURL(detectedURL)
                                    detectedClipboardURL = nil
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .font(.caption)
                            .bold()
                            
                            Button(action: {
                                withAnimation {
                                    detectedClipboardURL = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Quick Actions
                Section {
                    Button(action: { showingImportSheet = true }) {
                        Label("Import from YouTube / Reels", systemImage: "link.badge.plus")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                
                // Recipe List
                Section(header: Text("My Saved Recipes (\(store.recipes.count))")) {
                    if store.recipes.isEmpty {
                        Text("No recipes saved yet. Import a recipe link above!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(store.recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRowView(recipe: recipe)
                            }
                        }
                        .onDelete(perform: store.deleteRecipe)
                    }
                }
            }
            .navigationTitle("ChefPocket")
            .sheet(isPresented: $showingImportSheet) {
                ImportRecipeModal(isPresented: $showingImportSheet)
            }
            .onAppear {
                checkClipboard()
            }
            .refreshable {
                checkClipboard()
            }
        }
    }
    
    private func checkClipboard() {
        if let string = UIPasteboard.general.string {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if (trimmed.contains("youtube.com") || trimmed.contains("youtu.be") || trimmed.contains("instagram.com")) &&
                !store.recipes.contains(where: { $0.sourceURL == trimmed }) {
                detectedClipboardURL = trimmed
            }
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            HStack(spacing: 14) {
                Label("\(recipe.proteinGrams)g Protein", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Label("\(recipe.calories) kcal", systemImage: "bolt.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Label("\(recipe.prepTimeMinutes)m", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @State private var multiplier: Double = 1.0
    
    // Get live instance from store for toggle updates
    private var liveRecipe: Recipe {
        store.recipes.first(where: { $0.id == recipe.id }) ?? recipe
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Macro Card
                HStack(spacing: 12) {
                    MacroPill(label: "Protein", val: "\(Int(Double(liveRecipe.proteinGrams) * multiplier))g", color: .orange)
                    MacroPill(label: "Calories", val: "\(Int(Double(liveRecipe.calories) * multiplier)) kcal", color: .green)
                    MacroPill(label: "Time", val: "\(liveRecipe.prepTimeMinutes)m", color: .blue)
                }
                .padding(.horizontal)
                
                // Serving Scaler
                VStack(alignment: .leading, spacing: 6) {
                    Text("Servings: \(Int(multiplier))x")
                        .font(.subheadline)
                        .bold()
                    Picker("Scale", selection: $multiplier) {
                        Text("1x").tag(1.0)
                        Text("2x").tag(2.0)
                        Text("4x").tag(4.0)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                // Ingredients Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Ingredients")
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("Tap to check off")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(liveRecipe.ingredients) { ing in
                        Button(action: {
                            store.toggleIngredient(recipeId: liveRecipe.id, ingredientId: ing.id)
                        }) {
                            HStack {
                                Image(systemName: ing.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(ing.isChecked ? .orange : .secondary)
                                    .font(.title3)
                                
                                Text(ing.name)
                                    .strikethrough(ing.isChecked)
                                    .foregroundColor(ing.isChecked ? .secondary : .primary)
                                
                                Spacer()
                                
                                Text("\(String(format: "%.1f", ing.amount * multiplier)) \(ing.unit)")
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
                .padding(.horizontal)
                
                // Instructions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Step-by-Step Instructions")
                        .font(.title2)
                        .bold()
                    
                    ForEach(Array(liveRecipe.instructions.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(idx + 1)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.orange))
                            
                            Text(step)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                
                // Source Link Button
                if let sourceURL = liveRecipe.sourceURL, let url = URL(string: sourceURL) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                            Text("Watch Original Video")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .foregroundColor(.orange)
                        .font(.headline)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(liveRecipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    store.toggleFavorite(recipeId: liveRecipe.id)
                }) {
                    Image(systemName: liveRecipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct MacroPill: View {
    let label: String
    let val: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(val)
                .font(.headline)
                .bold()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
    }
}

struct ImportRecipeModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var store: RecipeStore
    @State private var inputURL = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Paste Video Link")) {
                    TextField("https://youtube.com/shorts/... or Reels", text: $inputURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                
                Section {
                    Button(action: {
                        if !inputURL.isEmpty {
                            store.addFromURL(inputURL)
                            isPresented = false
                        }
                    }) {
                        Text("Extract Recipe")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                            .foregroundColor(inputURL.isEmpty ? .secondary : .orange)
                    }
                    .disabled(inputURL.isEmpty)
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }
}
