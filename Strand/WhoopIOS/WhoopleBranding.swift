#if os(iOS)
import Foundation

/// User-facing product name for the iOS Whoople build. Internal module/target names stay NOOP.
enum WhoopleBranding {
    static let displayName = "Whoople"
    /// Wide geometric header wordmark (not the WHOOP trademark).
    static let wordmark = "WHOOPLE"
}

#endif
