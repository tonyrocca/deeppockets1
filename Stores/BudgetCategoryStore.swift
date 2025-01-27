import SwiftUI
import Foundation

// MARK: - DisplayType Enum
enum DisplayType {
    case monthly
    case total
}

// MARK: - BudgetCategoryStore Class
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
    /// Creates the initial array of BudgetCategories with consistent assumption styling.
    func createCategories() -> [BudgetCategory] {
        return [
            // ----------------------------------------------------------------
            // BIG / COMPLEX CATEGORIES (each has 'assumptions')
            // ----------------------------------------------------------------
            BudgetCategory(
                id: "house",
                    name: "Home Purchase",
                    emoji: "🏠",
                    description: "Total home price you can afford, including all ownership costs like property taxes and insurance.",
                    allocationPercentage: 0.28,
                    displayType: .total,
                    assumptions: [
                        CategoryAssumption(
                            title: "Down Payment",
                            value: "20",
                            inputType: .percentageSlider(step: 1),
                            description: "Higher down payment reduces monthly costs and may get better rates"
                        ),
                        CategoryAssumption(
                            title: "Interest Rate",
                            value: "7.0",
                            inputType: .percentageSlider(step: 0.25),
                            description: "Current average 30-year fixed mortgage rates"
                        ),
                        CategoryAssumption(
                            title: "Property Tax Rate",
                            value: "1.1",
                            inputType: .percentageSlider(step: 0.1),
                            description: "Annual property tax as percentage of home value"
                        )
                    ]
                ),
            BudgetCategory(
                id: "car",
                name: "Car",
                emoji: "🚗",
                description: "Monthly car costs including payment, insurance, fuel, and maintenance.",
                allocationPercentage: 0.15,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Down Payment",
                        value: "20",
                        inputType: .percentageSlider(step: 1),
                        description: "Higher down payment means lower monthly payments and better loan terms"
                    ),
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "7.5",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Auto loan rates are typically higher than mortgage rates"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 3, max: 7),
                        description: "Most auto loans range from 3-7 years"
                    )
                ]
            ),
            BudgetCategory(
                id: "emergency_savings",
                name: "Emergency Fund",
                emoji: "🆘",
                description: "Essential expenses coverage for unexpected events like job loss or medical emergencies.",
                allocationPercentage: 0.05,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                            title: "Months Coverage",
                            value: "6",
                            inputType: .percentageSlider(step: 1),
                            description: "Industry standard is 3-6 months, more if job is unstable"
                        ),
                        CategoryAssumption(
                            title: "Risk Level",
                            value: "Medium",
                            inputType: .textField,
                            description: "Low: Stable job/income, Medium: Average stability, High: Variable income"
                        ),
                        CategoryAssumption(
                            title: "Dependents",
                            value: "0",
                            inputType: .percentageSlider(step: 1),
                            description: "Number of people depending on your income"
                        )
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
                    CategoryAssumption(
                        title: "Stocks",
                        value: "60",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocated to stocks"
                    ),
                    CategoryAssumption(
                        title: "Bonds",
                        value: "30",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocated to bonds"
                    ),
                    CategoryAssumption(
                        title: "Other Assets",
                        value: "10",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocated to other assets"
                    )
                ]
            ),
            BudgetCategory(
                id: "college_savings",
                name: "College Savings",
                emoji: "🎓",
                description: "Monthly savings needed for future college expenses based on public university costs.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Years to College",
                        value: "18",
                        inputType: .yearSlider(min: 1, max: 18),
                        description: "Years until college starts"
                    )
                ]
            ),
            BudgetCategory(
                id: "vacation",
                name: "Vacation",
                emoji: "✈️",
                description: "Annual vacation budget adjusted for your travel style.",
                allocationPercentage: 0.03,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Destination Type",
                        value: "Domestic",
                        inputType: .textField,
                        description: "Choose: Domestic, International, or Luxury"
                    )
                ]
            ),
            
            // ----------------------------------------------------------------
            // SIMPLE / FLAT CATEGORIES (assumptions = [])
            // ----------------------------------------------------------------
            BudgetCategory(
                id: "groceries",
                    name: "Groceries & Essentials",
                    emoji: "🛒",
                    description: "Monthly food, household essentials, and personal care items.",
                    allocationPercentage: 0.12, // Increased to reflect current costs
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
                id: "public_transport",
                   name: "Public Transit",
                   emoji: "🚇",
                   description: "Public transportation passes, ride-sharing services, and occasional taxi use.",
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
                id: "clothing",
                name: "Clothing & Accessories",
                emoji: "👕",
                description: "Personal clothing, shoes, and essential accessories for work and daily life.",
                allocationPercentage: 0.04, // Adjusted for realistic spending
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
                id: "personal_care",
                name: "Personal Care",
                emoji: "✨",
                description: "Haircuts, personal hygiene products, and basic cosmetics.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "utilities",
                    name: "Utilities & Services",
                    emoji: "💡",
                    description: "All home utilities: electricity, water, gas, internet, phone, streaming services.",
                    allocationPercentage: 0.08,
                    displayType: .monthly,
                    assumptions: []
                ),
            BudgetCategory(
                id: "hobbies",
                name: "Hobbies & Recreation",
                emoji: "🎨",
                description: "Supplies and equipment for personal interests and recreational activities.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "phone",
                name: "Phone Plan & Device",
                emoji: "📱",
                description: "Monthly phone plan, device payments, and accessories.",
                allocationPercentage: 0.03,
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
            
            // ----------------------------------------------------------------
            // NEW COMMONLY-MISSED CATEGORIES (assumptions = [])
            // ----------------------------------------------------------------
            BudgetCategory(
                id: "healthcare",
                    name: "Healthcare",
                    emoji: "🏥",
                    description: "Insurance premiums, medications, routine care, and anticipated medical expenses.",
                    allocationPercentage: 0.06, // Increased to better reflect real costs
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
                id: "car_expenses",
                name: "Car Expenses",
                emoji: "🚗",
                description: "Fuel, insurance, maintenance, and parking for vehicle owners.",
                allocationPercentage: 0.10,
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

// MARK: - BudgetCategory Extension
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
                // (Example) Use 50% of monthly income as 'essential expenses'
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
