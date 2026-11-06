#if os(iOS)
import Foundation

/// User-facing product name for the iOS Whoople build. Internal module/target names stay NOOP.
enum WhoopleBranding {
    static var displayName: String { ProductBrand.displayName }
    /// Wide geometric header wordmark (not the WHOOP trademark).
    static let wordmark = "WHOOPLE"

    /// Strip competitor / WHOOP trademarks from device nicknames before UI.
    /// Order matters: replace longer tokens first so "WHOOPLE" / "Whoople" are left alone,
    /// and bare "WHOOP" becomes Whoople (not WhoopleLE).
    static func sanitizeDisplayName(_ raw: String) -> String {
        var s = raw
        // Protect our own brand from the WHOOP substring replace.
        let protect = "⟦WHOOPLE⟧"
        s = s.replacingOccurrences(of: "WHOOPLE", with: protect, options: .caseInsensitive)
        s = s.replacingOccurrences(of: "Whoople", with: protect)
        // Whole-token-ish WHOOP replacements (case variants).
        s = s.replacingOccurrences(of: "WHOOP", with: displayName)
        s = s.replacingOccurrences(of: "Whoop", with: displayName)
        s = s.replacingOccurrences(of: "whoop", with: displayName.lowercased())
        s = s.replacingOccurrences(of: protect, with: displayName)
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        // Collapse duplicate brand words ("Whoople Whoople Strap")
        let collapsed = trimmed.replacingOccurrences(
            of: "\(displayName) \(displayName)",
            with: displayName,
            options: .caseInsensitive
        )
        return collapsed.isEmpty ? "\(displayName) Strap" : collapsed
    }
}

#endif
