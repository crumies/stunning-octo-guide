import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var ble: DunenBLEManager
    @EnvironmentObject var settings: AppSettings
    @State private var fullscreen = false

    var speed: Double {
        settings.speedUnit == .kmh ? ble.telemetry.speedKmh : ble.telemetry.speedKmh * 0.621371
    }

    var odo: String {
        settings.speedUnit == .kmh ? String(format: "%.1f km", ble.telemetry.odometerKm) : String(format: "%.1f mi", ble.telemetry.odometerKm * 0.621371)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                HUDBlock(fullscreenButton: { fullscreen = true }, compact: false)

                GlassCard {
                    VStack(spacing: 12) {
                        HStack {
                            metric("Voltage", String(format: "%.1f V", ble.telemetry.voltage))
                            metric("Odometer", odo)
                        }
                        HStack {
                            metric("Battery", String(format: "%.0f %%", ble.telemetry.batteryPercent))
                            metric("Motor", "72V 38.4Ah")
                        }
                    }
                }

                GraphPanel(fullscreenButton: { fullscreen = true }, compact: false)
                RideRecordingCard()
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 82)
        }
        .fullScreenCover(isPresented: $fullscreen) {
            FullscreenHUD()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ConnectionPill()
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(Date.now.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let name = ble.connectedName {
                    Text("Connected to \(name)")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
            }
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HUDBlock: View {
    @EnvironmentObject var ble: DunenBLEManager
    @EnvironmentObject var settings: AppSettings
    var fullscreenButton: () -> Void
    var compact: Bool = false

    var speedValue: Double {
        settings.speedUnit == .kmh ? ble.telemetry.speedKmh : ble.telemetry.speedKmh * 0.621371
    }

    var displaySpeed: String {
        if ble.telemetry.mode == .park { return "P" }
        return "\(Int(speedValue.rounded()))"
    }

    var body: some View {
        GlassCard(glow: true) {
            ZStack {
                Circle()
                    .fill(modeColor.opacity(0.16 + min(ble.telemetry.speedKmh / 260, 0.22)))
                    .blur(radius: 52)
                    .frame(width: compact ? 210 : 260)

                VStack(spacing: compact ? 7 : 10) {
                    AptumLogoImage()
                        .frame(width: compact ? 132 : 150, height: compact ? 34 : 40)
                        .padding(.bottom, -2)

                    ModeBadge(mode: ble.telemetry.mode)

                    if settings.hudShowTemps {
                        HStack {
                            statusIcon("cpu", String(format: "%.0f°C", ble.telemetry.controllerTemp))
                            Spacer()
                            statusIcon("square.stack.3d.up.fill", String(format: "%.0f°C", ble.telemetry.motorTemp))
                            Spacer()
                            statusIcon("battery.75percent", String(format: "%.0f%%", ble.telemetry.batteryPercent))
                        }
                    }

                    ZStack {
                        RPMArc(rpm: ble.telemetry.rpm, mode: ble.telemetry.mode)
                            .frame(width: compact ? 205 : 225, height: compact ? 205 : 225)

                        VStack(spacing: 0) {
                            Text(displaySpeed)
                                .font(.system(size: ble.telemetry.mode == .park ? (compact ? 92 : 108) : (compact ? 76 : 88), weight: .heavy, design: .rounded))
                                .foregroundStyle(ble.telemetry.mode == .sports ? .orange : (ble.telemetry.mode == .park ? .white : .primary))
                            Text(ble.telemetry.mode == .park ? "PARK" : (ble.telemetry.mode == .reverse ? "REVERSE • \(settings.speedUnit.rawValue)" : settings.speedUnit.rawValue))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if settings.hudShowKW {
                        Text(String(format: "%.1f kW", ble.telemetry.powerKw))
                            .font(.title3.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.22))
                            .clipShape(Capsule())
                    }

                    if settings.hudShowLean {
                        LeanIndicator()
                    }

                    Text(Date.now.formatted(date: .omitted, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if settings.hudShowIcons {
                        HStack {
                            smallState("light.max.fill", active: ble.telemetry.headlightActive)
                            smallState("exclamationmark.circle.fill", active: ble.telemetry.warningCode != 0 || ble.telemetry.errorCode != 0)
                            smallState("parkingsign.circle.fill", active: ble.telemetry.parkingActive)
                            smallState("arrow.uturn.backward.circle.fill", active: ble.telemetry.reverseActive)
                            smallState("figure.stand", active: ble.telemetry.kickstandActive)
                            smallState("brakesignal", active: ble.telemetry.brakeActive)
                            Spacer()
                            Button {
                                fullscreenButton()
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                            }
                            .buttonStyle(.bordered)
                            .tint(.cyan)
                        }
                    }
                }
            }
        }
    }

    var modeColor: Color {
        switch ble.telemetry.mode {
        case .eco: return .green
        case .xc: return .cyan
        case .sports: return .orange
        case .reverse: return .purple
        case .park: return .white
        }
    }

    private func statusIcon(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).foregroundStyle(.cyan)
            Text(text).font(.caption.weight(.bold))
        }
    }

    private func smallState(_ icon: String, active: Bool) -> some View {
        Image(systemName: icon)
            .foregroundStyle(active ? .cyan : .secondary.opacity(0.4))
            .font(.caption)
    }
}

struct LeanIndicator: View {
    @EnvironmentObject var ble: DunenBLEManager

    var side: String {
        if ble.telemetry.leanAngle > 2 { return "RIGHT" }
        if ble.telemetry.leanAngle < -2 { return "LEFT" }
        return "CENTER"
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text("LEAN \(side)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f°", abs(ble.telemetry.leanAngle)))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.cyan)
            }

            GeometryReader { geo in
                ZStack {
                    Capsule().fill(.white.opacity(0.12))
                    Rectangle().fill(.white.opacity(0.35)).frame(width: 2)
                    Circle()
                        .fill(.cyan)
                        .frame(width: 10, height: 10)
                        .offset(x: CGFloat(max(-1, min(1, ble.telemetry.leanAngle / 42))) * geo.size.width / 2)
                }
            }
            .frame(height: 10)
        }
    }
}

