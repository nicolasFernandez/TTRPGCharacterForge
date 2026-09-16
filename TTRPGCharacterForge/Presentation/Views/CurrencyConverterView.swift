import SwiftUI

/// Edits and persists a character's exact SRD currency balance.
struct CurrencyConverterView: View {
    @ObservedObject var viewModel: CharacterEditorVM
    @Environment(\.locale) private var locale
    @State private var copper: String
    @State private var silver: String
    @State private var electrum: String
    @State private var gold: String
    @State private var platinum: String
    @State private var validationKey: LocalizedStringKey?
    @State private var saveStatusKey: LocalizedStringKey?

    private let converter = ConvertCurrencyUseCase()

    init(viewModel: CharacterEditorVM) {
        self.viewModel = viewModel
        let balance = viewModel.character.currencyBalance
        _copper = State(initialValue: String(balance?.copper ?? 0))
        _silver = State(initialValue: String(balance?.silver ?? 0))
        _electrum = State(initialValue: String(balance?.electrum ?? 0))
        _gold = State(initialValue: String(balance?.gold ?? Int64(viewModel.character.startingWealthGP ?? 0)))
        _platinum = State(initialValue: String(balance?.platinum ?? 0))
    }

    var body: some View {
        Form {
            Section {
                coinField("currency_copper", abbreviation: "cp", text: $copper)
                coinField("currency_silver", abbreviation: "sp", text: $silver)
                coinField("currency_electrum", abbreviation: "ep", text: $electrum)
                coinField("currency_gold", abbreviation: "gp", text: $gold)
                coinField("currency_platinum", abbreviation: "pp", text: $platinum)
            }

            Section {
                LabeledContent("currency_total_gp", value: validResult?.formattedTotalGP(locale: locale) ?? "—")
                    .accessibilityIdentifier("currency.total-gp")
                LabeledContent("currency_total_cp", value: totalCopperText)
                    .accessibilityIdentifier("currency.total-cp")
            }

            if let validationKey {
                Text(validationKey)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("currency.validation.message")
            }
            if let saveStatusKey {
                Text(saveStatusKey)
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("currency.save.status")
            }

            Button("currency_apply") { Task { await apply() } }
                .accessibilityIdentifier("currency.apply")
        }
        .accessibilityIdentifier("currency.converter.screen")
        .navigationTitle("currency_title")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("currency_title")
                    .accessibilityIdentifier("currency.converter.title")
            }
        }
    }

    private var input: ConvertCurrencyUseCase.Input {
        .init(copper: copper, silver: silver, electrum: electrum, gold: gold, platinum: platinum)
    }

    private var validResult: ConvertCurrencyUseCase.Result? { try? converter.execute(input) }

    private var totalCopperText: String {
        validResult.map { "\($0.totalCopper) cp" } ?? "—"
    }

    private func coinField(_ key: LocalizedStringKey, abbreviation: String, text: Binding<String>) -> some View {
        LabeledContent {
            TextField(abbreviation, text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .accessibilityIdentifier("currency.input.\(abbreviation)")
        } label: {
            Text(key)
                .accessibilityIdentifier("currency.label.\(abbreviation)")
        }
    }

    @MainActor
    private func apply() async {
        validationKey = nil
        saveStatusKey = nil
        do {
            let result = try converter.execute(input)
            try await viewModel.saveCurrencyBalance(result.balance)
            updateFields(from: result.balance)
            saveStatusKey = "currency_saved"
        } catch ConvertCurrencyUseCase.ConversionError.invalidCoinCount {
            validationKey = "currency_invalid_input"
        } catch ConvertCurrencyUseCase.ConversionError.amountTooLarge {
            validationKey = "currency_amount_too_large"
        } catch {
            validationKey = "currency_save_failed"
        }
    }

    private func updateFields(from balance: CurrencyBalance) {
        copper = String(balance.copper)
        silver = String(balance.silver)
        electrum = String(balance.electrum)
        gold = String(balance.gold)
        platinum = String(balance.platinum)
    }
}
