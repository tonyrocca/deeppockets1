import SwiftUI
import Foundation

class BudgetCategoryStore: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BudgetCategoryStore()
    
    // MARK: - Published Properties
    @Published var categories: [BudgetCategory] = []
    
    // MARK: - Init
    private init() {
        self.categories = createCategories()
    }
    
    // MARK: - Public Methods
    func category(for id: String) -> BudgetCategory? {
        return categories.first { $0.id == id }
    }
    
    func updateRecommendedAmount(for id: String, amount: Double) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].recommendedAmount = amount
        }
    }
    
    /// Calculate recommended amounts for all categories based on `monthlyIncome`.
    /// This will call each category's `calculateRecommendedAmount` method in turn.
    func calculateAllRecommendedAmounts(monthlyIncome: Double) {
        for i in 0..<categories.count {
            categories[i].calculateRecommendedAmount(monthlyIncome: monthlyIncome)
        }
    }
    
    // MARK: - Factory Method
    /// Creates the initial array of BudgetCategories with only the necessary assumptions
    /// for the categories that truly need them.
    func createCategories() -> [BudgetCategory] {
        return [
            // -----------------------
            // BIG / COMPLEX CATEGORIES (keep assumptions)
            // -----------------------
            BudgetCategory(
                id: "house",
                name: "House Price",
                emoji: "🏠",
                description: "Maximum home price you can afford based on your income and mortgage rates.",
                allocationPercentage: 0.20,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "Down Payment", value: "20"),
                    CategoryAssumption(title: "Interest Rate", value: "6.5"),
                    CategoryAssumption(title: "Loan Term", value: "30")
                ]
            ),
            BudgetCategory(
                id: "car",
                name: "Car",
                emoji: "🚗",
                description: "Monthly car costs (payment, insurance, fuel, maintenance).",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Car Payment", value: "60"),
                    CategoryAssumption(title: "Insurance", value: "20"),
                    CategoryAssumption(title: "Fuel & Maintenance", value: "20")
                ]
            ),
            BudgetCategory(
                id: "emergency_savings",
                name: "Emergency Fund",
                emoji: "🆘",
                description: "Total emergency fund target based on your essential monthly expenses.",
                allocationPercentage: 0.05,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "Months Coverage", value: "6"),
                    CategoryAssumption(title: "Monthly Save", value: "20"),
                    CategoryAssumption(title: "Interest Rate", value: "4.5")
                ]
            ),
            BudgetCategory(
                id: "investments",
                name: "Investments",
                emoji: "📈",
                description: "Monthly investment contributions (e.g., stocks, bonds, etc.).",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Stocks", value: "60"),
                    CategoryAssumption(title: "Bonds", value: "30"),
                    CategoryAssumption(title: "Other Assets", value: "10")
                ]
            ),
            BudgetCategory(
                id: "college_savings",
                name: "College Savings",
                emoji: "🎓",
                description: "Monthly contribution for education/college savings.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Monthly Save", value: "100"),
                    CategoryAssumption(title: "Return Rate", value: "5"),
                    CategoryAssumption(title: "Years to Save", value: "18")
                ]
            ),
            BudgetCategory(
                id: "vacation",
                name: "Vacation",
                emoji: "✈️",
                description: "Annual vacation budget including travel, lodging, and activities.",
                allocationPercentage: 0.03,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "Travel", value: "40"),
                    CategoryAssumption(title: "Lodging", value: "40"),
                    CategoryAssumption(title: "Activities", value: "20")
                ]
            ),
            
            // -----------------------
            // SIMPLE / FLAT CATEGORIES (remove assumptions)
            // -----------------------
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly food and household staples budget.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "eating_out",
                name: "Quick Bites",
                emoji: "🍔",
                description: "Fast food, coffee, takeout, and quick meals.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "public_transportation",
                name: "Transit",
                emoji: "🚆",
                description: "Buses, trains, ride-shares, etc.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "pet",
                name: "Pet Care",
                emoji: "🐾",
                description: "Food, supplies, vet care.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "restaurants",
                name: "Fine Dining",
                emoji: "🍽️",
                description: "Sit-down restaurants, date nights, etc.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "clothes",
                name: "Clothing",
                emoji: "👕",
                description: "Clothes, accessories, and shoes.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📱",
                description: "Streaming services, music, apps.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "gym",
                name: "Fitness",
                emoji: "💪",
                description: "Gym membership, classes, wellness apps.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "home_supplies",
                name: "Home Supplies",
                emoji: "🧻",
                description: "Cleaning products, paper goods, etc.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "home_utilities",
                name: "Utilities",
                emoji: "💡",
                description: "Electricity, water, gas, internet, phone.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "tickets",
                name: "Entertainment",
                emoji: "🎟️",
                description: "Concerts, sports events, movies.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            
            // -----------------------
            // NEW COMMONLY-MISSED CATEGORIES
            // -----------------------
            BudgetCategory(
                id: "medical",
                name: "Medical/Healthcare",
                emoji: "🏥",
                description: "Doctor visits, prescriptions, copays, etc.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "credit_cards",
                name: "Credit Cards",
                emoji: "💳",
                description: "Monthly credit card payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "student_loans",
                name: "Student Loans",
                emoji: "🎓",
                description: "Monthly student loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "personal_loans",
                name: "Personal Loans",
                emoji: "🏦",
                description: "Monthly personal loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "car_loan",
                name: "Car Loan",
                emoji: "🚗",
                description: "Monthly car loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "charity",
                name: "Charitable Giving",
                emoji: "❤️",
                description: "Donations to charities or religious tithes.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            )
        ]
    }
}


