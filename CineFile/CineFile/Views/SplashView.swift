import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    @State private var appear = false
    @State private var displayedText: String = ""
    @State private var typeTimer: Timer?
    private let fullTagline = "Cross off the classics, one reel at a time."

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                // Background image (add your image as "splash_bg" in Assets)
                Image("splash_bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Soft overhead light cone from the top center to mimic the lamp
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.38),
                        Color.white.opacity(0.16),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.02),
                    startRadius: 8,
                    endRadius: min(w, h) * 0.8
                )
                .compositingGroup()
                .blendMode(.screen)
                .ignoresSafeArea()
                .zIndex(1)

                // Gentle vignette/top gradient to ensure title contrast (above the light)
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
                .zIndex(2)

                // Centered tagline with SF Pro (non-serif), in requested color #AC9E79
                let taglineFont = Font.system(size: 20, weight: .medium, design: .default)
                let taglineColor = Color(red: 172/255, green: 158/255, blue: 121/255)
                Text(displayedText)
                    .font(taglineFont)
                    .foregroundColor(taglineColor)
                    .multilineTextAlignment(.center)
                    .kerning(0.3)
                    .shadow(color: Color.black.opacity(0.85), radius: 12, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .frame(width: min(w * 0.82, 520))
                    .position(x: w / 2, y: h / 2)
                    .zIndex(3)
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
            .onAppear {
                appear = true
                displayedText = ""
                typeTimer?.invalidate()
                var index = 0
                typeTimer = Timer.scheduledTimer(withTimeInterval: 0.035, repeats: true) { timer in
                    if index < fullTagline.count {
                        let i = fullTagline.index(fullTagline.startIndex, offsetBy: index)
                        displayedText.append(fullTagline[i])
                        index += 1
                    } else {
                        timer.invalidate()
                        typeTimer = nil
                    }
                }
                if let typeTimer { RunLoop.main.add(typeTimer, forMode: .common) }
            }
            .onDisappear {
                typeTimer?.invalidate()
                typeTimer = nil
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onFinished: {})
    }
}
