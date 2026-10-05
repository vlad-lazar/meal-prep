import Foundation

public enum SpendStats {
    public static func total(inMonthOf reference: Date, entries: [(date: Date, amount: Double)],
                             calendar: Calendar = .current) -> Double {
        entries
            .filter { calendar.isDate($0.date, equalTo: reference, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}
