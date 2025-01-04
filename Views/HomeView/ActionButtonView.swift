import SwiftUI

struct ActionButtonMenu: View {
    let onClose: () -> Void
    let onAffordabilityTap: () -> Void
    let onSavingsTap: () -> Void
    let onDebtTap: () -> Void
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Dimmed background
            if isShowing {
                Color.black
                    .opacity(0.4)  // Slightly reduced opacity
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                            onClose()
                        }
                    }
            }
            
            // Menu Buttons
            VStack {
                Spacer()
                
                if isShowing {
                    // Menu Container
                    VStack(spacing: 8) {  // Reduced spacing between buttons
                        menuButton(title: "Can I afford this?", action: onAffordabilityTap)
                        menuButton(title: "Calculate debt payoff", action: onDebtTap)
                        menuButton(title: "Create savings goal", action: onSavingsTap)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)  // Add some space before FAB
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Close/FAB Button
                Button(action: {
                    withAnimation(.spring()) {
                        isShowing.toggle()
                        if !isShowing {
                            onClose()
                        }
                    }
                }) {
                    Image(systemName: isShowing ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .semibold))  // Slightly smaller icon
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.tint)
                        .clipShape(Circle())
                        .shadow(color: Theme.tint.opacity(0.2), radius: 8, x: 0, y: 4)  // Subtle shadow
                }
                .rotationEffect(Angle(degrees: isShowing ? 45 : 0))  // Changed rotation
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // Helper function for consistent button styling
    private func menuButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation {
                isShowing = false
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 50)  // Slightly reduced height
                .frame(maxWidth: .infinity)
                .background(Theme.surfaceBackground.opacity(0.8))  // Semi-transparent background
                .cornerRadius(25)  // Rounded corners
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)  // Subtle border
                )
        }
    }
}
