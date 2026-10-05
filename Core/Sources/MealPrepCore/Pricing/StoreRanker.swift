import Foundation

public enum StoreRanker {
    /// Cheapest shopping total first; ties (within half an øre) go to the nearer store.
    public static func rank(_ baskets: [Basket]) -> [Basket] {
        baskets.sorted { a, b in
            if abs(a.shoppingTotal - b.shoppingTotal) > 0.005 { return a.shoppingTotal < b.shoppingTotal }
            return (a.store?.distanceMeters ?? .infinity) < (b.store?.distanceMeters ?? .infinity)
        }
    }
}
