import SwiftUI

struct TabHeaderView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Affordability",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                title: "Budget",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
        }
        .frame(height: 44) // Standard height for tab bar
        .background(Theme.darkBackground)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 43)
                
                Rectangle()
                    .fill(isSelected ? .white : .clear)
                    .frame(height: 1)
            }
        }
    }
}
