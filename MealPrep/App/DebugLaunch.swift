import Foundation

#if DEBUG
/// Launch arguments for simulator screenshots, e.g. `-debugOpenRecipe chicken-curry -debugShowStores YES`.
enum DebugLaunch {
    private static var defaults: UserDefaults { .standard }
    static var openRecipe: String? { defaults.string(forKey: "debugOpenRecipe") }
    static var showStores: Bool { defaults.bool(forKey: "debugShowStores") }
    static var startPrep: String? { defaults.string(forKey: "debugStartPrep") }
    static var cook: Bool { defaults.bool(forKey: "debugCook") }
    static var tab: String? { defaults.string(forKey: "debugTab") }
}
#endif
