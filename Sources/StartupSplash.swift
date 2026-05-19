import SwiftUI

struct StartupSplash: View {
    @State private var scale = 0.78
    @State private var glow = false
    @State private var bolts = false

    var body: some View {
        ZStack {
            AppBackground()

            ZStack {
                Circle()
                    .fill(.cyan.opacity(glow ? 0.26 : 0.08))
                    .blur(radius: 95)
                    .frame(width: glow ? 460 : 260)

                ForEach(0..<7, id: \.self) { i in
                    LightningBolt()
                        .stroke(.cyan.opacity(0.28), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 70, height: 180)
                        .rotationEffect(.degrees(Double(i) * 52))
                        .offset(y: bolts ? -135 : -75)
                        .opacity(bolts ? 0.65 : 0.05)
                        .animation(.easeInOut(duration: 0.9 + Double(i) * 0.05).repeatForever(autoreverses: true), value: bolts)
                }
            }

            VStack(spacing: 20) {
                AptumLogoImage()
                    .frame(width: 330, height: 118)
                    .scaleEffect(scale)
                    .shadow(color: .cyan.opacity(glow ? 0.55 : 0.18), radius: glow ? 34 : 12)

                Text("Initializing electric drive")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.cyan.opacity(0.9))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.05, dampingFraction: 0.74)) { scale = 1.0 }
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) { glow = true }
            bolts = true
        }
    }
}

struct LightningBolt: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY * 0.88))
        p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.05, y: rect.midY * 0.88))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX + rect.width * 0.20, y: rect.midY * 1.05))
        p.addLine(to: CGPoint(x: rect.midX - rect.width * 0.02, y: rect.midY * 1.05))
        p.closeSubpath()
        return p
    }
}
