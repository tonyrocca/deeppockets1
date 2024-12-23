import SwiftUI

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var budgetModel: BudgetModel
    @State private var name = ""
    @State private var emoji = "📝"
    @State private var allocation = ""
    @State private var type: BudgetCategoryType = .expense
    @State private var priority: BudgetCategoryPriority = .discretionary
    @State private var showingEmojiPicker = false
    
    private let emojis = ["📝", "🎯", "🎨", "🎮", "🎵", "📚", "🎬", "🏃‍♂️", "🍳", "🛠️", "🎁", "🌟"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Category Name")
                        TextField("Enter name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Button(action: { showingEmojiPicker.toggle() }) {
                            Text(emoji)
                                .font(.title2)
                        }
                    }
                    
                    HStack {
                        Text("Monthly Amount")
                        TextField("Enter amount", text: $allocation)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Picker("Type", selection: $type) {
                        Text("Expense").tag(BudgetCategoryType.expense)
                        Text("Savings").tag(BudgetCategoryType.savings)
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(BudgetCategoryPriority.allCases, id: \.self) { priority in
                            Text(priority.label).tag(priority)
                        }
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = Double(allocation), !name.isEmpty {
                            budgetModel.addCustomCategory(
                                name: name,
                                emoji: emoji,
                                allocation: amount,
                                type: type,
                                priority: priority
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || allocation.isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }
}

// EmojiPickerView.swift
struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String
    
    private let emojis = ["📝", "🎯", "🎨", "🎮", "🎵", "📚", "🎬", "🏃‍♂️", "🍳", "🛠️", "🎁", "🌟",
                         "🎪", "🎭", "🎪", "🎨", "🎯", "🎲", "🎼", "🎧", "🎤", "🎹", "🎸", "🎺",
                         "🎻", "🎬", "📷", "📱", "💻", "⌚️", "📱", "📲", "💻", "⌨️", "🖥", "🖨",
                         "🏃‍♀️", "🚴‍♂️", "🏋️‍♂️", "⛹️‍♂️", "🤸‍♂️", "🤼‍♂️", "🤽‍♂️", "🤾‍♂️", "🤹‍♂️",
                         "🎭", "🎪", "🎢", "🎡", "🎠", "🎮", "🕹", "🎲", "🎯", "🎳", "🎮"]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 30))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
