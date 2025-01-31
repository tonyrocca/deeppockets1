import SwiftUI

struct ActionButtonMenu: View {
    let onClose: () -> Void
    let onAffordabilityTap: () -> Void
    let onSavingsTap: () -> Void
    let onDebtTap: () -> Void
    @Binding var isShowing: Bool
    
    @State private var menuOffset: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Dimmed background
            if isShowing {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
                    VStack(spacing: 12) {
                        menuButton(
                            title: "What can I afford?",
                            icon: "cart.fill",
                            description: "Check if that purchase fits your budget",
                            action: onAffordabilityTap
                        )
                        
                        menuButton(
                            title: "Can I manage this debt?",
                            icon: "creditcard.fill",
                            description: "Calculate your debt payments",
                            action: onDebtTap
                        )
                        
                        menuButton(
                            title: "How can I save for this?",
                            icon: "banknote.fill",
                            description: "Plan your savings strategy",
                            action: onSavingsTap
                        )
                    }
                    .offset(y: menuOffset)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            menuOffset = 0
                        }
                    }
                }
                
                // Pill-shaped FAB Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowing.toggle()
                        if !isShowing {
                            onClose()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Ask me")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.tint)
                    .clipShape(Capsule())
                    .shadow(color: Theme.tint.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    private func menuButton(title: String, icon: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation {
                isShowing = false
                action()
            }
        }) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Theme.tint.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.tint)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.surfaceBackground.opacity(0.95))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
