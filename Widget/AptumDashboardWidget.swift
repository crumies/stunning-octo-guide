import WidgetKit
import SwiftUI

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct AptumRideLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AptumRideAttributes.self) { context in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.mode)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.cyan)
                    Text("\(context.state.speed) km/h")
                        .font(.title2.weight(.heavy))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f kW", context.state.kw))
                        .font(.headline.weight(.bold))
                    Text("\(context.state.battery)% • \(context.state.temp)°C")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.mode)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.speed) km/h")
                        .font(.title2.weight(.heavy))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.1f kW", context.state.kw))
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("RPM \(context.state.rpm)")
                        Spacer()
                        Text("\(context.state.battery)% • \(context.state.temp)°C")
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Text(context.state.mode.prefix(1))
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                Text("\(context.state.speed)")
            } minimal: {
                Text("\(context.state.speed)")
            }
        }
    }
}

struct AptumDashboardWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOSApplicationExtension 16.1, *) {
            AptumRideLiveActivityWidget()
        }
    }
}
#endif
