import Foundation

/// User-facing product name. iOS ships as Whoople; macOS/Android keep NOOP.
enum ProductBrand {
    static var displayName: String {
        #if os(iOS)
        return "Whoople"
        #else
        return "NOOP"
        #endif
    }
}
