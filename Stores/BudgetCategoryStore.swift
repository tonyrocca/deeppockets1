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
    /// Creates the initial array of BudgetCategories.
    func createCategories() -> [BudgetCategory] {
        return [
            // -------------------------------
            // Housing & Shelter
            // -------------------------------
            BudgetCategory(
                id: "home",
                name: "Home",
                emoji: "🏠",
                description: "Total purchase price for a home, including ownership costs like taxes and insurance.",
                allocationPercentage: 0.28,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Down Payment",
                        value: "20",
                        inputType: .percentageSlider(step: 1),
                        description: "Percentage paid upfront."
                    ),
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "7.0",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual mortgage interest rate."
                    ),
                    CategoryAssumption(
                        title: "Property Tax Rate",
                        value: "1.1",
                        inputType: .percentageSlider(step: 0.1),
                        description: "Annual property tax as % of value."
                    )
                ],
                type: .housing
            ),
            BudgetCategory(
                id: "rent",
                name: "Rent",
                emoji: "🏢",
                description: "Monthly rent for your residence.",
                allocationPercentage: 0.30,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Lease Term",
                        value: "12",
                        inputType: .yearSlider(min: 6, max: 24),
                        description: "Length of lease in months."
                    )
                ],
                type: .housing
            ),
            BudgetCategory(
                id: "home_maintenance",
                name: "Home Maintenance",
                emoji: "🔨",
                description: "Repairs and upkeep for your home.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .housing
            ),
            // -------------------------------
            // Transportation
            // -------------------------------
            BudgetCategory(
                id: "car",
                name: "Car",
                emoji: "🚗",
                description: "Total purchase price for a car, including financing costs and fees.",
                allocationPercentage: 0.15,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Down Payment",
                        value: "10",
                        inputType: .percentageSlider(step: 1),
                        description: "Percentage paid upfront."
                    ),
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "5.0",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual car loan interest rate."
                    ),
                    CategoryAssumption(
                        title: "Sales Tax Rate",
                        value: "8.0",
                        inputType: .percentageSlider(step: 0.1),
                        description: "Sales tax applied to the purchase price."
                    )
                ],
                type: .transportation
            ),
            BudgetCategory(
                id: "car_maintenance",
                name: "Car Maintenance",
                emoji: "🔧",
                description: "Repairs and routine maintenance for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .transportation
            ),
            BudgetCategory(
                id: "transportation",
                name: "Transportation",
                emoji: "🚇",
                description: "Costs for public transit, fuel, parking, and tolls.",
                allocationPercentage: 0.07,
                displayType: .monthly,
                assumptions: [],
                type: .transportation
            ),
            // -------------------------------
            // Utilities & Bills
            // -------------------------------
            BudgetCategory(
                id: "utilities",
                name: "Utilities",
                emoji: "💡",
                description: "Monthly costs for electricity, water, and gas.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: [],
                type: .utilities
            ),
            BudgetCategory(
                id: "internet",
                name: "Internet & Cable",
                emoji: "📶",
                description: "Monthly internet and cable TV expenses.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .utilities
            ),
            // -------------------------------
            // Food & Groceries
            // -------------------------------
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly food and household essentials.",
                allocationPercentage: 0.12,
                displayType: .monthly,
                assumptions: [],
                type: .food
            ),
            BudgetCategory(
                id: "dining",
                name: "Dining Out",
                emoji: "🍽️",
                description: "Expenses for eating out and coffee.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .food
            ),
            // -------------------------------
            // Entertainment
            // -------------------------------
            BudgetCategory(
                id: "entertainment",
                name: "Entertainment",
                emoji: "🎟️",
                description: "Movies, concerts, and events.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment
            ),
            BudgetCategory(
                id: "hobbies",
                name: "Hobbies",
                emoji: "🎨",
                description: "Supplies and expenses for hobbies and recreational activities.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment
            ),
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📺",
                description: "Costs for streaming services and apps.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment
            ),
            // -------------------------------
            // Insurance
            // -------------------------------
            BudgetCategory(
                id: "insurance",
                name: "Insurance",
                emoji: "🛡️",
                description: "Monthly premiums for home, auto, and renters insurance.",
                allocationPercentage: 0.06,
                displayType: .monthly,
                assumptions: [],
                type: .insurance
            ),
            BudgetCategory(
                id: "health_insurance",
                name: "Health Insurance",
                emoji: "💊",
                description: "Monthly health insurance premium.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .insurance
            ),
            BudgetCategory(
                id: "auto_insurance",
                name: "Auto Insurance",
                emoji: "🚘",
                description: "Insurance premiums for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .insurance
            ),
            BudgetCategory(
                id: "home_insurance",
                name: "Home Insurance",
                emoji: "🏠",
                description: "Insurance premiums for your home or rental.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .insurance
            ),
            
            // -------------------------------
            // Savings Categories
            // -------------------------------
            BudgetCategory(
                id: "retirement_savings",
                name: "Retirement Savings",
                emoji: "💰",
                description: "Contributions to retirement accounts.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [],
                type: .savings
            ),
            BudgetCategory(
                id: "shortterm_savings",
                name: "Short-term Savings",
                emoji: "🏦",
                description: "Savings for short-term goals and emergencies.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .savings
            ),
            BudgetCategory(
                id: "college_savings",
                name: "College Savings",
                emoji: "🎓",
                description: "Savings for future college expenses.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Years to College",
                        value: "18",
                        inputType: .yearSlider(min: 1, max: 18),
                        description: "Years until college starts."
                    )
                ],
                type: .savings
            ),
            BudgetCategory(
                id: "investments",
                name: "Investments",
                emoji: "📈",
                description: "Monthly contributions to investment accounts.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Stocks",
                        value: "60",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocation to stocks."
                    ),
                    CategoryAssumption(
                        title: "Bonds",
                        value: "30",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocation to bonds."
                    ),
                    CategoryAssumption(
                        title: "Other Assets",
                        value: "10",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocation to other assets."
                    )
                ],
                type: .savings
            ),
            BudgetCategory(
                id: "charity",
                name: "Charity",
                emoji: "❤️",
                description: "Donations and charitable contributions.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .savings
            ),
            
            // -------------------------------
            // Education
            // -------------------------------
            BudgetCategory(
                id: "education",
                name: "Education",
                emoji: "📚",
                description: "Tuition, books, and supplies for education.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Tuition Cost",
                        value: "5000",
                        inputType: .textField,
                        description: "Monthly tuition cost estimate."
                    )
                ],
                type: .education
            ),
            BudgetCategory(
                id: "personal_development",
                name: "Personal Development",
                emoji: "🎓",
                description: "Expenses for courses and self-improvement.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .education
            ),
            
            // -------------------------------
            // Debt Categories
            // -------------------------------
            BudgetCategory(
                id: "credit_cards",
                name: "Credit Card Debt",
                emoji: "💳",
                description: "Monthly credit card payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "APR",
                        value: "18",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual percentage rate"
                    ),
                    CategoryAssumption(
                        title: "Min Payment",
                        value: "2",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Min payment as % of balance"
                    )
                ],
                type: .debt
            ),
            BudgetCategory(
                id: "student_loans",
                name: "Student Loan Debt",
                emoji: "🎓",
                description: "Monthly student loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "5",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "10",
                        inputType: .yearSlider(min: 5, max: 20),
                        description: "Term in years"
                    )
                ],
                type: .debt
            ),
            BudgetCategory(
                id: "personal_loans",
                name: "Personal Loan Debt",
                emoji: "🏦",
                description: "Monthly personal loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "8",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 1, max: 10),
                        description: "Term in years"
                    )
                ],
                type: .debt
            ),
            BudgetCategory(
                id: "medical_debt",
                name: "Medical Debt",
                emoji: "🏥",
                description: "Monthly payments on medical bills.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .debt
            ),
            BudgetCategory(
                id: "mortgage",
                name: "Mortgage Debt",
                emoji: "🏠",
                description: "Monthly mortgage payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "4",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "30",
                        inputType: .yearSlider(min: 15, max: 30),
                        description: "Term in years"
                    )
                ],
                type: .debt
            )
        ]
    }
}
