import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<AptumRideAttributes>?

    func startIfNeeded(vehicleName: String, telemetry: Telemetry) {
        guard activity == nil else {
            update(telemetry: telemetry)
            return
        }

        let attributes = AptumRideAttributes(vehicleName: vehicleName)
        let state = AptumRideAttributes.ContentState(
            speed: Int(telemetry.speedKmh.rounded()),
            mode: telemetry.mode.rawValue,
            kw: telemetry.powerKw,
            battery: Int(telemetry.batteryPercent.rounded()),
            rpm: telemetry.rpm,
            temp: Int(telemetry.controllerTemp.rounded())
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Live Activity start failed: \(error)")
        }
    }

    func update(telemetry: Telemetry) {
        guard let activity else { return }
        let state = AptumRideAttributes.ContentState(
            speed: Int(telemetry.speedKmh.rounded()),
            mode: telemetry.mode.rawValue,
            kw: telemetry.powerKw,
            battery: Int(telemetry.batteryPercent.rounded()),
            rpm: telemetry.rpm,
            temp: Int(telemetry.controllerTemp.rounded())
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.activity = nil
        }
    }
}
#endif
