import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct AptumRideAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var speed: Int
        var mode: String
        var kw: Double
        var battery: Int
        var rpm: Int
        var temp: Int
    }

    var vehicleName: String
}
#endif
