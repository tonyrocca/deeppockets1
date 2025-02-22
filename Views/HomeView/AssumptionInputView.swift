import SwiftUI

struct AssumptionInputView: View {
    let title: String
    let description: String?
    let suffix: String
    @Binding var value: String
    let onChanged: (String) -> Void
    
    @FocusState private var isFocused: Bool
    @State private var localValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            
            if let description = description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
                    .padding(.bottom, 4)
            }
            
            HStack {
                if suffix == "$" {
                    Text(suffix)
                        .foregroundColor(.white)
                        .padding(.trailing, 2)
                }
                
                TextField("", text: $localValue)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .focused($isFocused)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                    .onChange(of: localValue) { newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            localValue = filtered
                        }
                    }
                
                if suffix != "$" && !suffix.isEmpty {
                    Text(suffix)
                        .foregroundColor(Theme.secondaryLabel)
                }
            }
            .background(Theme.surfaceBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Theme.tint : Color.black.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            localValue = value
        }
        .onDisappear {
            submitValue()
        }
        .onChange(of: isFocused) { focused in
            if !focused {
                submitValue()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                }
            }
        }
    }
    
    private func submitValue() {
        // Handle empty values
        if localValue.isEmpty {
            if suffix == "%" {
                localValue = "0"
            } else if suffix == "$" {
                localValue = "0"
            } else {
                localValue = "0"
            }
        }
        
        // Format based on suffix
        if suffix == "%" {
            // Ensure percentage is valid
            if let doubleValue = Double(localValue) {
                if doubleValue > 100 {
                    localValue = "100"
                }
            }
        }
        
        value = localValue
        onChanged(localValue)
    }
}
