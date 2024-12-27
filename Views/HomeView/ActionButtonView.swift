import SwiftUI

struct ActionButtonMenu: View {
    let onClose: () -> Void
    let onAffordabilityTap: () -> Void
    let onSavingsTap: () -> Void
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Dimmed background
            if isShowing {
                Color.black
                    .opacity(0.5)
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
                    // Affordability Calculator Button
                    Button(action: {
                        withAnimation {
                            isShowing = false
                            onAffordabilityTap()
                        }
                    }) {
                        Text("Can I afford this?")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(Theme.tint)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // Savings Calculator Button
                    Button(action: {
                        withAnimation {
                            isShowing = false
                            onSavingsTap()
                        }
                    }) {
                        Text("Saving for something...")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(Theme.tint)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
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
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.tint)
                        .clipShape(Circle())
                        .shadow(color: Theme.tint.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .rotationEffect(Angle(degrees: isShowing ? 90 : 0))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, isShowing ? 12 : 0)
            }
        }
    }
}
