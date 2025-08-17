import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            // Background image (add your image as "splash_bg" in Assets)
            Image("splash_bg")
                .resizable()
                .scaledToFill()
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

            // Title matching app style (serif, semibold), scaled up for splash
            Text("CineFile")
                .font(.system(size: 44, weight: .semibold, design: .serif))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.55), radius: 12, x: 0, y: 6)
                .scaleEffect(appear ? 1.0 : 0.96)
                .opacity(appear ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: appear)
                .accessibilityAddTraits(.isHeader)
        }
        .onAppear {
            appear = true
            // Hold for a moment, then finish with a smooth fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.35)) {
                    onFinished()
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onFinished: {})
    }
}