extension BudgetCategory {
    
    /// Calculates and updates this category's `recommendedAmount`
    /// based on its displayType and assumptions.
    mutating func calculateRecommendedAmount(monthlyIncome: Double) {
        switch displayType {
        case .monthly:
            // Example: monthly = monthlyIncome * allocationPercentage
            recommendedAmount = monthlyIncome * allocationPercentage
            
        case .total:
            // Custom logic for total categories
            if id == "house" {
                // House Price Calculation (illustrative)
                let monthlyBudget = monthlyIncome * allocationPercentage
                let interestRateStr = assumptions.first { $0.title == "Interest Rate" }?.value ?? "6.5"
                let loanTermStr     = assumptions.first { $0.title == "Loan Term" }?.value ?? "30"
                let downPaymentStr  = assumptions.first { $0.title == "Down Payment" }?.value ?? "20"
                
                guard
                    let interestRate = Double(interestRateStr),
                    let loanTerm     = Double(loanTermStr),
                    let downPayment  = Double(downPaymentStr)
                else {
                    // Fallback if parsing fails
                    recommendedAmount = monthlyBudget
                    return
                }
                
                let r = (interestRate / 100.0) / 12.0   // monthly interest
                let n = loanTerm * 12.0                // months
                if r > 0 {
                    let numerator   = pow(1 + r, n) - 1
                    let denominator = r * pow(1 + r, n)
                    let principal   = monthlyBudget * (numerator / denominator)
                    let dpFraction  = downPayment / 100.0
                    recommendedAmount = principal / (1.0 - dpFraction)
                } else {
                    // Zero interest fallback
                    recommendedAmount = monthlyBudget * n
                }
                
            } else if id == "emergency_savings" {
                // Simple emergency fund: months coverage * essential monthly expenses
                let monthsCoverageStr = assumptions.first { $0.title == "Months Coverage" }?.value ?? "6"
                guard let monthsCoverage = Double(monthsCoverageStr) else {
                    recommendedAmount = monthlyIncome * allocationPercentage
                    return
                }
                let essentialExpenses = monthlyIncome * 0.5
                recommendedAmount = essentialExpenses * monthsCoverage
                
            } else if id == "vacation" {
                // E.g. total for one year
                recommendedAmount = (monthlyIncome * allocationPercentage) * 12.0
                
            } else {
                // Default total category logic
                recommendedAmount = (monthlyIncome * allocationPercentage) * 12.0
            }
        }
    }
}
