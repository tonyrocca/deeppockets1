import SwiftUI

struct MainView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSalaryInput = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Deep Pockets")
                    .font(Theme.largeTitle)
                    .foregroundColor(Theme.label)
                
                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                        .font(Theme.body)
                        .foregroundColor(Theme.label)
                }
                .padding()
                
                Spacer()
                
                Button("Get Started") {
                    showSalaryInput = true
                }
                .buttonStyle(Theme.PrimaryButtonStyle())
                .padding()
            }
            .background(Theme.background)
            .navigationDestination(isPresented: $showSalaryInput) {
                SalaryInputView()
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
