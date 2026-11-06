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
        // Protect our brand with a token that cannot contain the WHOOP substring.
        let protect = "⟦W‑PLE‑BRAND⟧"
        s = s.replacingOccurrences(of: "WHOOPLE", with: protect, options: .caseInsensitive)
        s = s.replacingOccurrences(of: "Whoople", with: protect)
        s = s.replacingOccurrences(of: displayName, with: protect, options: .caseInsensitive)
        // Bare WHOOP → Whoople (case variants). Safe now that brand is protected.
        s = s.replacingOccurrences(of: "WHOOP", with: displayName)
        s = s.replacingOccurrences(of: "Whoop", with: displayName)
        s = s.replacingOccurrences(of: "whoop", with: displayName.lowercased())
        s = s.replacingOccurrences(of: protect, with: displayName)
        // Strip decorative brackets that may linger from older bad sanitizes.
        s = s.replacingOccurrences(of: "『", with: "")
        s = s.replacingOccurrences(of: "』", with: "")
        s = s.replacingOccurrences(of: "⟦", with: "")
        s = s.replacingOccurrences(of: "⟧", with: "")
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        var collapsed = trimmed
        let dupPattern = "\(displayName) \(displayName)"
        while collapsed.range(of: dupPattern, options: .caseInsensitive) != nil {
            collapsed = collapsed.replacingOccurrences(
                of: dupPattern,
                with: displayName,
                options: .caseInsensitive
            )
        }
        // Collapse WhoopleLE / Whooplele artifacts from prior bad replaces
        collapsed = collapsed.replacingOccurrences(of: "WhoopleLE", with: displayName, options: .caseInsensitive)
        collapsed = collapsed.replacingOccurrences(of: "Whooplele", with: displayName, options: .caseInsensitive)
        collapsed = collapsed.replacingOccurrences(of: "WHOOPLELE", with: displayName.uppercased(), options: .caseInsensitive)
        return collapsed.isEmpty ? "\(displayName) Strap" : collapsed
    }
}

#endif
