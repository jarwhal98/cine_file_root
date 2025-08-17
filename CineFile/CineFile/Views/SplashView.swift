import SwiftUI

struct SplashView: View {
    @EnvironmentObject var viewModel: MovieViewModel
    var onFinished: () -> Void
    @State private var appear = false
    @State private var displayedText: String = ""
    @State private var typeTimer: Timer?
    private let fullTagline = "Cross off\nthe Classics,\none reel\nat a time."

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let insets = proxy.safeAreaInsets

            ZStack {
                // Background image (add your image as "splash_bg" in Assets)
                Image("splash_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: w + insets.leading + insets.trailing,
                        height: h + insets.top + insets.bottom,
                        alignment: .center
                    )
                    .position(x: w / 2.2, y: h / 1.7807)
                    .clipped()
                    .scaleEffect(1.0) // 
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
        let taglineFont = Font.system(size: 24, weight: .semibold, design: .monospaced)
                let taglineColor = Color(red: 172/255, green: 158/255, blue: 121/255)
        VStack(spacing: 14) {
            Text(displayedText)
                    .font(taglineFont)
                    .foregroundColor(taglineColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                            )
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    )
                    .frame(width: min(w * 0.82, 520))

            // Progress bar while preloading
            if viewModel.isImporting {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.importProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: taglineColor))
                        .frame(width: min(w * 0.72, 420))
                    Text(viewModel.preloadStatus.isEmpty ? "Preparing…" : viewModel.preloadStatus)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.top, 6)
            } else if viewModel.preloadCompleted {
                // Begin button after preload completes
                Button(action: { withAnimation(.easeOut(duration: 0.35)) { onFinished() } }) {
                    Text("Click to begin")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .circular)
                                .fill(taglineColor)
                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
        }
        .position(x: w / 2, y: h * 0.56)
        .zIndex(3)
            }
            .contentShape(Rectangle())
            // Disable gestures until preload completes
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        guard viewModel.preloadCompleted else { return }
                        if value.translation.height < -40 { // swipe up
                            withAnimation(.easeOut(duration: 0.3)) { onFinished() }
                        }
                    }
            )
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
                if let timer = typeTimer { RunLoop.main.add(timer, forMode: .common) }
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
            .environmentObject(MovieViewModel())
    }
}
