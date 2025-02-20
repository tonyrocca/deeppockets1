import SwiftUI

@main
struct DeepPocketsApp: App {
    @StateObject var userModel = UserModel()
    @StateObject var budgetModel = BudgetModel(monthlyIncome: UserDefaults.standard.double(forKey: "monthlyIncome"))
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userModel)
                .environmentObject(budgetModel)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var userModel: UserModel
    
    var body: some View {
        // If the user is authenticated, show MainContentView; otherwise, show WelcomeView.
        if userModel.isAuthenticated {
            MainContentView()
        } else {
            NavigationStack {
                WelcomeView()
            }
        }
    }
}
