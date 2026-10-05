import Foundation

func approx(_ a: Double?, _ b: Double, tolerance: Double = 1e-6) -> Bool {
    guard let a else { return false }
    return abs(a - b) <= tolerance
}
