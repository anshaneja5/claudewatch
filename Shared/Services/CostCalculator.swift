import Foundation

// MARK: - Token Usage (Cost Domain)

struct TokenUsage {
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var cacheCreationInputTokens: Int = 0
    var cacheReadInputTokens: Int = 0

    init(inputTokens: Int = 0, outputTokens: Int = 0,
         cacheCreationInputTokens: Int = 0, cacheReadInputTokens: Int = 0) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationInputTokens = cacheCreationInputTokens
        self.cacheReadInputTokens = cacheReadInputTokens
    }

    init(raw: TokenUsageRaw) {
        self.inputTokens = raw.inputTokens
        self.outputTokens = raw.outputTokens
        self.cacheCreationInputTokens = raw.cacheCreationInputTokens ?? 0
        self.cacheReadInputTokens = raw.cacheReadInputTokens ?? 0
    }

    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationInputTokens + cacheReadInputTokens
    }

    static func + (lhs: TokenUsage, rhs: TokenUsage) -> TokenUsage {
        TokenUsage(
            inputTokens: lhs.inputTokens + rhs.inputTokens,
            outputTokens: lhs.outputTokens + rhs.outputTokens,
            cacheCreationInputTokens: lhs.cacheCreationInputTokens + rhs.cacheCreationInputTokens,
            cacheReadInputTokens: lhs.cacheReadInputTokens + rhs.cacheReadInputTokens
        )
    }

    static func += (lhs: inout TokenUsage, rhs: TokenUsage) {
        lhs = lhs + rhs
    }
}

// MARK: - Pricing

struct ModelPricing {
    let inputPerMillion: Double
    let outputPerMillion: Double
    let cacheCreationPerMillion: Double
    let cacheReadPerMillion: Double

    static let sonnet = ModelPricing(
        inputPerMillion: 3.00, outputPerMillion: 15.00,
        cacheCreationPerMillion: 3.75, cacheReadPerMillion: 0.30
    )

    static let opus = ModelPricing(
        inputPerMillion: 15.00, outputPerMillion: 75.00,
        cacheCreationPerMillion: 18.75, cacheReadPerMillion: 1.50
    )

    static let haiku = ModelPricing(
        inputPerMillion: 0.80, outputPerMillion: 4.00,
        cacheCreationPerMillion: 1.00, cacheReadPerMillion: 0.08
    )

    func totalCost(for usage: TokenUsage) -> Double {
        let m = 1_000_000.0
        return (Double(usage.inputTokens) / m * inputPerMillion)
             + (Double(usage.outputTokens) / m * outputPerMillion)
             + (Double(usage.cacheCreationInputTokens) / m * cacheCreationPerMillion)
             + (Double(usage.cacheReadInputTokens) / m * cacheReadPerMillion)
    }
}

// MARK: - Calculator

final class CostCalculator {
    private init() {}

    static func cost(for model: String, usage: TokenUsage) -> Double {
        pricingForModel(model).totalCost(for: usage)
    }

    static func pricingForModel(_ model: String) -> ModelPricing {
        let lower = model.lowercased()
        if lower.contains("opus") { return .opus }
        if lower.contains("haiku") { return .haiku }
        return .sonnet
    }
}
