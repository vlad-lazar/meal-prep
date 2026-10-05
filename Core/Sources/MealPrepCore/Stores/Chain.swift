import Foundation

/// Danish grocery chains we price against. Dealer ids are Tjek's (verified 2026-10-05).
public enum Chain: String, Codable, Sendable, CaseIterable, Identifiable {
    case netto, rema1000, lidl, foetex, bilka, coop365, kvickly, superbrugsen, brugsen, meny, spar, lovbjerg, minKobmand

    public var id: String { rawValue }

    public var dealerId: String {
        switch self {
        case .netto: return "9ba51"
        case .rema1000: return "11deC"
        case .lidl: return "71c90"
        case .foetex: return "bdf5A"
        case .bilka: return "93f13"
        case .coop365: return "DWZE1w"
        case .kvickly: return "c1edq"
        case .superbrugsen: return "0b1e8"
        case .brugsen: return "d311fg"
        case .meny: return "267e1m"
        case .spar: return "88ddE"
        case .lovbjerg: return "65caN"
        case .minKobmand: return "603dfL"
        }
    }

    public var displayName: String {
        switch self {
        case .netto: return "Netto"
        case .rema1000: return "REMA 1000"
        case .lidl: return "Lidl"
        case .foetex: return "føtex"
        case .bilka: return "Bilka"
        case .coop365: return "Coop 365"
        case .kvickly: return "Kvickly"
        case .superbrugsen: return "SuperBrugsen"
        case .brugsen: return "Dagli'Brugsen"
        case .meny: return "MENY"
        case .spar: return "SPAR"
        case .lovbjerg: return "Løvbjerg"
        case .minKobmand: return "Min Købmand"
        }
    }

    /// Brand colour as hex (no '#').
    public var brandHex: String {
        switch self {
        case .netto: return "FFD950"
        case .rema1000: return "014693"
        case .lidl: return "0347A1"
        case .foetex: return "1D2F54"
        case .bilka: return "00AEEF"
        case .coop365: return "01AA46"
        case .kvickly, .superbrugsen, .brugsen: return "C31414"
        case .meny: return "CD0931"
        case .spar: return "ED1C24"
        case .lovbjerg: return "A21837"
        case .minKobmand: return "054628"
        }
    }

    public init?(dealerId: String) {
        guard let chain = Self.allCases.first(where: { $0.dealerId == dealerId }) else { return nil }
        self = chain
    }

    public static var allDealerIds: [String] { allCases.map(\.dealerId) }
}
