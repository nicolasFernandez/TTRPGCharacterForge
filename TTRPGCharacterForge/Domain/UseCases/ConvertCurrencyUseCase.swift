import Foundation

/// Converts user-entered SRD coin counts into one exact, canonical balance.
struct ConvertCurrencyUseCase {
    enum ConversionError: Error, Equatable {
        case invalidCoinCount
        case amountTooLarge
    }

    struct Input: Equatable, Sendable {
        var copper: String
        var silver: String
        var electrum: String
        var gold: String
        var platinum: String
    }

    struct Result: Equatable, Sendable {
        let balance: CurrencyBalance
        let totalCopper: Int64

        func formattedTotalGP(locale: Locale) -> String {
            let wholeGP = totalCopper / 100
            let fractionalGP = totalCopper % 100
            let separator = locale.decimalSeparator ?? "."
            return "\(wholeGP)\(separator)\(String(format: "%02lld", fractionalGP)) gp"
        }
    }

    func execute(_ input: Input) throws -> Result {
        let values = try [
            parse(input.copper),
            parse(input.silver),
            parse(input.electrum),
            parse(input.gold),
            parse(input.platinum)
        ]
        let multipliers: [Int64] = [1, 10, 50, 100, 1_000]
        var total: Int64 = 0

        for (value, multiplier) in zip(values, multipliers) {
            let product = value.multipliedReportingOverflow(by: multiplier)
            guard !product.overflow else { throw ConversionError.amountTooLarge }
            let sum = total.addingReportingOverflow(product.partialValue)
            guard !sum.overflow else { throw ConversionError.amountTooLarge }
            total = sum.partialValue
        }

        return Result(balance: Self.normalize(totalCopper: total), totalCopper: total)
    }

    static func normalize(totalCopper: Int64) -> CurrencyBalance {
        var remainder = totalCopper
        let platinum = remainder / 1_000
        remainder %= 1_000
        let gold = remainder / 100
        remainder %= 100
        let electrum = remainder / 50
        remainder %= 50
        let silver = remainder / 10
        let copper = remainder % 10
        return CurrencyBalance(
            copper: copper,
            silver: silver,
            electrum: electrum,
            gold: gold,
            platinum: platinum
        )
    }

    private func parse(_ input: String) throws -> Int64 {
        guard !input.isEmpty else { return 0 }
        guard input.allSatisfy({ $0 >= "0" && $0 <= "9" }) else {
            throw ConversionError.invalidCoinCount
        }
        guard let value = Int64(input) else { throw ConversionError.amountTooLarge }
        return value
    }
}
