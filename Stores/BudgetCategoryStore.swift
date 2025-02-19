import SwiftUI
import Foundation

// MARK: - AmountDisplayType Enum
enum AmountDisplayType {
    case monthly
    case total
}

// MARK: - AssumptionInputType Enum
enum AssumptionInputType {
    case percentageSlider(step: Double)
    case yearSlider(min: Int, max: Int)
    case textField
    case percentageDistribution
}

// MARK: - CategoryAssumption Struct
struct CategoryAssumption: Identifiable {
    let title: String
    var value: String
    let inputType: AssumptionInputType
    let description: String?
    var id: String { title }
}

extension CategoryAssumption {
    var displayValue: String {
        switch inputType {
        case .percentageSlider:
            return value + "%"
        case .yearSlider:
            return value + " years"
        default:
            return value
        }
    }
}

// MARK: - CategoryType Enum
enum CategoryType {
    case housing
    case transportation
    case savings
    case debt
    case utilities
    case food
    case entertainment
    case insurance
    case education
    case personal
    case health
    case family
    case other
}

// MARK: - BudgetCategory Struct
struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let allocationPercentage: Double
    var recommendedAmount: Double = 0
    let displayType: AmountDisplayType
    var assumptions: [CategoryAssumption]
    let type: CategoryType
    let priority: Int
    
    // Optional properties
    var savingsGoal: Double?
    var savingsTimeline: Int?
    var debtAmount: Double?
    var debtInterestRate: Double?
    
    var formattedAllocation: String {
        let percentage = allocationPercentage * 100
        return String(format: "%.1f%%", percentage)
    }
    
    /// Default fallback for categories that simply use “percentage of income.”
    /// (Special categories like “home” or “car” can override this in the store.)
    mutating func calculateRecommendedAmount(monthlyIncome: Double) {
        if displayType == .monthly {
            recommendedAmount = monthlyIncome * allocationPercentage
        } else {
            recommendedAmount = monthlyIncome * allocationPercentage * 12
        }
    }
}

// MARK: - BudgetCategoryStore Class
class BudgetCategoryStore: ObservableObject {
    
    // Singleton instance
    static let shared = BudgetCategoryStore()
    
    // Published list of categories
    @Published var categories: [BudgetCategory] = []
    
    // Private initializer ensures only one instance is created
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
    
    /// Re-calculate recommended amounts for all categories based on monthlyIncome.
    /// This now includes special logic for “home”, “car”, and “emergency_savings.”
    func calculateAllRecommendedAmounts(monthlyIncome: Double) {
        for i in 0..<categories.count {
            var category = categories[i]
            
            switch category.id {
            case "home":
                category.recommendedAmount = calculateHomeAffordability(category, monthlyIncome: monthlyIncome)
            case "car":
                category.recommendedAmount = calculateCarAffordability(category, monthlyIncome: monthlyIncome)
            case "emergency_savings":
                category.recommendedAmount = calculateEmergencySavings(category, monthlyIncome: monthlyIncome)
            default:
                category.calculateRecommendedAmount(monthlyIncome: monthlyIncome)
            }
            
            categories[i] = category
        }
    }
    
