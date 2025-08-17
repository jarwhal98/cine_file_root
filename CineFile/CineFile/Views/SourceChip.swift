import SwiftUI

struct SourceChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .circular)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .circular)
                            .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
            )
            .foregroundColor(.primary)
    }
}

struct SourceChip_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            SourceChip(text: "NYTimes")
            SourceChip(text: "AFI")
            SourceChip(text: "TSPDT")
        }
        .padding()
        .background(Color(white: 0.95))
    }
}
