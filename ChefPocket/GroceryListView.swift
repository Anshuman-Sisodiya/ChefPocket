import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var store: RecipeStore
    @ObservedObject var languageManager = LanguageManager.shared
    
    @State private var showingAddSheet = false
    @State private var newItemName = ""
    @State private var newItemAmount = "1 pack"
    @State private var newItemCategory: GroceryCategory = .sabziMandi
    @State private var showingShareSheet = false
    @State private var searchText = ""
    
    private var pendingCount: Int {
        store.groceries.filter { !$0.isChecked }.count
    }
    
    private var completedCount: Int {
        store.groceries.filter { $0.isChecked }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Summary Bar
                    if !store.groceries.isEmpty {
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "basket.fill")
                                    .foregroundColor(.orange)
                                Text("\(pendingCount) to buy")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.12))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                            
                            if completedCount > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("\(completedCount) checked")
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.12))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                            }
                            
                            Spacer()
                            
                            if completedCount > 0 {
                                Button(action: {
                                    withAnimation { store.clearCompletedGroceries() }
                                }) {
                                    Text(languageManager.t("clear_checked"))
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 2. Empty State
                    if store.groceries.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "basket.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 40)
                            
                            VStack(spacing: 6) {
                                Text(languageManager.t("mandi_empty"))
                                    .font(.title3)
                                    .bold()
                                Text(languageManager.t("mandi_empty_sub"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                            }
                            
                            Button(action: { showingAddSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                    Text(languageManager.t("add_item"))
                                }
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        // 3. Category Groups (Aesthetic Cards)
                        VStack(spacing: 16) {
                            ForEach(GroceryCategory.allCases) { cat in
                                let items = store.groceries.filter { $0.category == cat }
                                if !items.isEmpty {
                                    VStack(alignment: .leading, spacing: 10) {
                                        // Category Header
                                        HStack {
                                            Label(cat.rawValue, systemImage: cat.icon)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(.primary)
                                            Spacer()
                                            let uncheck = items.filter { !$0.isChecked }.count
                                            Text(uncheck > 0 ? "\(uncheck) items" : "All bought! ✨")
                                                .font(.caption2)
                                                .foregroundColor(uncheck > 0 ? .secondary : .green)
                                        }
                                        
                                        // Items List
                                        VStack(spacing: 8) {
                                            ForEach(items) { item in
                                                Button(action: {
                                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                                    impact.impactOccurred()
                                                    withAnimation {
                                                        store.toggleGroceryItem(id: item.id)
                                                    }
                                                }) {
                                                    HStack(spacing: 12) {
                                                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                                            .foregroundColor(item.isChecked ? .green : Color(.systemGray3))
                                                            .font(.title3)
                                                        
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(item.name)
                                                                .font(.subheadline)
                                                                .strikethrough(item.isChecked)
                                                                .foregroundColor(item.isChecked ? .secondary : .primary)
                                                            
                                                            if let source = item.recipeSource {
                                                                Text("For: \(source)")
                                                                    .font(.caption2)
                                                                    .foregroundColor(.secondary)
                                                            }
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(item.amount)
                                                            .font(.caption)
                                                            .fontWeight(.medium)
                                                            .foregroundColor(item.isChecked ? .secondary : .orange)
                                                            .padding(.horizontal, 8)
                                                            .padding(.vertical, 3)
                                                            .background(Color(.systemGray6))
                                                            .clipShape(Capsule())
                                                    }
                                                    .contentShape(Rectangle())
                                                }
                                                .buttonStyle(.plain)
                                                
                                                if item.id != items.last?.id {
                                                    Divider()
                                                }
                                            }
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(languageManager.t("mandi_title"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !store.groceries.isEmpty {
                        Button(action: { showingShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Item Details")) {
                            TextField("Item name (e.g. Fresh Paneer, Kasuri Methi)", text: $newItemName)
                            TextField("Quantity (e.g. 250g, 1 bunch)", text: $newItemAmount)
                            
                            Picker("Category", selection: $newItemCategory) {
                                ForEach(GroceryCategory.allCases) { cat in
                                    Text(cat.rawValue).tag(cat)
                                }
                            }
                        }
                    }
                    .navigationTitle("Add Grocery Item")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                if !newItemName.isEmpty {
                                    store.addCustomGrocery(name: newItemName, amount: newItemAmount, category: newItemCategory)
                                    newItemName = ""
                                    showingAddSheet = false
                                }
                            }
                            .bold()
                            .disabled(newItemName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareActivityView(activityItems: [formattedGroceryList()])
            }
        }
    }
    
    private func formattedGroceryList() -> String {
        var text = "🛒 *ChefPocket Sabzi Mandi List*\n\n"
        for cat in GroceryCategory.allCases {
            let items = store.groceries.filter { $0.category == cat && !$0.isChecked }
            if !items.isEmpty {
                text += "*\(cat.rawValue)*:\n"
                for item in items {
                    text += "• \(item.name) (\(item.amount))\n"
                }
                text += "\n"
            }
        }
        return text
    }
}
