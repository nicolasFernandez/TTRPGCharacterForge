import Foundation

/// A character's exact five-denomination coin balance.
struct CurrencyBalance: Codable, Equatable, Sendable {
    var copper: Int64
    var silver: Int64
    var electrum: Int64
    var gold: Int64
    var platinum: Int64

    static let zero = CurrencyBalance(copper: 0, silver: 0, electrum: 0, gold: 0, platinum: 0)

    init(
        copper: Int64 = 0,
        silver: Int64 = 0,
        electrum: Int64 = 0,
        gold: Int64 = 0,
        platinum: Int64 = 0
    ) {
        self.copper = copper
        self.silver = silver
        self.electrum = electrum
        self.gold = gold
        self.platinum = platinum
    }
}
