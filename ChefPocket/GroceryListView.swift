import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showingAddSheet = false
    @State private var newItemName = ""
    @State private var newItemAmount = "1 pack"
    @State private var newItemCategory: GroceryCategory = .sabziMandi
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                if store.groceries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "basket.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange.opacity(0.6))
                        Text("Your Sabzi Mandi List is Empty")
                            .font(.headline)
                        Text("Add items from your favorite recipes or add custom items below!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    // Group by GroceryCategory
                    ForEach(GroceryCategory.allCases) { cat in
                        let items = store.groceries.filter { $0.category == cat }
                        if !items.isEmpty {
                            Section(header: Label(cat.rawValue, systemImage: cat.icon)) {
                                ForEach(items) { item in
                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .light)
                                        impact.impactOccurred()
                                        store.toggleGroceryItem(id: item.id)
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(item.isChecked ? .orange : .secondary)
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
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
                                                .foregroundColor(.secondary)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete(perform: store.deleteGrocery)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sabzi Mandi")
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
                    HStack(spacing: 12) {
                        if store.groceries.contains(where: { $0.isChecked }) {
                            Button("Clear Checked") {
                                withAnimation { store.clearCompletedGroceries() }
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                                .font(.title3)
                        }
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

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