struct ModeBadge: View {
    let mode: RideMode

    var color: Color {
        switch mode {
        case .eco: return .green
        case .xc: return .cyan
        case .sports: return .orange
        case .reverse: return .purple
        case .park: return .white
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mode.symbol)
            Text(mode.rawValue)
        }
        .font(.headline.weight(.heavy))
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct RPMArc: View {
    let rpm: Int
    let mode: RideMode

    var progress: Double { min(max(Double(rpm) / 9000.0, 0), 1) }

    var baseColor: Color {
        switch mode {
        case .eco: return .green
        case .xc: return .cyan
        case .sports: return .orange
        case .reverse: return .purple
        case .park: return .white
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(.white.opacity(0.10), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .rotationEffect(.degrees(90))

            Circle()
                .trim(from: 0.12, to: 0.12 + progress * 0.76)
                .stroke(
                    AngularGradient(
                        colors: [baseColor, baseColor, .yellow, .orange, .red],
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405)
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .shadow(color: progress > 0.78 ? .red.opacity(0.65) : baseColor.opacity(0.5), radius: 14)

            if progress > 0.82 {
                Circle()
                    .trim(from: 0.78, to: 0.88)
                    .stroke(.red.opacity(0.75), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .blur(radius: 1)
            }
        }
    }
}

struct GraphPanel: View {
    @EnvironmentObject var ble: DunenBLEManager
    @EnvironmentObject var settings: AppSettings
    var fullscreenButton: () -> Void
    var compact: Bool = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: compact ? 7 : 11) {
                HStack {
                    Text("Dynamic Live Graphs").font(.headline)
                    Spacer()
                    if !compact {
                        Button { fullscreenButton() } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                            .buttonStyle(.bordered).tint(.cyan)
                    }
                }

                graphRow("Speed", value: String(format: "%.0f %@", settings.speedUnit == .kmh ? ble.telemetry.speedKmh : ble.telemetry.speedKmh * 0.621371, settings.speedUnit.rawValue), values: ble.history.speed, max: 120)
                graphRow("RPM", value: "\(ble.telemetry.rpm) rpm", values: ble.history.rpm, max: 9000)
                graphRow("Voltage", value: String(format: "%.1f V", ble.telemetry.voltage), values: ble.history.voltage, max: 90)
                graphRow("Current", value: String(format: "%.1f A", ble.telemetry.currentA), values: ble.history.current, max: 140)
            }
        }
    }

    private func graphRow(_ title: String, value: String, values: [Double], max: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.caption.weight(.bold)).foregroundStyle(title == "Speed" ? .cyan : .primary)
            }
            MiniLineGraph(values: values, maxValue: max).frame(height: compact ? 34 : 44)
        }
    }
}

struct RideRecordingCard: View {
    @EnvironmentObject var ble: DunenBLEManager

    var body: some View {
        GlassCard(glow: ble.rideStats.isRecording) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Ride Recording").font(.headline)
                    Spacer()
                    Button(ble.rideStats.isRecording ? "Stop" : "Start") {
                        ble.rideStats.isRecording ? ble.stopRideRecording() : ble.startRideRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ble.rideStats.isRecording ? .red : .cyan)
                }

                HStack {
                    stat("Top", String(format: "%.0f km/h", ble.rideStats.topSpeedKmh))
                    stat("Avg", String(format: "%.0f km/h", ble.rideStats.averageSpeedKmh))
                    stat("0–50", ble.rideStats.zeroToFiftySeconds == nil ? "—" : String(format: "%.2fs", ble.rideStats.zeroToFiftySeconds!))
                }

                HStack {
                    stat("Trip", String(format: "%.2f km", ble.rideStats.tripKm))
                    stat("Peak RPM", "\(ble.rideStats.peakRPM)")
                    stat("Battery", String(format: "-%.2f V", ble.rideStats.batteryUsedVoltage))
                }
            }
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.bold)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FullscreenHUD: View {
    @EnvironmentObject var ble: DunenBLEManager
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            Circle()
                .fill(modeColor.opacity(0.20))
                .blur(radius: 90)
                .frame(width: 380)
                .offset(y: -40)

            ScrollView {
                VStack(spacing: 8) {
                    HUDBlock(fullscreenButton: {}, compact: true)
                        .frame(maxWidth: 430)
                    if settings.hudShowGraphs { GraphPanel(fullscreenButton: {}, compact: true) }
                        .frame(maxWidth: 430)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.top, 58)
                .padding(.bottom, 10)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .overlay(Circle().stroke(.cyan.opacity(0.35), lineWidth: 1))
                    .clipShape(Circle())
                    .shadow(color: .cyan.opacity(0.25), radius: 14)
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .preferredColorScheme(.dark)
    }

    var modeColor: Color {
        switch ble.telemetry.mode {
        case .eco: return .green
        case .xc: return .cyan
        case .sports: return .orange
        case .reverse: return .purple
        case .park: return .white
        }
    }
}
