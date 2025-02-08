import SwiftUI

struct TabHeaderView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(
                    icon: "💳",
                    title: "Affordability",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                TabButton(
                    icon: "💰",
                    title: "Budget",
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
            }
            .frame(height: 44)
            
            // Black divider line
            Rectangle()
                .fill(Color.black.opacity(0.1))
                .frame(height: 1)
        }
        .background(Theme.darkBackground)
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 17, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 43)
            .background(isSelected ? Theme.darkBackground : Theme.darkBackground)
            .overlay(
                Rectangle()
                    .fill(isSelected ? .white : .clear)
                    .frame(height: 2)
                    .padding(.horizontal, 8),
                alignment: .bottom
            )
        }
    }
}
