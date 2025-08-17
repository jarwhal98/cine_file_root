import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    @State private var appear = false

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let titleY = h * 0.28 // under the lamp, above the TV area

            ZStack {
                // Background image (add your image as "splash_bg" in Assets)
                Image("splash_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
                    .ignoresSafeArea()

                // Gentle vignette/top gradient to ensure title contrast
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.45),
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.10),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()

                // Soft overhead light cone from the top center to mimic the lamp
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.28),
                        Color.white.opacity(0.10),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.02),
                    startRadius: 8,
                    endRadius: min(w, h) * 0.8
                )
                .blendMode(.screen)
                .ignoresSafeArea()

                // Title using same font family as inline nav title (system San Francisco)
                let titleFont = Font.system(size: 44, weight: .semibold, design: .default)
                Text("CineFile")
                    .font(titleFont)
                    .foregroundColor(Color.white.opacity(0.92))
                    // Downward shadow to emphasize overhead light
                    .shadow(color: Color.black.opacity(0.60), radius: 14, x: 0, y: 18)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1)
                    // Top-lit highlight inside text
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .blendMode(.screen)
                        .mask(
                            Text("CineFile")
                                .font(titleFont)
                        )
                    )
                    .scaleEffect(appear ? 1.0 : 0.96)
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: appear)
                    .accessibilityAddTraits(.isHeader)
                    .position(x: w / 2, y: titleY)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.height < -40 { // swipe up
                            withAnimation(.easeOut(duration: 0.3)) { onFinished() }
                        }
                    }
            )
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.35)) { onFinished() }
            }
            .onAppear { appear = true }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onFinished: {})
    }
}