    // MARK: - Factory Method
    /// Creates the initial array of BudgetCategories.
    func createCategories() -> [BudgetCategory] {
        var list: [BudgetCategory] = [
            // -------------------------------
            // Housing & Shelter
            // -------------------------------
            BudgetCategory(
                id: "home",
                name: "Home",
                emoji: "🏠",
                description: "Total purchase price for a home, including estimated taxes and insurance.",
                allocationPercentage: 0.28,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Down Payment",
                        value: "20", // Best practice is 20%
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
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "30",
                        inputType: .yearSlider(min: 15, max: 30),
                        description: "Loan term in years for your mortgage."
                    )
                ],
                type: .housing,
                priority: 1
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
                type: .housing,
                priority: 1
            ),
            BudgetCategory(
                id: "home_maintenance",
                name: "Home Maintenance",
                emoji: "🔨",
                description: "Monthly expenses for repairs and upkeep of your home.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .housing,
                priority: 3
            ),
            BudgetCategory(
                id: "home_improvement",
                name: "Rennovations",
                emoji: "🏡",
                description: "Funds for renovations and upgrades (one-time or infrequent expenses).",
                allocationPercentage: 0.04,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Renovation Budget",
                        value: "15000",
                        inputType: .textField,
                        description: "Total budget for home improvements."
                    )
                ],
                type: .housing,
                priority: 3
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
                        value: "20", // Best practice: aim for 20%
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
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 3, max: 7),
                        description: "Loan term in years for your car loan."
                    )
                ],
                type: .transportation,
                priority: 2
            ),
            BudgetCategory(
                id: "car_maintenance",
                name: "Car Maintenance",
                emoji: "🔧",
                description: "Monthly expenses for repairs and routine maintenance of your vehicle.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .transportation,
                priority: 4
            ),
            BudgetCategory(
                id: "transportation",
                name: "Public Transit & Fuel",
                emoji: "🚇",
                description: "Monthly costs for fuel, parking, tolls, and public transit.",
                allocationPercentage: 0.07,
                displayType: .monthly,
                assumptions: [],
                type: .transportation,
                priority: 3
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
                type: .utilities,
                priority: 2
            ),
            BudgetCategory(
                id: "internet",
                name: "Internet & Cable",
                emoji: "📶",
                description: "Monthly internet and cable TV expenses.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .utilities,
                priority: 3
            ),
            BudgetCategory(
                id: "cell_phone",
                name: "Cell Phone",
                emoji: "📱",
                description: "Monthly cell phone bill.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "70",
                        inputType: .textField,
                        description: "Average monthly cell phone expense."
                    )
                ],
                type: .utilities,
                priority: 2
            ),
            BudgetCategory(
                id: "home_security",
                name: "Home Security",
                emoji: "🔒",
                description: "Monthly expenses for security systems monitoring.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "40",
                        inputType: .textField,
                        description: "Monthly home security expense."
                    )
                ],
                type: .utilities,
                priority: 2
            ),
            // -------------------------------
            // Food & Groceries
            // -------------------------------
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly spending on food and household essentials.",
                allocationPercentage: 0.12,
                displayType: .monthly,
                assumptions: [],
                type: .food,
                priority: 1
            ),
            BudgetCategory(
                id: "dining",
                name: "Dining Out",
                emoji: "🍽️",
                description: "Expenses for eating out, takeout, and coffee shops.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .food,
                priority: 3
            ),
            // -------------------------------
            // Entertainment & Leisure
            // -------------------------------
            BudgetCategory(
                id: "entertainment",
                name: "Entertainment",
                emoji: "🎟️",
                description: "Expenses for movies, concerts, and other events.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment,
                priority: 4
            ),
            BudgetCategory(
                id: "hobbies",
                name: "Hobbies",
                emoji: "🎨",
                description: "Supplies and costs for hobbies and recreational activities.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment,
                priority: 4
            ),
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📺",
                description: "Monthly costs for streaming services, apps, and memberships.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment,
                priority: 4
            ),
            // -------------------------------
            // Insurance
            // -------------------------------
            BudgetCategory(
                id: "insurance",
                name: "General Insurance",
                emoji: "🛡️",
                description: "Monthly premiums for home, auto, or renters insurance.",
                allocationPercentage: 0.06,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 1
            ),
            BudgetCategory(
                id: "health_insurance",
                name: "Health Insurance",
                emoji: "💊",
                description: "Monthly premium for your health insurance plan.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Deductible",
                        value: "1000",
                        inputType: .textField,
                        description: "Annual deductible for your plan."
                    )
                ],
                type: .insurance,
                priority: 1
            ),
            BudgetCategory(
                id: "auto_insurance",
                name: "Auto Insurance",
                emoji: "🚘",
                description: "Monthly premiums for your car insurance.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 2
            ),
            BudgetCategory(
                id: "home_insurance",
                name: "Home Insurance",
                emoji: "🏠",
                description: "Monthly premiums for your home or rental insurance.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 2
            ),
            // -------------------------------
            // Savings & Investments
            // -------------------------------
            // New Savings Category for House Downpayment
            BudgetCategory(
                id: "house_downpayment",
                name: "House Downpayment",
                emoji: "🏡",
                description: "Savings target for your house downpayment. Best practice is to aim for a 20% downpayment.",
                allocationPercentage: 0.05,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Target Amount",
                        value: "60000",
                        inputType: .textField,
                        description: "Total savings goal for a house downpayment."
                    )
                ],
                type: .savings,
                priority: 10,
                savingsGoal: 60000
            ),
            // New Savings Category for Car Downpayment
            BudgetCategory(
                id: "car_downpayment",
                name: "Car Downpayment",
                emoji: "🚙",
                description: "Savings target for your car downpayment. Aim for a 20% downpayment.",
                allocationPercentage: 0.02,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Target Amount",
                        value: "5000",
                        inputType: .textField,
                        description: "Total savings goal for a car downpayment."
                    )
                ],
                type: .savings,
                priority: 10,
                savingsGoal: 5000
            ),
            BudgetCategory(
                id: "retirement_savings",
                name: "Retirement Savings",
                emoji: "💰",
                description: "Monthly contributions to retirement accounts.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Employer Match",
                        value: "5",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Percentage of your salary matched by your employer."
                    )
                ],
                type: .savings,
                priority: 1
            ),
            BudgetCategory(
                id: "shortterm_savings",
                name: "Short-term Savings",
                emoji: "🏦",
                description: "Savings for short-term goals and emergency funds.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .savings,
                priority: 1
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
                        description: "Number of years until college starts."
                    )
                ],
                type: .savings,
                priority: 2
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
                type: .savings,
                priority: 2
            ),
            BudgetCategory(
                id: "charity",
                name: "Charity",
                emoji: "❤️",
                description: "Donations and charitable contributions.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .savings,
                priority: 3
            ),
            BudgetCategory(
                id: "emergency_savings",
                name: "Emergency Savings",
                emoji: "🚨",
                description: "Savings for unexpected emergencies. Typically, you should cover around 6 months of your salary.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Months of Salary",
                        value: "6",
                        inputType: .yearSlider(min: 3, max: 12),
                        description: "Number of months of salary to cover for emergencies."
                    )
                ],
                type: .savings,
                priority: 1
            ),
            BudgetCategory(
                id: "vacation_savings",
                name: "Vacation Savings",
                emoji: "🏖️",
                description: "Savings for vacations and leisure travel.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Target Amount",
                        value: "2000",
                        inputType: .textField,
                        description: "Desired vacation fund total."
                    )
                ],
                type: .savings,
                priority: 4
            ),
            BudgetCategory(
                id: "tax_savings",
                name: "Tax Savings",
                emoji: "🧾",
                description: "Funds set aside for upcoming tax payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Savings Target",
                        value: "300",
                        inputType: .textField,
                        description: "Amount to save monthly for taxes."
                    ),
                    CategoryAssumption(
                        title: "Effective Tax Rate",
                        value: "25",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Your estimated effective tax rate."
                    )
                ],
                type: .savings,
                priority: 1
            ),
            BudgetCategory(
                id: "investment_fees",
                name: "Investment Fees",
                emoji: "💼",
                description: "Monthly management fees or commissions for investments.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "20",
                        inputType: .textField,
                        description: "Average monthly investment fees."
                    )
                ],
                type: .savings,
                priority: 3
            ),
            BudgetCategory(
                id: "charitable_donations",
                name: "Charitable Donations",
                emoji: "🤝",
                description: "Additional donations beyond basic charity.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Donation",
                        value: "25",
                        inputType: .textField,
                        description: "Budget for extra charitable donations."
                    )
                ],
                type: .savings,
                priority: 4
            ),
            // -------------------------------
            // Education
            // -------------------------------
            BudgetCategory(
                id: "education",
                name: "Education (Tuition)",
                emoji: "📚",
                description: "Tuition, books, and supplies for formal education.",
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
                type: .education,
                priority: 2
            ),
            // -------------------------------
            // Personal Development & Work
            // -------------------------------
            BudgetCategory(
                id: "personal_development",
                name: "Personal Development",
                emoji: "🎓",
                description: "Expenses for courses, workshops, and self-improvement.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .personal,
                priority: 3
            ),
            // -------------------------------
            // Debt Repayment
            // -------------------------------
            BudgetCategory(
                id: "credit_cards",
                name: "Credit Card Debt",
                emoji: "💳",
                description: "Monthly payments on credit card balances.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "APR",
                        value: "18",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual percentage rate."
                    ),
                    CategoryAssumption(
                        title: "Min Payment",
                        value: "2",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Minimum payment as % of balance."
                    )
                ],
                type: .debt,
                priority: 1
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
                        description: "Annual interest rate."
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "10",
                        inputType: .yearSlider(min: 5, max: 20),
                        description: "Term in years."
                    )
                ],
                type: .debt,
                priority: 2
            ),
            BudgetCategory(
                id: "personal_loans",
                name: "Personal Loan Debt",
                emoji: "🏦",
                description: "Monthly payments for personal loans.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "8",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual interest rate."
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 1, max: 10),
                        description: "Term in years."
                    )
                ],
                type: .debt,
                priority: 2
            ),
            BudgetCategory(
                id: "medical_debt",
                name: "Medical Debt",
                emoji: "🏥",
                description: "Monthly payments on outstanding medical bills.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .debt,
                priority: 2
            ),
            BudgetCategory(
                id: "mortgage",
                name: "Mortgage Debt",
                emoji: "🏠",
                description: "Monthly mortgage payments on a home loan.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "4",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual interest rate."
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "30",
                        inputType: .yearSlider(min: 15, max: 30),
                        description: "Term in years."
                    )
                ],
                type: .debt,
                priority: 1
            ),
            // -------------------------------
            // Family Expenses
            // -------------------------------
            BudgetCategory(
                id: "childcare",
                name: "Childcare",
                emoji: "👶",
                description: "Expenses for childcare or daycare services.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost per Child",
                        value: "800",
                        inputType: .textField,
                        description: "Average monthly cost per child."
                    )
                ],
                type: .family,
                priority: 2
            ),
            BudgetCategory(
                id: "child_education",
                name: "Child Education",
                emoji: "🎒",
                description: "Expenses for school supplies, fees, and extracurricular activities.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "300",
                        inputType: .textField,
                        description: "Average monthly cost for child education."
                    )
                ],
                type: .family,
                priority: 3
            ),
            BudgetCategory(
                id: "pet_care",
                name: "Pet Care",
                emoji: "🐾",
                description: "Expenses for pet food, vet visits, and supplies.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "150",
                        inputType: .textField,
                        description: "Average monthly pet expense."
                    )
                ],
                type: .family,
                priority: 3
            ),
            // -------------------------------
            // Personal Expenses
            // -------------------------------
            BudgetCategory(
                id: "clothing",
                name: "Clothing",
                emoji: "👗",
                description: "Expenses for apparel and accessories.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "200",
                        inputType: .textField,
                        description: "Average monthly clothing expense."
                    )
                ],
                type: .personal,
                priority: 3
            ),
            BudgetCategory(
                id: "personal_care",
                name: "Personal Care",
                emoji: "💄",
                description: "Expenses for grooming, haircuts, and toiletries.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "100",
                        inputType: .textField,
                        description: "Average monthly personal care expense."
                    )
                ],
                type: .personal,
                priority: 3
            ),
            BudgetCategory(
                id: "gym_membership",
                name: "Gym Membership",
                emoji: "🏋️‍♀️",
                description: "Monthly fees for fitness club membership.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "50",
                        inputType: .textField,
                        description: "Monthly gym membership fee."
                    )
                ],
                type: .personal,
                priority: 4
            ),
            BudgetCategory(
                id: "work_expenses",
                name: "Work Expenses",
                emoji: "💼",
                description: "Costs related to commuting and supplies for work.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "150",
                        inputType: .textField,
                        description: "Average monthly work expense."
                    )
                ],
                type: .personal,
                priority: 2
            ),
            BudgetCategory(
                id: "professional_development",
                name: "Professional Development",
                emoji: "📖",
                description: "Investments in courses, workshops, and self-improvement.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "100",
                        inputType: .textField,
                        description: "Average monthly expense for professional development."
                    )
                ],
                type: .personal,
                priority: 3
            ),
            BudgetCategory(
                id: "legal_expenses",
                name: "Legal Expenses",
                emoji: "⚖️",
                description: "Costs for legal fees and advice.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "30",
                        inputType: .textField,
                        description: "Average monthly legal expense."
                    )
                ],
                type: .personal,
                priority: 3
            ),
            // -------------------------------
            // Health Expenses
            // -------------------------------
            BudgetCategory(
                id: "medical_expenses",
                name: "Medical Expenses",
                emoji: "🏥",
                description: "Out-of-pocket medical costs not covered by insurance.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "200",
                        inputType: .textField,
                        description: "Average monthly out-of-pocket medical expense."
                    )
                ],
                type: .health,
                priority: 2
            ),
            BudgetCategory(
                id: "dental",
                name: "Dental",
                emoji: "😬",
                description: "Expenses for dental care and treatments.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "50",
                        inputType: .textField,
                        description: "Average monthly dental expense."
                    )
                ],
                type: .health,
                priority: 2
            ),
            BudgetCategory(
                id: "vision_care",
                name: "Vision Care",
                emoji: "👓",
                description: "Expenses for eye exams and glasses.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "30",
                        inputType: .textField,
                        description: "Average monthly vision care expense."
                    )
                ],
                type: .health,
                priority: 3
            ),
            // -------------------------------
            // Other/Discretionary Expenses
            // -------------------------------
            BudgetCategory(
                id: "miscellaneous",
                name: "Miscellaneous",
                emoji: "📦",
                description: "Budget for unplanned or irregular expenses.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "100",
                        inputType: .textField,
                        description: "Budget for miscellaneous expenses."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "travel",
                name: "Travel",
                emoji: "✈️",
                description: "Expenses for travel (non-vacation) or weekend trips.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "150",
                        inputType: .textField,
                        description: "Average monthly travel expense."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "gifts",
                name: "Gifts",
                emoji: "🎁",
                description: "Budget for gift giving for friends and family.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "50",
                        inputType: .textField,
                        description: "Budget for gifts."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "lawn_care",
                name: "Lawn Care",
                emoji: "🌱",
                description: "Expenses for maintaining your yard and landscaping.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "40",
                        inputType: .textField,
                        description: "Average monthly lawn care expense."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "cleaning_services",
                name: "Cleaning Services",
                emoji: "🧹",
                description: "Costs for professional cleaning services.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "80",
                        inputType: .textField,
                        description: "Average monthly cleaning service expense."
                    )
                ],
                type: .other,
                priority: 4
            )
        ]
        
        return list
    }
}

// MARK: - Special Calculations Extension
extension BudgetCategoryStore {
    // Helper method to get assumption values
    private func getAssumptionValue(_ assumptions: [CategoryAssumption], title: String) -> Double? {
        if let valueStr = assumptions.first(where: { $0.title == title })?.value,
           let value = Double(valueStr) {
            return value
        }
        return nil
    }
    
    func calculateHomeAffordability(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 7.0
        let propertyTax = getAssumptionValue(assumptions, title: "Property Tax Rate") ?? 1.1
        let loanTermYears = Int(getAssumptionValue(assumptions, title: "Loan Term") ?? 30)
        
        // 1) Determine your target monthly budget for housing:
        let monthlyBudget = monthlyIncome * category.allocationPercentage
        
        // 2) Convert annual interest to monthly
        let monthlyInterest = (interestRate / 100.0) / 12.0
        
        // 3) Number of monthly payments
        let n = Double(loanTermYears * 12)
        
        // 4) Mortgage factor: r(1+r)^n / ((1+r)^n - 1)
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        guard denominator > 0 else { return 0 }
        let factor = numerator / denominator
        
        // 5) Solve for homePrice such that:
        //    ( (homePrice * (1 - dp/100)) * factor ) + (homePrice * (propertyTax/100) / 12 ) = monthlyBudget
        let dpFraction = (1 - downPayment / 100.0)
        let monthlyTaxFraction = (propertyTax / 100.0) / 12.0
        
        let divisor = dpFraction * factor + monthlyTaxFraction
        guard divisor > 0 else { return 0 }
        
        let homePrice = monthlyBudget / divisor
        return homePrice
    }
    
    func calculateCarAffordability(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 5.0
        let loanTermYears = Int(getAssumptionValue(assumptions, title: "Loan Term") ?? 5)
        
        // 1) Determine your target monthly budget for car:
        let monthlyBudget = monthlyIncome * category.allocationPercentage
        
        // 2) Convert annual interest to monthly
        let monthlyInterest = (interestRate / 100.0) / 12.0
        let n = Double(loanTermYears * 12)
        guard n > 0, monthlyInterest >= 0 else { return 0 }
        
        // 3) Loan factor: r(1+r)^n / ((1+r)^n - 1)
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        guard denominator > 0 else { return 0 }
        let factor = numerator / denominator
        
        // 4) Solve for carPrice:
        let dpFraction = 1.0 - (downPayment / 100.0)
        guard dpFraction > 0 else { return 0 }
        
        let carPrice = monthlyBudget / (factor * dpFraction)
        return carPrice
    }
    
    func calculateEmergencySavings(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let monthsOfSalary = getAssumptionValue(assumptions, title: "Months of Salary") ?? 6.0
        return monthlyIncome * monthsOfSalary
    }
}
